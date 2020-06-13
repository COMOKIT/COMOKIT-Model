/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* 
* Description: 
* 	Model illustrating a local lockdown policy applied with a given tolerance:
* 		initially, a local lockdown is decided around each infected Individual (i.e. in a circle of a given radius, no activity is allowed).
*	In the application area, a rate of the population is nevertheless allowed to do its activities.
* 	Outside of the application areas, Individuals are free to act following their agenda.
* 
* Parameters:
* 	- tolerance: defines the rate of the population who is allowed to do its activities. (default value: 0.2)
* 	- radius_lockdown: the radius of the policy application area (default value: 200 #m)
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology,lockdown
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {	
	list<Individual> sources <- [];
	float tolerance <- 0.2;
	float radius_lockdown <- 200 #m;

	/*
	 * Initialize the radius lockdown policy (around infected Individuals) with a given tolerance.
	 */	
	action define_policy {
		name <- "Radius lockdown with " + int(tolerance * 100) + "% of tolerance";
		ask Authority {
			ask all_individuals where (each.state != susceptible) {
				sources << self;
				state <- symptomatic;
			}

			list<AbstractPolicy> policies <- [];
			loop i over: sources {
				policies << with_tolerance(create_lockdown_policy_in_radius(i.location, radius_lockdown), tolerance);
			}

			policy <- combination(policies);
		}
	}
}

experiment "Radius Quarantine" parent: "Abstract Experiment" autorun: true {
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;				
		
		display "Main" parent: default_display {
			species SpatialPolicy transparency: 0.7{
				draw application_area empty: false color: #red;
			}
		}
		display "Chart" parent: states_evolution_chart {}
	}
}