/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi, Patrick Taillandier, Damien Philippon
* Tags: covid19,epidemiology
***/


@no_experiment

model CoVid19

import "../Functions.gaml"
import "Activity.gaml"
import "Building.gaml"


global
{
	int total_number_of_infected <- 0;
	int total_number_reported <- 0;
	int total_number_individual <- 0;
	
	map<string, int> building_infections;
}

species Individual{
	int age;
	int sex; //0 M 1 F
	string household_id;
	bool is_at_home <- true;
	Building home;
	Building school;
	Building working_place;
	list<Individual> relatives;
	list<Individual> friends;
	Building current_place;
	bool is_outside <- false;
	
	
	//Epidemiologial attributes
	string status <- susceptible; //S,E,Ua,Us,A,R,D
	string report_status <- not_tested; //Not-tested, Negative, Positive
	bool is_infectious <- define_is_infectious();
	bool is_infected <- define_is_infected();
	bool is_asymptomatic <- define_is_asymptomatic();
	float incubation_time; 
	float infectious_time;
	float serial_interval;
	float contact_rate_human;
	float basic_viral_release;
	int tick <- 0;
	
	
	list<map<int, Activity>> agenda_week;
	Activity last_activity;
	
	//Intervention related attributes
	float reduction_contact_rate_asymptomatic;
	float reduction_contact_rate_wearing_mask;
	bool free_rider <- false;
	float proba_wearing_mask;
	bool wearMask;
	
	//Hospitalization related attributes
	string hospitalization_status <- healthy;
	bool is_hospitalized <- false;
	bool is_ICU <- false;
	float time_before_hospitalization;
	float time_before_ICU;
	float time_stay_ICU;	
	map<Activity, list<Building>> building_targets;
	
	action initialize {
		reduction_contact_rate_asymptomatic <- world.get_reduction_contact_rate_asymptomatic(age);
		reduction_contact_rate_wearing_mask <- world.get_reduction_contact_rate_wearing_mask(age);
		basic_viral_release <- world.get_basic_viral_release(age);
		contact_rate_human <- world.get_contact_rate_human(age);
		proba_wearing_mask <- world.get_proba_wearing_mask(age);
		int nb_friends <- min(length(Individual) - length(relatives) - 1, max(0,round(gauss(nb_friends_mean,nb_friends_std))));
		loop while: length(friends) < nb_friends {
			friends <-  friends + (nb_friends among Individual);
			friends <- friends - self - relatives;
		}
		
		
 	}
	
	action enter_building(Building b) {
		if (current_place != nil ){
			current_place.individuals >> self;
		}	
		current_place <- b;
		is_at_home <- current_place = home;
		current_place.individuals << self;
		location <- any_location_in(current_place);
	}
	
	
	action testIndividual
	{
		if(self.is_infected)
		{
			if(world.is_true_positive(self.age))
			{
				report_status <- tested_positive;
				total_number_reported <- total_number_reported+1;
			}
			else
			{
				report_status <- tested_negative;
			}
		}
		else
		{
			if(world.is_true_negative(self.age))
			{
				report_status <- tested_negative;
			}
			else
			{
				report_status <- tested_positive;
				total_number_reported <- total_number_reported+1;
			}
		}
	}

	action updateWearMask
	{
		if(free_rider)
		{
			wearMask <- false;
		}
		else
		{
			if(flip(proba_wearing_mask))
			{
				wearMask <- true;
			}
			else
			{
				wearMask <- false;
			}
		}
	}
	
	action defineNewCase
	{
		total_number_of_infected <- total_number_of_infected +1;
		do set_status(exposed);
		self.incubation_time <- world.get_incubation_time(self.age);
		self.serial_interval <- world.get_serial_interval(self.age);
		self.infectious_time <- world.get_infectious_time(self.age);
		
		if(building_infections.keys contains(current_place.type))
		{
			building_infections[current_place.type] <- building_infections[current_place.type] +1;
		}
		else
		{
			add 1 to: building_infections at: current_place.type;
		}
		
		if(serial_interval<0)
		{
			if(abs(serial_interval)>incubation_time)
			{
				serial_interval <- -incubation_time;
			}
			self.infectious_time <- max(0,self.infectious_time - self.serial_interval);
			self.incubation_time <- max(0,self.incubation_time + self.serial_interval);
		}
		self.tick <- 0;
	}
	
	bool define_is_infectious {
		return [asymptomatic,symptomatic_without_symptoms, symptomatic_with_symptoms ] contains status;
	}
	
	bool is_exposed {
		return status = exposed;
	}
	
	bool define_is_infected {
		return is_infectious or self.is_exposed();
	}
	
	bool define_is_asymptomatic {
		return [asymptomatic,symptomatic_without_symptoms] contains status;
	}
	
	action set_hospitalization_time{
		if(world.is_hospitalized(self.age))
		{
			time_before_hospitalization <- status=symptomatic_without_symptoms? abs(self.serial_interval)+world.get_time_onset_to_hospitalization(self.age,self.infectious_time):world.get_time_onset_to_hospitalization(self.age,self.infectious_time);
			if(time_before_hospitalization>infectious_time)
			{
				time_before_hospitalization <- infectious_time;
			}
			if(world.is_ICU(self.age))
			{
				time_before_ICU <- world.get_time_hospitalization_to_ICU(self.age, self.time_before_hospitalization);
				time_stay_ICU <- world.get_time_ICU(self.age);
				if(time_before_hospitalization+time_before_ICU>=infectious_time)
				{
					time_before_hospitalization <- infectious_time-time_before_ICU;
				}
			}
		}
	}
	
	action set_status(string new_status) {
		status <- new_status;
		is_infectious <- define_is_infectious();
		is_infected <- define_is_infected();
		is_asymptomatic <- define_is_asymptomatic();
	}

	reflex become_infected_outside when: is_outside {
		if flip(proba_outside_contamination_per_hour) {
			do defineNewCase;
		}
	}
	
	reflex infectOthers when: not is_outside and is_infectious
	{
		float reduction_factor <- 1.0;
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * reduction_contact_rate_asymptomatic;
		}
		if(wearMask)
		{
			reduction_factor <- reduction_factor * reduction_contact_rate_wearing_mask;
		}
		if(current_place!=nil)and(transmission_building)
		{
			ask current_place
			{
				do addViralLoad(reduction_factor*myself.basic_viral_release);
			}
		}
		if transmission_human {
			
			if (is_at_home) {
				float proba <- contact_rate_human*reduction_factor;
				ask relatives where (flip(proba) and (each.status = susceptible)) {
		 			do defineNewCase;
				}
				if (current_place.nb_households > 1) {
					
					proba <- proba * reduction_coeff_other_household;
					
					ask current_place.individuals where (flip(proba) and (each.status = susceptible) and not (self in relatives))
			 		{
			 			do defineNewCase;
			 		}
				}
				
			}
			else {
				float proba <- contact_rate_human*reduction_factor;
				ask current_place.individuals where (flip(proba) and (each.status = susceptible))
		 		{
					do defineNewCase;
		 		}
		 	}
		}
	}
	
	reflex becomeInfectious when: self.is_exposed() and(tick >= incubation_time)
	{
		if(world.is_asymptomatic(self.age))
		{
			do set_status(asymptomatic);
			tick <- 0;
		}
		else
		{
			if(serial_interval<0)
			{
				do set_status(symptomatic_without_symptoms);
				tick <- 0;
				do set_hospitalization_time;
			}
			else
			{
				do set_status(symptomatic_with_symptoms);
				tick <- 0;
				do set_hospitalization_time;
			}
		}
	}
	
	

	reflex becomeSymptomatic when: status=symptomatic_without_symptoms and self.tick>=abs(self.serial_interval) {
		do set_status(symptomatic_with_symptoms);
	}
	
	reflex becomesNotInfectious when: ((status=symptomatic_with_symptoms) or (status=asymptomatic))and(tick>=infectious_time)
	{
		if(self.status = symptomatic_with_symptoms)
		{
			if(self.hospitalization_status=need_ICU)and(self.is_ICU=false)
			{
				do set_status(dead);
			}
			else
			{
				if(self.hospitalization_status=need_ICU)and(self.is_ICU=true)and(world.is_fatal(self.age))
				{
					do set_status(dead);
				}
				else
				{
					do set_status(recovered);
					self.hospitalization_status <- healthy;
				}
			}
		}
		else
		{
			do set_status(recovered);
			self.hospitalization_status <- healthy;
		}
	}
	
	reflex executeAgenda {
		Activity act <- agenda_week[current_date.day_of_week - 1][current_date.hour];
		if (act != nil) {
			last_activity <- act;
			if (Authority[0].allows(self, act)) {
				do enter_building(any(act.find_target(self)));
				is_outside <- current_place = the_outside;
				
			}
		}
	}
	
	reflex update_before_hospitalization when: (time_before_hospitalization>0)
	{
		if(time_before_hospitalization>0)
		{
			time_before_hospitalization <-time_before_hospitalization -1;
			if(time_before_hospitalization<=0)
			{
				hospitalization_status <- need_hospitalization;
			}
		}
	}
	
	reflex update_before_ICU when: (hospitalization_status = need_hospitalization) and (time_before_ICU>0)
	{
		if(time_before_ICU>0)
		{
			time_before_ICU <-time_before_ICU -1;
			if(time_before_ICU<=0)
			{
				self.hospitalization_status <- need_ICU;
			}
		}
	}
	
	reflex update_stay_ICU when: (time_before_ICU<=0)and(time_stay_ICU>0)and(self.is_ICU=true)
	{
		if(time_stay_ICU>0)
		{
			time_stay_ICU <-time_stay_ICU -1;
			if(time_stay_ICU<=0)
			{
				hospitalization_status <- need_hospitalization;
			}
		}
	}
	
	reflex updateDiseaseCycle when:(status!=recovered)and(status!=dead) {
		tick <- tick + 1;
		
		if(transmission_building and (not is_infected)and(self.current_place!=nil))
		{
			if(flip(current_place.viral_load*successful_contact_rate_building))
			{
				do defineNewCase();
			}
		}
		do updateWearMask();
	}

	aspect default {
		if not is_outside {
			draw shape color: status = exposed ? #pink : ((status = symptomatic_with_symptoms)or(status=asymptomatic)or(status=symptomatic_without_symptoms)? #red : #green);
		}
	}
}