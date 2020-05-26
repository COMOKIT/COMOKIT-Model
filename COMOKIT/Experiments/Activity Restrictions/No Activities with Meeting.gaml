/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* 
* Description: 
* 	Model illustrating a policy that does not allow any activity that lets Individuals meet other Individuals.
*   Activities such as working, studying, going to school, eating, leisure, or sport are thus forbidden.
* 
* Parameters:
* 	The activities defined as a activity with meeting are defined in the global variable:
* 	- meeting_relaxing_act (in Parameters.gaml)
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology
******************************************************************/


model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

/*
 * Initialize a policy based on activity restrictions: working, studying and leisure (including having dinner or making sport outside) 
 */
global { 
	action define_policy{   
		ask Authority {
			name <- "No activity with meeting policy";
			policy <- create_no_meeting_policy();
		}
	}
}

experiment "No Meeting Activities" parent: "Abstract Experiment" autorun: true {
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
		display "Plot" parent: states_evolution_chart {}		
	}
}