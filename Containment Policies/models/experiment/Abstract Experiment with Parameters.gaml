/***
* Name: AbstractExperimentwithParameters
* Author: dphilippon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model AbstractExperimentwithParameters

import "Abstract Experiment.gaml"
/* Insert your model definition here */

experiment "With parameters" parent: "Abstract Experiment" autorun: true {
	parameter "Epidemiological from file" category:"Epidemiology" var:load_epidemiological_parameter_from_file <- false; //Allowing parameters being loaded from a csv file 
	parameter "Path of Epidemiological from file" category:"Epidemiology"  var:epidemiological_parameters <- "../parameters/Epidemiological_parameters.csv"; //File for the parameters
	parameter "Allow human transmission" category:"Epidemiology"  var:transmission_human <- true; //Allowing human to human transmission
	parameter "Successful contact rate for human" category:"Epidemiology"  var:successful_contact_rate_human <- 2.5 * 1/(14.69973*nb_step_for_one_day);//Contact rate for human to human transmission derivated from the R0 and the mean infectious period
	parameter "Proportion of asymptomatic infections" category:"Epidemiology"  var:proportion_asymptomatic <- 0.3; //Proportion of asymptomatic infections
	parameter "Reduction contact rate for asymptomatic" category:"Epidemiology"  var:reduction_contact_rate_asymptomatic <- 0.55; //Factor of the reduction for successful contact rate for  human to human transmission for asymptomatic individual
	parameter "Proportion of fatal symptomatic infections" category:"Epidemiology"  var:proportion_dead_symptomatic <- 0.01; //Proportion of symptomatic infections dying
	parameter "Allow environment transmission" category:"Epidemiology"  var:transmission_building <- false; //Allowing environment contamination and infection
	parameter "Successful contact rate from environment" category:"Epidemiology"  var:successful_contact_rate_building <- 2.5 * 1/(14.69973*nb_step_for_one_day);//Contact rate for environment to human transmission derivated from the R0 and the mean infectious period
	parameter "Viral load released by infection individuals" category:"Epidemiology"  var:basic_viral_release <- 3.0; //Viral load released in the environment by infectious individual
	parameter "Viral load value removed from the environment" category:"Epidemiology"  var:viralLoadDecrease <- 0.33/nb_step_for_one_day; //Value to decrement the viral load in the environment
	parameter "Type of distribution for incubation" category:"Epidemiology"  among:["Normal","Lognormal","Gamma","Weibull"] var:distribution_type_incubation <- "Lognormal"; //Type of distribution of the incubation period; Among normal, lognormal, weibull, gamma
	parameter "Parameter 1 for incubation" category:"Epidemiology"  var:parameter_1_incubation <- 1.57; //First parameter of the incubation period distribution
	parameter "Parameter 2 for incubation" category:"Epidemiology"  var:parameter_2_incubation <- 0.65; //Second parameter of the incubation period distribution
	parameter "Type of distribution for serial interval" category:"Epidemiology"  among:["Normal","Lognormal","Gamma","Weibull"]   var:distribution_type_serial_interval <- "Normal"; //Type of distribution of the serial interval
	parameter "Parameter 1 for serial interval" category:"Epidemiology"  var:parameter_1_serial_interval <- 3.96;//First parameter of the serial interval distribution
	parameter "Parameter 2 for serial interval" category:"Epidemiology"  var:parameter_2_serial_interval <- 3.75;//Second parameter of the serial interval distribution
	parameter "Type of distribution for onset to recovery" category:"Epidemiology"  among:["Normal","Lognormal","Gamma","Weibull"]   var: distribution_type_onset_to_recovery <- "Lognormal";//Type of distribution of the time from onset to recovery
	parameter "Parameter 1 for onset to recovery" category:"Epidemiology"  var:parameter_1_onset_to_recovery <- 3.034953;//First parameter of the time from onset to recovery distribution
	parameter "Parameter 2 for onset to recovery" category:"Epidemiology"  var:parameter_2_onset_to_recovery <- 0.34;//Second parameter of the time from onset to recovery distribution
	parameter "True positive test" category:"Epidemiology"  var:probability_true_positive <- 0.89; //Probability of successfully identifying an infected
	parameter "True negative test" category:"Epidemiology"  var:probability_true_negative <- 0.92; //Probability of successfully identifying a non infected
	parameter "Proportion wearing mask" category:"Epidemiology"  var:proportion_wearing_mask <- 0.0; //Proportion of people wearing a mask
	parameter "Reduction wearing mask" category:"Epidemiology"  var:reduction_contact_rate_wearing_mask <- 0.5; //Factor of reduction for successful contact rate of an infectious individual wearing mask
	
	
	output {
		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {0, world.shape.height/2 - 30#px} color:world.color anchor: #top_left;
				
			}
		}

	}

}