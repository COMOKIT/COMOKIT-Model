/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* The main species of COMOKIT: a Biological Entity that can perform 
* Activities in Buildings.
* Individuals maintain networks of family members, friends and colleagues
* In addition to the attributes and states inherited from its parent, 
* this species provides actions so that its agents can be tested, hospitalized, 
* infected, can infect others, wear masks, and so on.
* 
* Author: Huynh Quang Nghi, Patrick Taillandier, Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/


@no_experiment

model CoVid19

import "../Global.gaml"
import "../Functions.gaml"
import "Authority.gaml"
import "Activity.gaml"
import "Building.gaml"
import "Biological Entity.gaml"
import "Vaccine.gaml"
import "Virus.gaml"

global
{
	
	// Those are observed individual variable aggregated over the whole population
	int total_number_individual <- 0;
	
	// TODO : document and generalize observer
	int total_number_of_infected <- 0;
	map<int,int> total_incidence_age;
	int total_number_reported <- 0;
	map<int,int> tn_reported;
	int total_number_deaths <- 0;
	map<int,int> tn_deaths;
	int total_number_hospitalised <- 0;
	map<int,int> tn_hostpialised;
	int total_number_ICU <- 0;
	map<int,int> tn_icu;
	
	list<int> total_number_doses <- [0,0,0];
	map<covax,int> total_number_doses_per_vax;
	
	map<string, int> building_infections;
	
}

species Individual parent: BiologicalEntity schedules: shuffle(Individual where (each.is_active and (each.clinical_status != dead))){
	int id_int;
	//Age of the individual
	int age;
	//Sex of the individual
	int sex; //0 M 1 F
	//employement status of the individual
	bool is_unemployed; 
	//COMOKIT identifier
	string individual_id;
		
	//Bool to consider only once the death
	bool is_counted_dead <- false;
	//Bool to consider only once the hospitalisation
	bool is_counted_hospitalised <- false;
	//Bool to consider only once the ICU
	bool is_counted_ICU <- false;
	//#############################################################
	//Location related attributes
	//#############################################################
	//ID of the household of the individual
	string household_id;
	//Bool to consider if the individual is at home
	bool is_at_home <- true;
	//Home building of the individual
	Building home;
	//School building of the individual (if student)
	Building school;
	//Working place of the individual (if working)
	Building working_place;
	//Relatives (i.e. same household) of the individual
	list<Individual> relatives;
	//Friends (i.e. possibility of leisure activities together) of the individual
	list<Individual> friends;
	//Colleagues (i.e. same working place) of the individual
	list<Individual> colleagues;
	//Current building of the individual
	Building current_place;
	//Bool to consider if the individual is outside of the commune
	bool is_outside <- false;
	
	//#############################################################
	//Agenda and activities attributes
	//#############################################################
	list<map<int, pair<Activity,list<Individual>>>> agenda_week;
	list<Individual> activity_fellows;
	Activity last_activity;
	map<Activity, map<string,list<Building>>> building_targets;
	
	//#############################################################
	//Intervention related attributes
	//#############################################################
	//Reduction in the transmission when wearing a mask (coughing prevented)
	float factor_contact_rate_wearing_mask;
	//Bool to consider not following interventions
	bool free_rider <- false;
	//Probability of wearing a mask per time step
	float proba_wearing_mask;
	//Bool to represent wearing a mask
	bool is_wearing_mask;
	//Bool to uniquely count positive
	bool is_already_positive <- false;
	
	//Vaccines
	map<date, vax> vaccine_history;
	float vax_willingness;
	
	//#############################################################
	//Contact related variables
	//#############################################################
	map<agent,bool> infectious_contacts_with;
	Activity infected_when;
	int number_of_infected_individuals <- 0;
	
	//#############################################################
	//Optimization related variables
	//#############################################################
	//if false, do not simulate it
	bool is_active <- true;
	
	bool is_activity_allowed <- true;
	int nb_max_fellow <- #max_int;
	int index_home;
	
	list<list<int>> to_remove_if_actif;
	list<list<list<int>>> index_group_in_building_agenda;
	list<list<list<Building>>> index_building_agenda;
	
	//#############################################################
	// -- Initialization
	//#############################################################
	
	// Initialization of bahavioral aspect related to epidemiology, e.g. wearing a mask, willigness to vaccine
	action initialise_epidemiological_behavior {
		// Not virus dependant
		factor_contact_rate_wearing_mask <- world.get_factor_contact_rate_wearing_mask(age);
		proba_wearing_mask <- world.get_proba_wearing_mask(age);
		vax_willingness <- 1 - world.get_proba_antivax(age);
		free_rider <- flip(world.get_proba_free_rider(age));
	}
	
	//Initialise epidemiological parameters according to the age of the Entity
	action initialise_disease {
		// Virus dependant
		factor_contact_rate_asymptomatic <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_factor_asymptomatic);
		contact_rate <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_successful_contact_rate_human);
		viral_factor <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_viral_individual_factor);
		
		// TODO : move this elsewhere - rate of viral agent release in the environment
		basic_viral_release <-  world.get_basic_viral_release(self.age);
		
		//Set the status of the Individual to latent (i.e. not infectious)
		state <- "latent";
		is_susceptible <- false;
		
		if(viral_agent.flip_epidemiological_aspect(self,epidemiological_proportion_asymptomatic)){ 
			is_symptomatic <- false;
			latent_period <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_incubation_period_asymptomatic);
		}else{
			is_symptomatic <- true;
			presymptomatic_period <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_serial_interval);
			latent_period <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_incubation_period_symptomatic) + 
				(presymptomatic_period<0 ? presymptomatic_period : 0);
		}
	}
	
	//Initialiase social network of the agents (colleagues, friends)
	action initialise_social_network(map<Building,list<Individual>> working_places, map<Building,list<Individual>> schools, map<int,list<Individual>> ind_per_age_cat) {
		
		int nb_friends <- max(0,round(gauss(nb_friends_mean,nb_friends_std)));
		loop i over: ind_per_age_cat.keys {
			if age < i {
				friends <- nb_friends among ind_per_age_cat[i];
				friends <- friends - self;
				break;
			}
		}
		
		if (working_place != nil) {
			int nb_colleagues <- max(0,int(gauss(nb_work_colleagues_mean,nb_work_colleagues_std)));
			if nb_colleagues > 1 {
				colleagues <- nb_colleagues among working_places[working_place];
				colleagues <- colleagues - self;
			}
		} 
		if (school != nil) {
			int nb_classmates <- max(0,int(gauss(nb_classmates_mean,nb_classmates_std)));
			if nb_classmates > 1 {
				//colleagues <- nb_classmates among ((schools[school] where ((each.age >= (age -1)) and (each.age <= (age + 1))))- self);
				colleagues <- nb_classmates among schools[school];
				colleagues <- colleagues - self;
			}
		}
 	}
	
	//#############################################################
	//Actions
	//#############################################################
	
	//Action to call when performing a test on a individual
	action test_individual
	{
		//If the Individual is infected, we check for true positive
		if(self.is_infected)
		{
			if(viral_agent.flip_epidemiological_aspect(self, epidemiological_probability_true_positive))
			{
				report_status <- tested_positive;
				if(is_already_positive=false){
					is_already_positive <- true;
					total_number_reported <- total_number_reported+1;
				}
			}
			else
			{
				report_status <- tested_negative;
			}
		}
		else
		{
			//If the Individual is not infected, we check for true negative
			if(viral_agent.flip_epidemiological_aspect(self, epidemiological_probability_true_negative))
			{
				report_status <- tested_negative;
				
			}
			else
			{
				report_status <- tested_positive;
				if(is_already_positive=false){
					is_already_positive <- true;
					total_number_reported <- total_number_reported+1;
				}
			}
		}
		last_test <- cycle;
	}
	
	//Action to call to define a new case, obtaining different time to key events
	bool define_new_case(virus infectious_agent)
	{
		if not activate_immunity(infectious_agent) {

            if (use_activity_precomputation) {
                if not empty(index_building_agenda) {
                    current_place <- index_building_agenda[current_week][current_day][current_hour];
                    loop l over: to_remove_if_actif {
                        all_buildings[l[0]].entities_inside[l[1]][l[2]][l[3]][l[4]] >> self;
                    }
                }
            }

			//Add the new case to the total number of infected (not mandatorily known)
			total_number_of_infected <- total_number_of_infected +1;
			
			//Add the infection to the infections having been caused in the building
			loop fct over: current_place.functions  {
				if(building_infections.keys contains(fct))
				{
					building_infections[fct] <- building_infections[fct] +1;
				}
			}
			
			//Add the infection to the infections of the same age
			if(total_incidence_age.keys contains(self.age))
			{
				total_incidence_age[self.age] <- total_incidence_age[self.age] +1;
			}
			else
			{
				add 1 to: total_incidence_age at: self.age;
			}
			//Add the activity done while being infected
			infected_when <- last_activity; 
			
			// Infected by
			viral_agent <- infectious_agent;
			do initialise_disease;
			
			return true;
		}
		return false;
	}
	
	// Allows to track who infect who 
	action infect_someone(Individual succesful_contact) { 
		ask succesful_contact { myself.infectious_contacts_with[succesful_contact] <-  define_new_case(myself.viral_agent); }
		if infectious_contacts_with[succesful_contact] { number_of_infected_individuals <- number_of_infected_individuals + 1; }
	}
	
	//Action to call to update wearing a mask for a time step
	action update_wear_mask
	{
		//If the Individual is a free rider, it will not care for masks
		if(free_rider)
		{
			is_wearing_mask <- false;
		}
		else
		{
			if(flip(proba_wearing_mask))
			{
				is_wearing_mask <- true;
			}
			else
			{
				is_wearing_mask <- false;
			}
		}
	}
	
	
	//Action to call when entering a new building to update the list of individuals of the buildings
	action enter_building(Building b) {
		if (current_place != nil ){
			current_place.individuals >> self;
		}	
		current_place <- b;
		is_at_home <- current_place = home;
		current_place.individuals << self;
		location <- any_location_in(current_place);
	}
	
	//Vaccination for Covid19 on the current date
	//return the number of doses done
	int vaccination(covax v){
		int dose_nb <- vaccine_history.values count (each = v);
		
		// records
		total_number_doses[dose_nb] <- total_number_doses[dose_nb] + 1;
		if total_number_doses_per_vax contains_key v {total_number_doses_per_vax[v] <- total_number_doses_per_vax[v]+1;}
		else {total_number_doses_per_vax[v] <- 1;}
		
		do build_immunity(v.target,1-v.infection_prevention[dose_nb]);
		vaccine_history[current_date] <- v;
		
		return vaccine_history.values count (each = v);
	}
	
	// UTILS
	// -----
	// Increment count of "var" given the age of current Individual
	action increment_total_of(string var) {
		
		switch var {
			//Add the new case to the total number of infected (not mandatorily known)
			match INFECTED { total_number_of_infected <- total_number_of_infected + 1; do increment_age_total(total_incidence_age);}
			match REPORTED { total_number_reported <- total_number_reported + 1; do increment_age_total(tn_reported);}
			match HOSPITALISED { total_number_hospitalised <- total_number_hospitalised + 1; do increment_age_total(tn_hostpialised);}
			match ICU { total_number_ICU <- total_number_ICU + 1; do increment_age_total(tn_icu);}
			match DEATH { total_number_deaths <- total_number_deaths + 1; do increment_age_total(tn_deaths);}
		}
		
		
	}
	
	action increment_age_total(map<int,int> var) {
		if(var contains_key self.age) { var[self.age] <- var[self.age] + 1; }
		else { add 1 to: var at: self.age; }
	}
	
	//#############################################################
	//Reflexes
	//#############################################################
	
	//Reflex to trigger infection when outside of the commune
	reflex become_infected_outside when: is_outside and not use_activity_precomputation{
		float start <- BENCHMARK ? machine_time : 0.0;
		ask outside {do outside_epidemiological_dynamic(myself);}
		if BENCHMARK {bench["Individual.become_infected_outside"] <- bench["Individual.become_infected_outside"] + machine_time - start;}
	}
	
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: not is_outside and is_infectious
	{
		float start <- BENCHMARK ? machine_time : 0.0;
		//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		if (use_activity_precomputation) {
			current_place <- is_activity_allowed ? index_building_agenda[current_week][current_day][current_hour] : home;
			if udpate_for_display {
				location <- any_location_in(current_place);
			}
			do update_wear_mask();
			
		}
	
		float reduction_factor <- viral_factor;
		
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic;
		}
		if(is_wearing_mask)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_wearing_mask;
		}
		
		//Performing environmental contamination
		if(current_place!=nil)and(allow_transmission_building)
		{
			ask current_place
			{
				do add_viral_load(reduction_factor*myself.basic_viral_release, myself.viral_agent);
			}
		}
		
		//Perform human to human transmission
		if allow_transmission_human {
			float proba <- contact_rate*reduction_factor;
					
			if (use_activity_precomputation) {
				list<list<Individual>> others <- current_place.entities_inside[current_week][current_day][current_hour];
				if empty(current_place.individuals) {
					ask current_place {do compute_individuals;}
				}
				
		
				int index;
				if (is_at_home ) {
					index <- index_home;
				} else {
					index <-  index_group_in_building_agenda[current_week][current_day][current_hour];
				}
				list<Individual> all_ag <- others accumulate each;
				
				loop ag over: is_at_home ? copy(others[index]) : (nb_max_fellow among others[index]) {
					if  flip(proba){
						do infect_someone(ag);
					}
				}
				
				if (not is_at_home or current_place.nb_households > 1) {
					float proba_actual <- proba * reduction_coeff_all_buildings_individuals;
					loop ag over: current_place.individuals {
						if  flip(proba_actual){
							do infect_someone(ag);
						}
					}
				}
				
		
					
			} else { 
				//If the Individual is at home, perform transmission on the household level with a higher factor
				if (is_at_home) {
					
					loop succesful_contact over: relatives where (each.is_at_home and flip(proba) and (each.state = susceptible)) {
						do infect_someone(succesful_contact);
					}
					if (current_place.nb_households > 1) {
						proba <- proba * reduction_coeff_all_buildings_individuals;
						loop succesful_contact over:  current_place.individuals where (flip(proba) and (each.state = susceptible))
				 		{
				 			do infect_someone(succesful_contact);
				 		}
					}
					
				}
				else {
					//Perform transmission with people doing the activity explicitly with the Individual
					list<Individual> fellows <- activity_fellows where (flip(proba) and (each.state = susceptible));
					if (species(last_activity) != Activity) {
						fellows <- fellows where (each.current_place = current_place); 
					}
					
					loop succesful_contact over: fellows { do infect_someone(succesful_contact); }
					
					//Perform slightly reduced transmission with people not being involved in the activity but still being present
					proba <- proba * reduction_coeff_all_buildings_individuals;
					loop succesful_contact over: current_place.individuals where (flip(proba) and (each.state = susceptible))
			 		{
						do infect_someone(succesful_contact);
			 		}
			 	}	
			 }
		}
		if BENCHMARK {bench["Individual.infect_others"] <- bench["Individual.infect_others"] + machine_time - start;}
	}
	

	//Reflex to execute the agenda	
	reflex execute_agenda when:  clinical_status!=dead{
		float start <- BENCHMARK ? machine_time : 0.0;
		pair<Activity,list<Individual>> act <- agenda_week[current_day][current_hour];
		if (act.key != nil) {
			if use_activity_precomputation {
				is_activity_allowed<- Authority[0].allows(self, act.key);
				nb_max_fellow <- Authority[0].limitGroupActivity(self, act.key) - 1;
			}
			else if (Authority[0].allows(self, act.key)) {
				int nb_fellows <- Authority[0].limitGroupActivity(self, act.key) - 1;
					if (nb_fellows > 0) {
					activity_fellows <-nb_fellows among act.value;
				} else {
					activity_fellows <- [];
				}
					
				map<Building,list<Individual>> bds_ind <-  act.key.find_target(self);
				if not empty(bds_ind) {
					Building bd <- any(bds_ind.keys);
					list<Individual> inds <- bds_ind[bd];
					activity_fellows <- activity_fellows + inds;
					last_activity <- act.key;
					do enter_building(bd);
					is_outside <- current_place = the_outside;
				} else {
					activity_fellows <- [];
				}
			}
		}
		if BENCHMARK {bench["Individual.execute_agenda"] <- bench["Individual.execute_agenda"] + machine_time - start;}
	}
	
	//Remove recoevred agent (no specific behavior anymore)
	reflex become_inactive when:use_activity_precomputation and(state = removed){
		is_active <- false;
	}

	//Reflex to update disease cycle
	reflex update_epidemiology when:not use_activity_precomputation and (state!=removed) {
		float start <- BENCHMARK ? machine_time : 0.0;
		if(allow_transmission_building and (not is_infected)and(self.current_place!=nil))
		{
			loop v over: current_place.viral_load.keys {
				if(flip(current_place.viral_load[v]*successful_contact_rate_building))
				{
					infectious_contacts_with[current_place] <- define_new_case(v);
				}	
			}
		}
		do update_wear_mask();
		if BENCHMARK {bench["Individual.update_epidemiology"] <- bench["Individual.update_epidemiology"] + machine_time - start;}
	}
	
	//Reflex to add to death monitor when dead
	reflex add_to_dead when:(clinical_status=dead)and(is_counted_dead=false){
		float start <- BENCHMARK ? machine_time : 0.0;
		do increment_total_of(DEATH);
		is_counted_dead <- true;
		if BENCHMARK {bench["Individual.add_to_dead"] <- bench["Individual.add_to_dead"] + machine_time - start;}
	}
	
	//Reflex to add to hospitalized monitor when dead
	reflex add_to_hospitalised when:(is_hospitalised)and(is_counted_hospitalised=false){
		float start <- BENCHMARK ? machine_time : 0.0;
		do increment_total_of(HOSPITALISED);
		is_counted_hospitalised <- true;
		if BENCHMARK {bench["Individual.add_to_hospitalised"] <- bench["Individual.add_to_hospitalised"] + machine_time - start;}
	}
	
	//Reflex to add to ICU monitor when dead
	reflex add_to_ICU when:(is_ICU)and(is_counted_ICU=false){
		float start <- BENCHMARK ? machine_time : 0.0;
		do increment_total_of(ICU);
		is_counted_ICU <- true;
		if BENCHMARK {bench["Individual.add_to_ICU"] <- bench["Individual.add_to_ICU"] + machine_time - start;}
	}
	
	//#############################################################
	//Visualization
	//#############################################################
	
	aspect default {
		if not is_outside and is_active{
			draw shape color: state = latent ? #pink : ((state = symptomatic)or(state=asymptomatic)or(state=presymptomatic)? #red : #green);
		}
	}
}