/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Damien Philippon
* 
* Description: 
* 	COMOKIT integrates 2 ways of disease transmission: human-to-human transmission and transmission through buildings 
* 	The model compares the 4 possibles combinations of these 2 transmission ways:
* 		- no transmission
* 		- human transmission only
* 		- transmission through environment (with virus load in buildings)
* 		- human transmission and transmission through environment (with virus load in buildings)
* 	No policy is applied.
* 
* Dataset: chosen by the user (through a choice popup)
*  
* Tags: covid19,epidemiology,policy comparison, sensitivity analysis
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Batch Experiment.gaml"

global{
	
	list<string> force_parameters <- list(epidemiological_transmission_building,epidemiological_basic_viral_decrease,epidemiological_basic_viral_release);
}

experiment "Comparison" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		
		/*
		 * Initialize a simulation without disease transmission  
		 */	
		create simulation with: [dataset_path::shape_path, seed::simulation_seed, allow_transmission_building::false, allow_transmission_human::false] {
			name <- "No viral load, no human transmission";
			ask Authority {
				policy <- create_no_containment_policy();
			}
		}

		/*
		 * Initialize a simulation with only transmission through environment 
		 */	
		create simulation with: [dataset_path::shape_path, seed::simulation_seed, allow_transmission_building::true, allow_transmission_human::false]{
			name <- "With viral load, no human transmission";
			ask Authority { 
				policy <- create_no_containment_policy();
			}
		}

		/*
		 * Initialize a simulation with only human transmission 
		 */			
		create simulation with: [dataset_path::shape_path, seed::simulation_seed, allow_transmission_building::false, allow_transmission_human::true] {
			name <- "No viral load, with human transmission";
			ask Authority {
				policy <- create_no_containment_policy();
			}
		}

		/*
		 * Initialize a simulation with both transmission through environment and human transmission
		 */	
		create simulation with: [dataset_path::shape_path, seed::simulation_seed, allow_transmission_building::true, allow_transmission_human::true]{
			name <- "With viral load and human transmission";
			ask Authority { 
				policy <- create_no_containment_policy();
			}
		}
	}
	
	permanent {
		display "charts" parent: infected_cases {
			graphics "title" {
				draw ("Day " + int((current_date - starting_date) /  #day))  font: default at: {100#px, 0} color:#white anchor: #top_left;
			}			
		}
		display "cumulative" parent: cumulative_incidence {}
	}


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		display "Main" parent: default_display {}
	}
}

experiment HeadlessComparison parent: "Abstract Headless"  {
	parameter "Allow Transmission Building" var: allow_transmission_building init: true; 
	
	parameter "Basic Viral Release" var: basic_viral_release init: 0.01 min: 0.01 max: 0.1 step: 0.01; // if: [allow_transmission_building,true]
	parameter "Basic Viral Decrease" var: basic_viral_decrease init: 0.02 min: 0.02 max: 0.2 step: 0.02; // if: [allow_transmission_building,true]
}
