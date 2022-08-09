/**
* Name: experiments
* Based on the internal empty template. 
* Author: root
* Tags: 
*/


model Experiments

import "../Models/Experiments/Abstract Experiment.gaml"

global {
	//benchmark 
	float t0; // t0 of the xp
	int s; // seed of the xp
	
	// Maximum simulation step
	int MAX_STEP <- 365 * 24 const: true; // 1 year
	
	//output variables
	int nb_susceptibles -> group_individuals sum_of (each.num_susceptibles);
	int nb_infected -> group_individuals sum_of(each.num_latent_asymptomatics + each.num_latent_symptomatics + each.num_symptomatic + each.num_asymptomatic);
	int nb_infectious -> group_individuals sum_of (each.num_symptomatic + each.num_asymptomatic);
	int nb_recovered -> group_individuals sum_of (each.num_recovered);
	int nb_immune -> group_individuals sum_of(each.num_immune);
	int nb_hospitalized -> group_individuals sum_of(each.num_hospitalisation);
	int nb_ICU -> group_individuals sum_of(each.num_icu);
	int nb_dead -> group_individuals sum_of (each.num_dead);
	
	int step_end_epidemiology <- MAX_STEP;	
	int step_max_peak <- 0;
	int max_hospitalized <- 0;
	
	// update max peak
	int max_peak <- -1;
	reflex update_peak when: nb_infected > max_peak{
		max_peak <- nb_infected;
		step_max_peak <- cycle;
	}
	
	reflex update_max_hospitalized when: max_hospitalized < nb_hospitalized{
		max_hospitalized <- nb_hospitalized;
	}
	
	// test that population is stable
	int nb_tot <- 0 update: nb_susceptibles + nb_infected + nb_recovered + nb_hospitalized + nb_ICU + nb_dead;
	int old_tot <- nb_tot;
	reflex when: nb_tot != old_tot{
		write "/!\\ pop changed : " + nb_tot + " " + old_tot;
		old_tot <- nb_tot;
	}
	
	
	reflex start when: cycle=1{
		// starting time of the experiment
		t0 <- machine_time;
		write "["+ s + "] Start experiment ...";
	}
	
	reflex stop when: nb_infected <=0 or (cycle = MAX_STEP-1) {		
		// Update step_end_epidemiology
		step_end_epidemiology <- cycle;	
		
		// Save final Results
		save [
			// Inputs
			nb_init_infected,
			density_ref_contact,
			init_all_ages_successful_contact_rate_human,
			init_all_ages_factor_contact_rate_asymptomatic,
			init_all_ages_proportion_asymptomatic,
			init_all_ages_proportion_hospitalisation,
			init_all_ages_proportion_icu,
			init_all_ages_proportion_dead_symptomatic,
			
			// Outputs
			nb_dead,
			nb_recovered,
			nb_susceptibles,
			nb_infectious,
			nb_infected,
			step_max_peak,
			step_end_epidemiology,
			seed
		] to:"./Results/Results_COMOKIT.csv" type:"csv" rewrite: false;	
		
		
		// Write execution time
		write "["+ s + "] End. Execution time : " + string ((machine_time - t0) / 1000) + "s. Result saved";
		do pause;
	}

	
	reflex save_outputs when: every(12#cycles){
		save[
			cycle,
			nb_dead,
			nb_recovered,
			nb_susceptibles,
			nb_infectious,
			nb_infected
		] to: ("./Results/time_series_" + s + ".csv") type: "csv" rewrite: cycle=0 ? true : false;
	}
	
	init {
		s <- floor(seed) as int;
		
		// Allow reinfection
		allow_reinfection <- true;
		// TODO find and use actual values for icu capacity
		hospital_icu_capacity <- 100000;
		// List of parameters to study
		forced_sars_cov_2_parameters <- [
			epidemiological_successful_contact_rate_human,
			epidemiological_factor_asymptomatic,
			// TODO use distribution instead of a single value for all ages
			epidemiological_proportion_asymptomatic,
			epidemiological_proportion_hospitalisation,
			epidemiological_proportion_icu,
			epidemiological_proportion_death_symptomatic
		];
	}
	
	
	action define_policy{   
		ask Authority {
			name <- "No containment policy";
			policy <- create_no_containment_policy();
		}
	}
}




experiment Sobol type: gui keep_simulations: false {
    parameter "Nb init infected" var: nb_init_infected min:1 max:50000;
    parameter "Density ref contact" var:density_ref_contact min: 10.0 max: 500.0;
    parameter "Succeful contact rate proba" var: init_all_ages_successful_contact_rate_human min: 0.001 max: 0.999;
    parameter "factor contact rate asymptomatic" var: init_all_ages_factor_contact_rate_asymptomatic min: 0.001 max: 0.999;
    parameter "Asymptomatic proportion" var: init_all_ages_proportion_asymptomatic min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic case hospitalised" var: init_all_ages_proportion_hospitalisation min: 0.001 max: 0.999;
    parameter "Proportion of hospitalised going to ICU" var: init_all_ages_proportion_icu min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic dying" var: init_all_ages_proportion_dead_symptomatic min: 0.001 max: 0.999;
    
    
   output{
    	display Population_information refresh:every(1#cycles) {
	    	chart "evolution" type: series{
	        	data "susceptibles" value: nb_susceptibles color: #blue;
	        	data "infected" value: nb_infected color: #orange;
	        	data "infectious" value: nb_infectious color: #red;
	        	data "recovered" value: nb_recovered color: #green;
	        	data "immune" value: nb_immune color: #darkgreen;
	        	data "hospitalized" value: nb_hospitalized color: #grey;
	        	data "ICU" value: nb_ICU color: #darkgrey;
	        	data "dead" value: nb_dead color: #black;
	    	}	
	    }
	    
	    display icu_capacity refresh:every(1#cycles) {	
	    	chart "ICU capacity" type:pie {
	    		data "ICU used" value: nb_ICU;
	    		data "free ICU" value: hospital_icu_capacity - nb_ICU;
	    	}
    	}
    	monitor "max peak" value: step_max_peak;
    	monitor "end_epidemiology" value: step_end_epidemiology;
    	monitor "susceptibles" value: nb_susceptibles;
    	monitor "infected" value: nb_infected;
    	monitor "infectious" value: nb_infectious;
    	monitor "recovered" value: nb_recovered;
    	monitor "immune" value: nb_immune;
    	monitor "hospitalized" value: nb_hospitalized;
    	monitor "ICU" value: nb_ICU;
    	monitor "dead" value: nb_dead;
    }
}


