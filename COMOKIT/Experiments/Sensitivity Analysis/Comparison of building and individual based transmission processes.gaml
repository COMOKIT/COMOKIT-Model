/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: kevin chapuis <chapuisk>
* 
* Description: 
* 	Experiments intended to explore several transmission alternatif processes
* 	1 - default transmission : infectious agent go through all susceptible in the same building for a potential succeful contact
*   2 -  
* 
* Parameters:
* 	- The process to be tested
* 
* Dataset: Sample
* Tags: covid19,epidemiology,transmission process,sensitivity
******************************************************************/


model Alttransmissionprocesses

/* Insert your model definition here */

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	
	string case_study_folder_name <- "Sample";
	bool BUILDING_TRANSMISSION_STRATEGY init: true parameter:true ;
	bool BENCHMARK <- true;
	
	action define_policy{   
		ask Authority {
			name <- "No containment policy";
			policy <- create_no_containment_policy();
		}
	}
		
}

experiment "Alternative transmission processes" parent: "Abstract Experiment" autorun: true {
	output {
		layout #split editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
		display "Plot" parent: states_evolution_chart refresh: every(#day) {}	
		
		monitor "individual based transmission" value:with_precision(bench["Individual.infect_others"]/1000,2) refresh:every(#day);
		monitor "building based transmission" value:with_precision(bench["Building.infect_occupants"]/1000,2) refresh:every(#day);
		
	}
}

experiment "Transmission processes comparison" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string case_study <- "Vinh Phuc";
		float simulation_seed <- rnd(2000.0);
		
		/*
		 * Initialize a simulation where buildings manage the transmission  
		 */	
		create simulation with: [case_study_folder_name::case_study, seed::simulation_seed, BUILDING_TRANSMISSION_STRATEGY::true, BENCHMARK::true] {
			name <- "Building based transmission process";
			ask Authority {
				policy <- create_no_containment_policy();
			}
		}

		/*
		 * Initialize a simulation where infectious individuals  manage the transmission
		 */	
		create simulation with: [case_study_folder_name::case_study, seed::simulation_seed, BUILDING_TRANSMISSION_STRATEGY::false, BENCHMARK::true]{
			name <- "Individual based transmission process";
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
		monitor "Transmission process" value:with_precision(bench[BUILDING_TRANSMISSION_STRATEGY?"Building.infect_occupants":"Individual.infect_others"]/1000,2) refresh:every(#day);
		monitor "Active agents for transmission" value:BUILDING_TRANSMISSION_STRATEGY ? Building count (each.building_schedule) : Individual count (each.is_infectious);
		display "Main" parent: default_display {}
	}
}