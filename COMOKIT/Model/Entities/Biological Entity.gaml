/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Abstract species representing the dynamics of infection and clinical 
* states in a "biological" agent. Parent of the Individual species, it is 
* designed to be used for other species of agent that could be infected 
* by the virus
* 
* Author: Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/

model BiologicalEntity

/* Insert your model definition here */
import "../Global.gaml"
import "../Functions.gaml"
import "../Parameters.gaml"
import "Virus.gaml"

//The biological entity is the mother species of the Individual agent, it could be used for other kinds of agent that
// could be infected by the virus
species BiologicalEntity control:fsm{
	//Age of the entity
	int age;
	
	// INFECTION PERIODS
	
	//The latent period, i.e., the time between exposure and being infectious
	float latent_period;
	//The presymptomatic period, used only for soon to be symptomatic entity that are already infectious
	float presymptomatic_period;
	//The infectious period, used as the time between onset and not being infectious for symptomatic entity, or the time after the latent period for asymptomatic ones
	float infectious_period;
	
	// INFECTION TIMES (TODO: describe what 'time' stands for each variable)
	
	//Time attribute for the different epidemiological states of the entity
	float tick <- 0.0;
	
	//Time between symptoms onset and hospitalisation of a symptomatic entity
	float time_symptoms_to_hospitalisation <- -1.0;
	//Time between hospitalisation and admission to intensive care unit
	float time_hospitalisation_to_ICU <- -1.0;
	//Time attribute to represent the time done in ICU
	float time_ICU;
	//Time of stay in intensive care unit
	float time_stay_ICU;
	//Time attribute for the time before death of the entity (i.e. the time allowed between needing ICU, and death due to not having been admitted to ICU
	float time_before_death;
		
	// INFECTIOUS STATUS
	
	//Clinical status of the entity (no need hospitalisation, needing hospitalisation, needing ICU, dead, recovered)
	string clinical_status <- no_need_hospitalisation;
	
	//Define if the entity is currently being treated in a hospital (but not ICU)
	bool is_hospitalised <- false;
	//Define if the entity is currently admitted in ICU
	bool is_ICU <- false;
	//Boolean to determine if the agent is infected (i.e. latent, presymptomatic, symptomatic, asymptomatic)
	bool is_infected;
	//Boolean to determine if the agent is infectious (i.e. presymptomatic, symptomatic, asymptomatic)
	bool is_infectious;
	//Boolean to determine if the agent is asymptomatic (i.e. presymptomatic, asymptomatic)
	bool is_asymptomatic;
	//Boolean to determine if the agent is symptomatic
	bool is_symptomatic;
	
	// Comorbidities
	int comorbidities <- 0;
	
	// TESTS
	
	//Report status of the entity if it has been tested, or not
	string report_status <- not_tested;
	//Number of step of the last test
	int last_test <- 0;
	//Number of times negatively tested
	int number_negative_tests <- 0;
	
	// VIRUS and IMMUNITY
	
	//The viral agent that infect this biological entity
	virus viral_agent;
	//Immunity
	map<virus,float> immunity;
	//Infection history
	map<virus,string> infection_history;
	
	// TRANSMISSION Variables
	
	// Origi from Damian : Factor for the beta and the basic viral release
	// TODO : should be seen as the viral load, rather than a factor
	float viral_factor;
	
	// Origi from Damian : Basic contact rate of the agent (might be age-dependent, hence its presence here)
	// Later from Kevin : this is a factor that establish the basic probability of one contact to turn into an infection
	//				* It is basic because it will be changed based on several factors 
	//				* It is a pure probability used within a flip() gama operator BUT without any control on its veracity (might end up being more than 1 when manipulated by "factors")
	float contact_rate;
	
	//Factor of the contact rate for asymptomatic and presymptomatic individuals (might be age-dependent, hence its presence here)
	float factor_contact_rate_asymptomatic;
	
	//Basic viral release of the agent (might be age-dependent, hence its presence here)
	float basic_viral_release;
	
	//Current location of the entity (as we do not represent transportation, the entity can only be inside a building)
	Building current_place;
	
	//#############################################################
	//Actions
	//#############################################################
	//Initialise epidemiological parameters according to the age of the Entity
	action initialise_epidemio {
		
		// Virus dependant
		factor_contact_rate_asymptomatic <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_factor_asymptomatic);
		basic_viral_release <-  viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_basic_viral_release);
		contact_rate <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_successful_contact_rate_human);
		viral_factor <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_viral_individual_factor);
	
	}
	
	//Action to call when performing a test on a individual
	action test_individual
	{
		//If the Individual is infected, we check for true positive
		if(self.is_infected)
		{
			if(viral_agent.flip_epidemiological_aspect(nil, epidemiological_probability_true_positive))
			{
				report_status <- tested_positive;
			}
			else
			{
				report_status <- tested_negative;
			}
		}
		else
		{
			//If the Individual is not infected, we check for true negative
			if(viral_agent.flip_epidemiological_aspect(nil, epidemiological_probability_true_negative))
			{
				report_status <- tested_negative;
				
			}
			else
			{
				report_status <- tested_positive;
			}
		}
		last_test <- cycle;
	}
	
	//#############################################################
	//Tools
	//#############################################################
	//Return the fact of the Individual being infectious (i.e. asymptomatic, presymptomatic, symptomatic)
	bool define_is_infectious {
		return [asymptomatic,presymptomatic, symptomatic] contains state;
	}
	
	//Return the fact of the Individual not being infectious yet but infected (i.e. latent)
	bool is_latent {
		return state = latent;
	}
	
	//Return the fact of the Individual being infected (i.e. latent, asymptomatic, presymptomatic or symptomatic)
	bool define_is_infected {
		return is_infectious or self.is_latent();
	}
	
	//Return the fact of the Individual not showing any symptoms (i.e. asymptomatic, presymptomatic)
	bool define_is_asymptomatic {
		return [asymptomatic,presymptomatic] contains state;
	}
	
	//Action to set the status of the entity
	action set_status {
		is_infectious <- define_is_infectious();
		is_infected <- define_is_infected();
		is_asymptomatic <- define_is_asymptomatic();
	}
		
	//Reflex to update the time before death when an entity need to be admitted in ICU, but is not in ICU
	reflex update_time_before_death when: (clinical_status = need_ICU) and (is_ICU = false) {
		float start <- BENCHMARK ? machine_time : 0.0;
		time_before_death <- time_before_death -1;
		if(time_before_death<=0){
			clinical_status <- dead;
			state <- removed;
		}
		if BENCHMARK {bench["Biological Entity.update_time_before_death"] <- bench["Biological Entity.update_time_before_death"] + machine_time - start; }
	}
	
	//Reflex used to update the time in ICU of the entity, and change the entity status accordingly
	reflex update_time_in_ICU when: (clinical_status = need_ICU) and (is_ICU = true) {
		float start <- BENCHMARK ? machine_time : 0.0;
		time_ICU <- time_ICU -1;
		if(time_ICU<=0){
			//In the case of the entity being treated in ICU, but still dying
			if(viral_agent.flip_epidemiological_aspect(self,epidemiological_proportion_death_symptomatic)){
				clinical_status <- dead;
				state <- removed;
			}else{
				clinical_status <- need_hospitalisation;
			}
		}
		if BENCHMARK {bench["Biological Entity.update_time_in_ICU"] <- bench["Biological Entity.update_time_in_ICU"] + machine_time - start; }
	}
	
	//#############################################################
	// INFECTION
	//#############################################################
	
	//Action to define a new case, initialising it to latent and computing its latent period, and whether or not it will be symptomatic
	action define_new_case(virus infectious_agent) {
		state <- "latent";
		viral_agent <- infectious_agent;
		if(viral_agent.flip_epidemiological_aspect(nil,epidemiological_proportion_asymptomatic)){
			is_symptomatic <- false;
				latent_period <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_incubation_period_asymptomatic);
			}else{
				is_symptomatic <- true;
				presymptomatic_period <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_serial_interval);
				latent_period <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_incubation_period_symptomatic) + 
					(presymptomatic_period<0 ? presymptomatic_period : 0);
			}
	}
	
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: is_infectious
	{
		float start <- BENCHMARK ? machine_time : 0.0;
		//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		float reduction_factor <- 1.0;
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic;
		}
		
		//Perform human to human transmission
		if allow_transmission_human {
			float proba <- contact_rate*reduction_factor;
			list<BiologicalEntity> fellows <- BiologicalEntity where (flip(proba) and (each.state = susceptible));
			ask world {do console_output(sample(fellows), caller::"Biological_Entity.gaml");}
			ask fellows {
				do define_new_case;
			}
	 	}
		if BENCHMARK {bench["Biological Entity.infect_others"] <- bench["Biological Entity.infect_others"] + machine_time - start; }
	}
	
	//#############################################################
	// IMMUNITY
	//#############################################################
	
	//Action to build an immune response to a given virus which is equal to 1 minus immune escapement
	action build_immunity(virus va, float immune_escapement) { immunity[va] <- 1 - immune_escapement; }
	
	//Activate immune system to fight against infection of virus 'va' 
	// return > true : means immunity prevents from the infection
	// return > false : means failure of immune system
	bool activate_immunity(virus va) {
		
		// Immunity for this particular train
		if immunity contains_key va { return flip(immunity[va]); }
		
		// Immunity got from protection provided for the source strain of the variant 'va'
		if immunity contains_key va.source_of_mutation { return flip(immunity[va.source_of_mutation] * va.get_value_for_epidemiological_aspect(self, epidemiological_immune_evasion)); }
		
		// Immunity got from protection provided for the variant of the source strain 'va'
		// TODO : validate how protection against a variant protect from the source strain !!!
		if immunity.keys collect (each.source_of_mutation) contains va { return va.flip_epidemiological_aspect(self, epidemiological_reinfection_probability); }
		
		// If there is no linked immunity, then no body protection
		return false;
	}
	
	
	//#############################################################
	//States
	//#############################################################
	//State when the entity is susceptible
	state susceptible initial: true{
		enter{
			do set_status;
		}
	}
	
	//State when the entity is latent
	state latent {
		enter{
			tick <- 0.0;
			do set_status;
		}
		tick <- tick+1;
		
		transition to: symptomatic when: (tick>=latent_period) and (self.is_symptomatic) and (presymptomatic_period>=0);
		transition to: presymptomatic when: (tick>=latent_period) and (self.is_symptomatic) and (presymptomatic_period<0);
		transition to: asymptomatic when: (tick>=latent_period) and (self.is_symptomatic=false);
	}
	
	//State when the entity is presymptomatic
	state presymptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			presymptomatic_period <- abs(presymptomatic_period);
		}
		tick <- tick+1;
		transition to: symptomatic when: (tick>=presymptomatic_period);
	}
	
	//State when the entity is symptomatic
	state symptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			infectious_period <-  viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_infectious_period_symptomatic);
			if(viral_agent.flip_epidemiological_aspect(self,epidemiological_proportion_hospitalisation)){
				//Compute the time before hospitalisation knowing the current biological status of the agent
				time_symptoms_to_hospitalisation <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_onset_to_hospitalisation, self.infectious_period); 
				if(time_symptoms_to_hospitalisation>infectious_period)
				{
					time_symptoms_to_hospitalisation <- infectious_period;
				}
				//Check if the Individual will need to go to ICU
				if(viral_agent.flip_epidemiological_aspect(self,epidemiological_proportion_icu))
				{
					//Compute the time before going to ICU once hospitalised
					time_hospitalisation_to_ICU <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_hospitalisation_to_ICU, self.time_symptoms_to_hospitalisation);
					time_stay_ICU <-  viral_agent.get_value_for_epidemiological_aspect(self, epidemiological_stay_ICU);
					if(time_symptoms_to_hospitalisation+time_hospitalisation_to_ICU>=infectious_period)
					{
						time_symptoms_to_hospitalisation <- infectious_period-time_hospitalisation_to_ICU;
					}
				}
			}	
		}
		tick <- tick+1;
		if(tick>=time_symptoms_to_hospitalisation)and(clinical_status=no_need_hospitalisation)and(time_symptoms_to_hospitalisation>0){
			clinical_status <- need_hospitalisation;
		}
		
		if(tick>=time_hospitalisation_to_ICU+time_symptoms_to_hospitalisation)and(time_hospitalisation_to_ICU>0){
			clinical_status <- need_ICU;
			time_before_death <- time_stay_ICU;
			time_ICU <- time_stay_ICU;
		}
		
		
		transition to: removed when: (tick>=infectious_period){
			if(clinical_status=no_need_hospitalisation){
				clinical_status <- recovered;
			}else{
				//In case no hospital is taking care of the entity
				if(is_hospitalised=false){
					if(clinical_status=need_hospitalisation)and(time_hospitalisation_to_ICU<0){
						clinical_status <- recovered;
					}
				}
			}
		}
	}
	
	//State when the entity is asymptomatic
	state asymptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			infectious_period <- viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_infectious_period_asymptomatic);
		}
		tick <- tick+1;
		transition to:removed when: (tick>=infectious_period){
			clinical_status <- recovered;
		}
	}
	
	//State when the entity is not infectious anymore
	state removed{
		enter{
			// If the agent recovered, then he build an immune response
			if clinical_status != dead and not (immunity contains_key viral_agent) { 
				do build_immunity(viral_agent, viral_agent.get_value_for_epidemiological_aspect(self,epidemiological_reinfection_probability));
			}
		}
		
		do set_status;
		
		// If there is re-infection in the model, then move back to susceptible
		transition to:susceptible when:clinical_status != dead and allow_reinfection {
			infection_history[viral_agent] <- clinical_status;
			viral_agent <- nil;
			// TODO : all epidemiological variable should be reset 
		}
	}
	
}