/**
* Name: Sensitivity_Analysis
* 
* This file define experiments to perform sensitivity analysis using Sobol and Morris methods.
* The parameters to test are :
*			nb_init_infected,
*			density_ref_contact,
*			init_all_ages_successful_contact_rate_human,
*			init_all_ages_factor_contact_rate_asymptomatic,
*			init_all_ages_proportion_asymptomatic,
*			init_all_ages_proportion_hospitalisation,
*			init_all_ages_proportion_icu,
*			init_all_ages_proportion_dead_symptomatic
* The output of interest are :
*			nb_dead,
*			nb_recovered,
*			nb_susceptibles,
*			nb_infectious,
*			nb_infected,
*			step_epidemiological_peak,
*			step_end_epidemiology
* 
* Gui experiment "test" can be run to perform 1 simulation and shows outputs of the model but doesn't
* perform sensitivity analysis.
* 
* Gui experiment "headless" should be run headless with xml files generated with the python script
* "generate_sensitivity.py" that perform Saltelli or Morris sampling. This will evaluate the model
* for the corresponding sample and save result into "./Results/Results_COMOKIT.csv" file.
* Then to compute Sobol or Morris indices please see 
* 
* Batch experiment "Sobol" and "Morris" can be use directly for fewer sample but the Sensitivity Analysis
* won't be as good.
* 
* /!\ You should delete the folder "Results" before performing sensitivity analysis to ensure that 
* the previous analysis doesn't interfere.
* 
* Author: Raphaël Dupont
* Tags: Sensitivity
*/


model Sensitivity_Analysis

import "../Models/Experiments/Abstract Experiment.gaml"

global {
	//benchmark 
	float t0; // t0 of the xp
	int s; // seed of the xp
	
	// Maximum simulation step
	int MAX_STEP <- 2232 const: true; // 3 mois
	
	//output variables
		// outputs per step of simulation
	int nb_susceptibles -> group_individuals sum_of (each.num_susceptibles);
	int nb_infected -> group_individuals sum_of(each.num_latent_asymptomatics + each.num_latent_symptomatics + each.num_symptomatic + each.num_asymptomatic);
	int nb_infectious -> group_individuals sum_of (each.num_symptomatic + each.num_asymptomatic);
	int nb_recovered -> group_individuals sum_of (each.num_recovered);
	int nb_hospitalized -> group_individuals sum_of(each.num_hospitalisation);
	int nb_ICU -> group_individuals sum_of(each.num_icu);
	int nb_dead -> group_individuals sum_of (each.num_dead);
		// aggregate output
	int max_hospitalization <- -1;
	int max_icu <- -1;
	int step_epidemiological_peak <- 0;
	int step_end_epidemiology <- MAX_STEP;
	
	
	// update step_epidemiological_peak
	int max_epidemiological_peak <- -1;
	reflex update_peak when: nb_infected > max_epidemiological_peak{
		max_epidemiological_peak <- nb_infected;
		step_epidemiological_peak <- cycle;
	}
	
	// update max_icu
	reflex max_icu when: max_icu < nb_hospitalized{
		max_icu <- nb_hospitalized;
	}
	
	// update max_hospitalization
	reflex update_max_hospitalized when: max_hospitalization < nb_hospitalized{
		max_hospitalization <- nb_hospitalized;
	}
	
	// Update step_end_epidemiology
	reflex end_epidemiology when: nb_infected <=0 and nb_infectious <=0 and nb_hospitalized <=0 and nb_ICU<=0 and step_end_epidemiology=MAX_STEP{
		step_end_epidemiology <- cycle;
	}
	
	reflex start when: cycle=1{
		// starting time of the experiment
		t0 <- machine_time;
		write "["+ s + "] Start experiment ...";
	}

	reflex stop_and_save when: cycle = MAX_STEP-1 {
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
			home_infection_rate,
			
			// Outputs
			nb_dead,
			max_icu,
			max_hospitalization,
			step_epidemiological_peak,
			step_end_epidemiology,
			
			// To identify the experiment
			seed
		] to:"./Results/Results_COMOKIT.csv" type:"csv" rewrite: false;	
		
		
		// Write execution time
		write "["+ s + "] End. Execution time : " + string ((machine_time - t0) / 1000) + "s. Result saved";
		
	}

	// Save state of simulation once a day for plots
	reflex save_outputs when: every(nb_step_for_one_day#cycle){
		save[
			cycle,
			nb_susceptibles,
			nb_recovered,
			nb_hospitalized,
			nb_ICU,
			nb_dead
		] to: ("./Results/plots/time_series_" + s + ".csv") type: "csv" rewrite: cycle=0 ? true : false;
	}
	
	init {
		s <- floor(seed) as int;
		
		// No reinfection
		allow_reinfection <- false;
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




experiment test type: gui keep_simulations: false {
    parameter "Nb init infected" var: nb_init_infected min:1 max:50000;
    parameter "Density ref contact" var:density_ref_contact min: 10.0 max: 500.0;
    parameter "Succeful contact rate proba" var: init_all_ages_successful_contact_rate_human min: 0.001 max: 0.999;
    parameter "factor contact rate asymptomatic" var: init_all_ages_factor_contact_rate_asymptomatic min: 0.001 max: 0.999;
    parameter "Asymptomatic proportion" var: init_all_ages_proportion_asymptomatic min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic case hospitalised" var: init_all_ages_proportion_hospitalisation min: 0.001 max: 0.999;
    parameter "Proportion of hospitalised going to ICU" var: init_all_ages_proportion_icu min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic dying" var: init_all_ages_proportion_dead_symptomatic min: 0.001 max: 0.999;
    parameter "Home infection rate" init:0.999 var: home_infection_rate min:0.001 max:0.999;
    
    
   output{
	display Population_information refresh:every(1#cycles) {
		chart "evolution" type: series{
			data "susceptibles" value: nb_susceptibles color: #blue;
			data "infected" value: nb_infected color: #orange;
			data "infectious" value: nb_infectious color: #red;
			data "recovered" value: nb_recovered color: #green;
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
	monitor "step_epidemiological_peak" value: step_epidemiological_peak;
	monitor "step_end_epidemiology" value: step_end_epidemiology;
	monitor "max_icu" value: max_icu;
	monitor "max_hospitalization" value: max_hospitalization;
	monitor "susceptibles" value: nb_susceptibles;
	monitor "infected" value: nb_infected;
	monitor "infectious" value: nb_infectious;
	monitor "recovered" value: nb_recovered;
	monitor "hospitalized" value: nb_hospitalized;
	monitor "ICU" value: nb_ICU;
	monitor "dead" value: nb_dead;
    }
}


experiment headless type: gui keep_simulations: false {
    parameter "Nb init infected" var: nb_init_infected min:1 max:50000;
    parameter "Density ref contact" var:density_ref_contact min: 10.0 max: 500.0;
    parameter "Succeful contact rate proba" var: init_all_ages_successful_contact_rate_human min: 0.001 max: 0.999;
    parameter "factor contact rate asymptomatic" var: init_all_ages_factor_contact_rate_asymptomatic min: 0.001 max: 0.999;
    parameter "Asymptomatic proportion" var: init_all_ages_proportion_asymptomatic min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic case hospitalised" var: init_all_ages_proportion_hospitalisation min: 0.001 max: 0.999;
    parameter "Proportion of hospitalised going to ICU" var: init_all_ages_proportion_icu min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic dying" var: init_all_ages_proportion_dead_symptomatic min: 0.001 max: 0.999;
    parameter "Home infection rate" var: home_infection_rate min:0.001 max:0.999;
}

/*
experiment Sobol type:batch until: (cycle = MAX_STEP - 1) {
	parameter "Nb init infected" var: nb_init_infected min:1 max:50000;
    parameter "Density ref contact" var:density_ref_contact min: 10.0 max: 500.0;
    parameter "Succeful contact rate proba" var: init_all_ages_successful_contact_rate_human min: 0.001 max: 0.999;
    parameter "factor contact rate asymptomatic" var: init_all_ages_factor_contact_rate_asymptomatic min: 0.001 max: 0.999;
    parameter "Asymptomatic proportion" var: init_all_ages_proportion_asymptomatic min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic case hospitalised" var: init_all_ages_proportion_hospitalisation min: 0.001 max: 0.999;
    parameter "Proportion of hospitalised going to ICU" var: init_all_ages_proportion_icu min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic dying" var: init_all_ages_proportion_dead_symptomatic min: 0.001 max: 0.999;
    parameter "Home infection rate" var: home_infection_rate min:0.001 max:0.999;
    
	method sobol
		outputs:["nb_dead",						//List of outputs of interest
			"nb_recovered",
			"nb_susceptibles",
			"nb_infectious",
			"nb_infected",
			"step_epidemiological_peak",
			"step_end_epidemiology",
			"seed"]
	sample:2					// should be a power of 2	/!\ nb_sim = sample * (2 * nb_param + 2)
	path:"./Results/Sobol/sample.csv"		// path to the saltelli sample
	report:"./Results/Sobol/report.txt";		// path to the report
}

experiment Morris type:batch until: (cycle = MAX_STEP - 1) {
	parameter "Nb init infected" var: nb_init_infected min:1 max:50000;
    parameter "Density ref contact" var:density_ref_contact min: 10.0 max: 500.0;
    parameter "Succeful contact rate proba" var: init_all_ages_successful_contact_rate_human min: 0.001 max: 0.999;
    parameter "factor contact rate asymptomatic" var: init_all_ages_factor_contact_rate_asymptomatic min: 0.001 max: 0.999;
    parameter "Asymptomatic proportion" var: init_all_ages_proportion_asymptomatic min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic case hospitalised" var: init_all_ages_proportion_hospitalisation min: 0.001 max: 0.999;
    parameter "Proportion of hospitalised going to ICU" var: init_all_ages_proportion_icu min: 0.001 max: 0.999;
    parameter "Proportion of symptomatic dying" var: init_all_ages_proportion_dead_symptomatic min: 0.001 max: 0.999;
    parameter "Home infection rate" var: home_infection_rate min:0.001 max:0.999;
    
    
	method morris
		outputs:["nb_dead",						//List of outputs of interest
			"nb_recovered",
			"nb_susceptibles",
			"nb_infectious",
			"nb_infected",
			"step_epidemiological_peak",
			"step_end_epidemiology",
			"seed"]
		levels: 4											// Level of Morris exploration
		sample: 16											// should be a product of 2		/!\ nb_sim = 2 * sample
		csv_file_parameters: "./Results/Morris/sample.csv"	// path to the sample
	results:"./Results/Morris/report.txt";				// path to the report
		
}
*/
