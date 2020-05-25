/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"
import "../Abstract Batch Experiment.gaml"

global{
	// +==================
	// | Batch exploration variable
	// | Set with default values, but overwritten if the parameter is explored
	
	// CONFINMENT POLICY
	float percentage_of_people_allowed;
	int nb_cases <- 20;
	int nb_days <- 60;
	
	// COVID TEST POLICY
	int number_of_tests_per_step <- 100;
	bool only_untested_ones <- true;
	bool only_symptomatic_ones <- true;
	
	// See Constant.gaml for the list of activities
	list<string> allowed_activities <- [act_home, act_shopping];
	// 			==================+

	//@Override
	action define_policy{
		ask Authority {
			AbstractPolicy d <- create_detection_policy(number_of_tests_per_step, only_symptomatic_ones, only_untested_ones);
			AbstractPolicy l <- create_lockdown_policy_except(allowed_activities);
			AbstractPolicy p <- create_positive_at_home_policy();
			l <- with_percentage_of_allowed_individual(l, percentage_of_people_allowed);
			l <- from_min_cases(l, nb_cases);
			l <- during(l, nb_days);
			policy <- combination([d, p, l]);
		}
	}
	
}
experiment "Unconfined Individuals" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(10000.0);
		list<rgb> colors <- brewer_colors("Paired");
		int color_browser <- 0;
		
		loop percentage over: [0.05, 0.1, 0.2, 0.3, 0.4] {
			create simulation with: [color::(colors at int(color_browser)), dataset_path::shape_path, seed::simulation_seed] {
				name <-  string(int(percentage*100)) + "% of unconfined people";
				
				percentage_of_people_allowed <- percentage;
				do define_policy();
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
		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {5 #px, 5 #px} color: world.color anchor: #top_left;
			}
		}
	}
}