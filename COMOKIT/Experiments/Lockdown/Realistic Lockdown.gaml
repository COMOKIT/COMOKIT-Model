/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	This model compares a policy without containment and a realistic lockdown policy.
* 	A realistic lockdown policy allows Individuals shopping and home activities only, with a given tolerance (e.g. for essential workers).
* 	As soon as an Individual is positive to a test, it has to stay home.
* 	During the simulation, a given number of tests (nb_tests_) are performed at every simulation step.
* 
* Parameters:
* 	- tolerance: defines the rate of the population who is allowed to do its activities (default value: 0.1)
* 	- nb_tests_: number of tests performed every step (default value: 100)
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology,lockdown
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

experiment "Realistic Lockdown" parent: "Abstract Experiment" autorun: true {
	map<string, unknown> ask_values {
		float p <- -1.0;
		map<string, unknown> result;
		loop while: (p > 1) or (p < 0) {
			result <- user_input("Initialization", [enter("Proportion (between 0 and 1) of essential workers allowed to go out",0.1), enter("Daily number of tests",300)]);
			p <- float(result["Proportion (between 0 and 1) of essential workers allowed to go out"]);
		}

		return result;
	}

	action _init_ {
		map<string, unknown> input <- ask_values();
		
		float tolerance <- float(input["Proportion (between 0 and 1) of essential workers allowed to go out"]);
		int nb_tests_ <- int(input["Daily number of tests"]);

		/*
		 * Initialize the no containment policy.
		 */		
		create simulation {
			name <- "No containment policy";
			ask Authority {
				policy <- create_no_containment_policy();
			}

		}

		/*
		 * Initialize the "realistic" lockdown policy with a given tolerance and a number of hourly tests.
		 */
		create simulation {
			name <- "Realistic lockdown with " + int(tolerance * 100) + "% of essential workers and " + nb_tests_ + " daily tests";
			allow_transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(nb_tests_, false, true);
				AbstractPolicy l <- create_lockdown_policy_except([act_home, act_shopping]);
				AbstractPolicy p <- create_positive_at_home_policy();
				l <- with_percentage_of_allowed_individual(l, tolerance);
				policy <- combination([d, p, l]);
			}

		}

	}
	
	permanent {
		display "charts" parent: infected_cases {}
		display "cumulative" parent: cumulative_incidence {}
	}

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
	}
}

