/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	Model illustrating a total lockdown policy applied on a population with a given tolerance.
* 	In a total lockdown, no activities are allowed.
* 	The tolerance expresses a rate of the population that is allowed to do its activities.
* 	Contrarily to "Realistic Lockdown Extents" model (where the Individuals allowed to move are always the same ones over the simulation,
* 		in this model the tolerance is only used as a probability to be allowed to do an activity.
* 
* Parameters:
* 	- tolerance: (asked to the user in a popup) defines the rate of the population who is allowed to do its activities.
*
*  Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology, lockdown
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {	
	float ask_tolerance {
		float t <- -1.0;
		loop while: (t > 1) or (t < 0) {
			t <- float(user_input("Tolerance with respect to activites (between 0.0: no tolerance, and 1.0: no constraint) ", [enter("Your choice",0.1)])["Your choice"]);
		}
		return t;
	}

	/*
	 * Initialize the lockdown policy with a given tolerance.
	 */
	action define_policy{
		float tolerance <- ask_tolerance();
		name <- "Partial lockdown with " + int(tolerance * 100) + "% of tolerance";
		ask Authority {
			policy <- with_tolerance(create_lockdown_policy(),tolerance);
		}
	}
}

experiment "Partial Lock Down" parent: "Abstract Experiment" autorun: true {

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;		
		
		display "Main" parent: default_display {}
		display "Chart" parent: states_evolution_chart {}
		display "Cumulative incidence" parent: cumulative_incidence {}
	}

}