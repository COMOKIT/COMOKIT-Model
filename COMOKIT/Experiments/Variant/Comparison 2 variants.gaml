/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Benoit Gaudou
* 
* Description: 
* 	Comparison of infection by 2 variaantss: it creates one simulation with a no containment policy 
* 		and plots the evolution of the number of individuals infecte by each variant.
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology
******************************************************************/

model Comparison2variants

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	//number of infected individuals by the original strain at the initialization of the simulation
	int num_infected_init <- 2; 
	//number of infected individuals by the B.1.1.7  (UK) variant at the initialization of the simulation	
	int num_infected_init_variant <- 2;
		
	/*
	 * Used to initialize a second variant infection
	 */
	action after_init {
		virus variant <- VOC first_with (each.name = "B.1.1.7");
		ask num_infected_init_variant among (all_individuals where (each.state = susceptible)) { 
			do define_new_case(variant);
		}
	}	
	
	action define_policy{   
		ask Authority {
			name <- "No containment policy";
			policy <- create_no_containment_policy();
		}
	}	
}

experiment "No Containment" parent: "Abstract Experiment" autorun: true {
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
		display "Infections by variants" parent: infections_by_variant {}
	}
}
