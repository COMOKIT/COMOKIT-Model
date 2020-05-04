/***
* Name: BiologicalEntity
* Author: damie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BiologicalEntity

/* Insert your model definition here */
import "../Functions.gaml"

species BiologicalEntity control:fsm{
	float latent_period;
	float presymptomatic_period;
	float infectious_period;
	float time_symptoms_to_hospitalisation <- -1.0;
	float time_hospitalisation_to_ICU <- -1.0;
	float time_stay_ICU;
	string clinical_status <- no_need_hospitalisation;
	bool is_hospitalised <- false;
	bool is_ICU <- false;
	float time_ICU;
	float tick <- 0.0;
	float time_before_death;
	bool is_infected;
	bool is_infectious;
	bool is_asymptomatic;
	bool is_symptomatic;
	string report_status <- not_tested;
	int last_test <- 0;
	int age;
	float factor_contact_rate_asymptomatic;
	float basic_viral_release;
	float contact_rate;
	Building current_place;
	//Number of times negatively tested
	int number_negative_tests <- 0;
	//#############################################################
	//Actions
	//#############################################################
	//Initialise epidemiological parameters according to the age of the Entity
	action initialise_epidemio {
		factor_contact_rate_asymptomatic <- world.get_factor_contact_rate_asymptomatic(age);
		basic_viral_release <- world.get_basic_viral_release(age);
		contact_rate <- world.get_contact_rate_human(age);
	}
	
	//Action to call when performing a test on a individual
	action test_individual
	{
		//If the Individual is infected, we check for true positive
		if(self.is_infected)
		{
			if(world.is_true_positive(self.age))
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
			if(world.is_true_negative(self.age))
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
	
	action set_status {
		is_infectious <- define_is_infectious();
		is_infected <- define_is_infected();
		is_asymptomatic <- define_is_asymptomatic();
	}
	
	action define_new_case{
		state <- "latent";
		if(world.is_asymptomatic(self.age)){
			is_symptomatic <- false;
			latent_period <- world.get_incubation_period_asymptomatic(self.age);
		}else{
			is_symptomatic <- true;
			presymptomatic_period <- world.get_serial_interval(self.age);
			latent_period <- presymptomatic_period<0?world.get_incubation_period_symptomatic(self.age)+presymptomatic_period:world.get_incubation_period_symptomatic(self.age);
		}
	}
	
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: is_infectious
	{
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
			write fellows;
			ask fellows {
				do define_new_case;
			}
	 	}
		
	}
	
	reflex update_time_before_death when: (clinical_status = need_ICU) and (is_ICU = false) {
		time_before_death <- time_before_death -1;
		if(time_before_death<=0){
			clinical_status <- dead;
			state <- removed;
		}
	}
	
	reflex update_time_in_ICU when: (clinical_status = need_ICU) and (is_ICU = true) {
		time_ICU <- time_ICU -1;
		if(time_ICU<=0){
			if(world.is_fatal(self.age)){
				clinical_status <- dead;
				state <- removed;
			}else{
				clinical_status <- need_hospitalisation;
			}
		}
	}
	
	
	//#############################################################
	//States
	//#############################################################
	state susceptible initial: true{
		enter{
			do set_status;
		}
	}
	
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
	
	state presymptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			presymptomatic_period <- abs(presymptomatic_period);
		}
		tick <- tick+1;
		transition to: symptomatic when: (tick>=presymptomatic_period);
	}
	
	state symptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			infectious_period <- world.get_infectious_period_symptomatic(self.age);
			if(world.is_hospitalised(self.age)){
				//Compute the time before hospitalisation knowing the current biological status of the agent
				time_symptoms_to_hospitalisation <- world.get_time_onset_to_hospitalisation(self.age,self.infectious_period);
				if(time_symptoms_to_hospitalisation>infectious_period)
				{
					time_symptoms_to_hospitalisation <- infectious_period;
				}
				//Check if the Individual will need to go to ICU
				if(world.is_ICU(self.age))
				{
					//Compute the time before going to ICU once hospitalised
					time_hospitalisation_to_ICU <- world.get_time_hospitalisation_to_ICU(self.age, self.time_symptoms_to_hospitalisation);
					time_stay_ICU <- world.get_time_ICU(self.age);
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
	
	state asymptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			infectious_period <- world.get_infectious_period_asymptomatic(self.age);
		}
		tick <- tick+1;
		transition to:removed when: (tick>=infectious_period){
			clinical_status <- recovered;
		}
	}
	
	state removed{
		enter{
			do set_status;
		}
	}
	
}