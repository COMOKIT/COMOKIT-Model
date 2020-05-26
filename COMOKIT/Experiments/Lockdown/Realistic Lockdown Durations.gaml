/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	This model compares various durations of a "realistic" lockdown policy.
* 	The policy starts to be applied when a given number (nb_cases) of Individuals are positive to tests 
* 		and for a given duration (nb_days). 
* 	A realistic lockdown policy allows Individuals shopping and home activities only, with a given tolerance (e.g. for essential workers).
* 	As soon as an Individual is positive to a test, it has to stay home.
* 	During the simulation, a given number of tests (nb_tests_) are performed at every simulation step.
* 
* Parameters:
* 	- tolerance: defines the rate of the population who is allowed to do its activities (default value: 0.1)
* 	- nb_cases: the number of Individuals positive to tests needed to decide the application of the policy (default value: 20)
* 	- nb_tests_: number of tests performed every step (default value: 100)
* 	- the possible lockdown durations to be compared can be modified in the loop creating the simulations (default value: [0, 15, 30, 45, 60])
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

experiment "Early containment" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- brewer_colors("Paired");
		int color_browser <- 0;
		
		// Parameters of the policies implemented
		int nb_cases <- 20;
		float tolerance <- 0.1;
		int nb_tests_ <- 100;
		
		// The possible durations to be compared are 0, 15, 30, 45 and 60 days.
		loop nb_days over: [0, 15, 30, 45, 60] {
			create simulation with: [color::(colors at int(color_browser)), dataset_path::shape_path, seed::simulation_seed] {
				name <- string(nb_days) + " days containment after " + nb_cases + " cases";
				ask Authority {
					AbstractPolicy d <- create_detection_policy(nb_tests_, true, true);
					AbstractPolicy l <- create_lockdown_policy_except([act_home, act_shopping]);
					AbstractPolicy p <- create_positive_at_home_policy();
					l <- with_percentage_of_allowed_individual(l, tolerance);
					l <- from_min_cases(l, nb_cases);
					l <- during(l, nb_days);
					policy <- combination([d, p, l]);
				}
			}

			color_browser <- color_browser + 1;
		}
	}

	permanent {
		display "charts" parent: infected_cases refresh: every(24 #cycle) {
			graphics "title" {
				draw ("Day " + int((current_date - starting_date) / #day)) font: default at: {100 #px, 0} color: #white anchor: #top_left;
			}			
		}
	}

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;

		display "Main" parent: default_display {}
	}
}