/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* 
* Description: 
* 	Model with a total lockdown policy applied during a given number of days.
* 	In a total lockdown, no activities are allowed, and this is applied to all the Individuals.
* 	After this lockdown period, no policy is applied.
* 
* Parameters:
* 	- numb_days: defines the number of days for the lockdown application.
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology,lockdown
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	// Parameter used to define the duration of the lockdown policy
	int num_days <- 120;

	/*
	 * Initialize the lockdown policy over a given duration: no activities are allowed.
	 */
	action define_policy{
		ask Authority {
			if (num_days > 0) {
				policy <- create_lockdown_policy();
				policy <- during(policy, num_days); 
			}
		}
	}

}

experiment "Lockdown" parent: "Abstract Experiment" {
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
		display "Plot" parent: states_evolution_chart {}	
	}
}