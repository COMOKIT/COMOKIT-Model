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

import "Abstract Activity.gaml"

import "../Functions.gaml"
import "Biological Entity.gaml"
import "Vaccine.gaml"

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

species AbstractIndividual parent:BiologicalEntity {
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
	//Current place of the individual
	AbstractPlace current_place; 
	//Bool to consider if the individual is outside of the commune
	bool is_outside <- false;
	
	//############################################################# 
	//Agenda and activities attributes
	//#############################################################
	AbstractActivity last_activity;
	
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
	AbstractActivity infected_when;
	int number_of_infected_individuals <- 0;
	
	//Relatives (i.e. same household) of the individual
	list<AbstractIndividual> relatives;
	
	//#############################################################
	//Optimization related variables
	//#############################################################
	//if false, do not simulate it
	bool is_active <- true;
	
	bool is_activity_allowed <- true;
	int nb_max_fellow <- #max_int;
	int index_home;
	
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
	
	action other_initialisation_action;

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
		do other_initialisation_action;
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
	
	//#############################################################
	//Actions
	//#############################################################
	
	
	
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
	
	//Action to call when performing a test on a individual
	action test_individual
	{
		//If the Individual is infected, we check for true positive
		if(self.is_infected)
		{
			if(viral_agent.flip_epidemiological_aspect(self, epidemiological_probability_true_positive))
			{
				report_status <- tested_positive;
				infection_history[viral_agent] <+ current_date::report_status; // Keep track of reported true positive
				
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
			if(original_strain.flip_epidemiological_aspect(self, epidemiological_probability_true_negative))
			{
				report_status <- tested_negative;
				
			}
			else
			{
				report_status <- tested_positive;
				infection_history[nil] <- map(current_date::"False positive");
				
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
		if (not activate_immunity(infectious_agent)) {
				
				//Add the new case to the total number of infected (not mandatorily known)
				total_number_of_infected <- total_number_of_infected +1;
				
				//Add the infection to the infections having been caused in the building
				
				if current_place != nil {
					loop fct over: current_place.functions  {
						if(building_infections.keys contains(fct))
						{
							building_infections[fct] <- building_infections[fct] +1;
						}
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
				
				// Add the activity done while being infected
				infected_when <- last_activity; 
				// Infected by
				viral_agent <- infectious_agent;
				// Start history of the infetion
				infection_history[infectious_agent] <- map(current_date::INFECTED); 
				 
				do initialise_disease;
				
				return true;
			}
			
			return false;
			
		
	}
	
	
	// Allows to track who infect who 
	action infect_someone(AbstractIndividual succesful_contact) { 
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
	
	//Reflex to update disease cycle
	reflex update_epidemiology when:(state!=removed) {
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
}

