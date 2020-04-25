/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Damien Philippon
* Tags: covid19,epidemiology
***/

model CoVid19

import "Abstract Experiment.gaml"

experiment "With parameters" parent: "Abstract Experiment" autorun: true {

	/** 
	* Enabling parameters being loaded from a csv file  
	*/
	parameter "Epidemiological from file" category: "Epidemiology" var: load_epidemiological_parameter_from_file <- false enables: [epidemiological_parameters];
	//File for the parameters
	parameter "Path of Epidemiological from file" category: "Epidemiology" var: epidemiological_parameters <- "../Parameters/Epidemiological Parameters.csv";

	/** 
	 * Enabling human to human transmission
	 */
	parameter "Enables inter-human transmission" category: "Epidemiology" var: allow_transmission_human <- true enables:
	[init_all_ages_successful_contact_rate_human, init_all_ages_proportion_asymptomatic, init_all_ages_factor_contact_rate_asymptomatic, init_all_ages_proportion_dead_symptomatic];
	//Contact rate for human to human transmission derivated from the R0 and the mean infectious period
	parameter "Successful contact rate for human" category: "Epidemiology" var: init_all_ages_successful_contact_rate_human <- 2.5 * 1 / (14.69973 * nb_step_for_one_day);
	//Proportion of asymptomatic infections
	parameter "Proportion of asymptomatic infections" category: "Epidemiology" var: init_all_ages_proportion_asymptomatic <- 0.3;
	//Factor of the reduction for successful contact rate for  human to human transmission for asymptomatic individual
	parameter "Reduction contact rate for asymptomatic" category: "Epidemiology" var: init_all_ages_factor_contact_rate_asymptomatic <- 0.55;
	//Proportion of symptomatic infections dying 
	parameter "Proportion of fatal symptomatic infections" category: "Epidemiology" var: init_all_ages_proportion_dead_symptomatic <- 0.01;

	/**
	 * Enabling environment contamination and infection
	 */
	parameter "Enables environmental transmission" category: "Epidemiology" var: allow_transmission_building <- false enables:
	[successful_contact_rate_building, basic_viral_release, basic_viral_decrease];
	//Contact rate for environment to human transmission derivated from the R0 and the mean infectious period
	parameter "Successful contact rate from environment" category: "Epidemiology" var: successful_contact_rate_building <- 2.5 * 1 / (14.69973 * nb_step_for_one_day); 
	//Viral load released in the environment by infectious individual
	parameter "Viral load released by infection individuals" category: "Epidemiology" var: basic_viral_release <- 3.0; 
	//Value to decrement the viral load in the environment
	parameter "Viral load value removed from the environment" category: "Epidemiology" var: basic_viral_decrease <- 0.33; 
	
	
	/**
	 * Other epidemiological parameters
	 */
	//Type of distribution of the incubation period; Among normal, lognormal, weibull, gamma
	parameter "Type of distribution for incubation" category: "Epidemiology" among: ["Normal", "Lognormal", "Gamma", "Weibull"] var:  init_all_ages_distribution_type_incubation <- "Lognormal"; 
	//First parameter of the incubation period distribution
	parameter "Parameter 1 for incubation" category: "Epidemiology" var:  init_all_ages_parameter_1_incubation <- 1.57; 
	//Second parameter of the incubation period distribution
	parameter "Parameter 2 for incubation" category: "Epidemiology" var:  init_all_ages_parameter_2_incubation <- 0.65; 
	//Type of distribution of the serial interval
	parameter "Type of distribution for serial interval" category: "Epidemiology" among: ["Normal", "Lognormal", "Gamma", "Weibull"] var:
	 init_all_ages_distribution_type_serial_interval <- "Normal"; 
	//First parameter of the serial interval distribution
	parameter "Parameter 1 for serial interval" category: "Epidemiology" var:  init_all_ages_parameter_1_serial_interval <- 3.96; 
	//Second parameter of the serial interval distribution
	parameter "Parameter 2 for serial interval" category: "Epidemiology" var:  init_all_ages_parameter_2_serial_interval <- 3.75; 
	//Type of distribution of the time from onset to recovery
	parameter "Type of distribution for onset to recovery" category: "Epidemiology" among: ["Normal", "Lognormal", "Gamma", "Weibull"] var:
	 init_all_ages_distribution_type_onset_to_recovery <- "Lognormal"; 
	//First parameter of the time from onset to recovery distribution
	parameter "Parameter 1 for onset to recovery" category: "Epidemiology" var:  init_all_ages_parameter_1_onset_to_recovery <- 3.034953; 
	//Second parameter of the time from onset to recovery distribution
	parameter "Parameter 2 for onset to recovery" category: "Epidemiology" var:  init_all_ages_parameter_2_onset_to_recovery <- 0.34; 
	//Probability of successfully identifying an infected
	parameter "True positive test" category: "Epidemiology" var:  init_all_ages_probability_true_positive <- 0.89; 
	//Probability of successfully identifying a non infected
	parameter "True negative test" category: "Epidemiology" var:  init_all_ages_probability_true_negative <- 0.92; 
	//Proportion of people wearing a mask
	parameter "Proportion wearing mask" category: "Epidemiology" var:  init_all_ages_proportion_wearing_mask <- 0.0; 
	//Factor of reduction for successful contact rate of an infectious individual wearing mask
	parameter "Reduction wearing mask" category: "Epidemiology" var:  init_all_ages_factor_contact_rate_wearing_mask <- 0.5; 
	output {
		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {0, world.shape.height / 2 - 30 #px} color: world.color anchor: #top_left;
			}

		}

	}

}