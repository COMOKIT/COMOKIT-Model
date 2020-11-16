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
	bool BUILDING_TRANSMISSION_STRATEGY <- true;
	
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
		
	}
}