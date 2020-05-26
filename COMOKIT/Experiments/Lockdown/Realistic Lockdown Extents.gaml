/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	Model comparing a realistic lockdown policy with various rates of the population unconfined (for each tolerance value, one simulation is created and executed).
* 	A realistic lockdown policy allows Individuals shopping and home activities only, except for a given set of Individuals (e.g. for essential workers).
* 	As soon as an Individual is positive to a test, it has to stay home.
* 	During the simulation, a given number of tests (nb_tests_) are performed at every simulation step.
* 
* Parameters:
* 	- percentage_of_people_allowed: defines the rate of the population who is allowed to do its activities. 
* 			These Individuals are always allowed to perform each of their activities.
* 	- nb_cases: the number of Individuals positive to tests needed to decide the application of the policy (default value: 20)
* 	- nb_days: the lockdown duration 
* 	- number_of_tests_per_step: number of tests performed every step (default value: 100)
* 	- only_untested_ones: set whether Individuals are tested only once (or can be tested several times). 
* 			Tests are not 100% exact, and there are probabilities of false negatives and positives.
* 	- only_symptomatic_ones: set whether only the symptomatic are tested (or whether all the agents can be tested)
* 	- allowed_activities: list of the allowed activities (to all agents) during the lockdown (default value: [act_home, act_shopping])
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology,lockdown,policy comparison
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

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
	
		/*
		 * Initialize the "realistic" lockdown policy for each of the possible percentage value
		 * 	define_policy action is called automatically.
		 */	
		loop percentage over: [0.05, 0.1, 0.2, 0.3, 0.4] {
			create simulation with: [color::(colors at int(color_browser)), dataset_path::shape_path, seed::simulation_seed, 
				percentage_of_people_allowed::percentage
			] {
				name <-  string(int(percentage*100)) + "% of unconfined people";
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
