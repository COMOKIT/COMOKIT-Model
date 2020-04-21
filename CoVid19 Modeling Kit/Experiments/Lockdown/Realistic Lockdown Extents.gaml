/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
***/

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
			create simulation with: [color::(colors at int(color_browser)), dataset::shape_path, seed::simulation_seed] {
				name <-  string(int(percentage*100)) + "% of unconfined people";
				
				percentage_of_people_allowed <- percentage;
				do define_policy();
			}

			color_browser <- color_browser + 1;
		}

	}

	permanent {
		display "charts" toolbar: false background: #black refresh: every(24 #cycle) {
			chart "Infected cases" /*"Infected and reported cases"*/ background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 12, #bold) title_visible: true {
				loop s over: simulations {
					data s.name /*  + " (infected)"*/ value: s.number_of_infectious color: s.color marker: false style: line thickness: 2;
					//data s.name + " (reported)" value: s.total_number_reported color: s.color marker: true line_visible: false thickness: 1;
				}

			}

			graphics "title" {
				draw ("Day " + int((current_date - starting_date) / #day)) font: default at: {100 #px, 0} color: #white anchor: #top_left;
			}

		}

	}

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: false;
		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {5 #px, 5 #px} color: world.color anchor: #top_left;
			}

		}

	}

}

/*
 *
 *	HEADLESS/BATCH !
 *
 */
experiment "Realistic Lock Down Batch" parent: "Abstract Batch Experiment" 
	type: batch repeat: 500 keep_seed: true until: ((Individual count each.is_infected = 0) and had_infected_Individual) or world.sim_stop() 
{
	method exhaustive;
	
	// CONFINMENT POLICY
	parameter "Percentage of people allowed" var: percentage_of_people_allowed init: 0.0 min: 0.0 max: 0.5 step: 0.05;
	parameter "Nbr of cases needed to start the policy" var:nb_cases init:0 min:0 max: 100 step: 5;
	parameter "Nbr of days of lockdown" var:nb_days init: 7 min: 7 max: 182 step: 7; // Max ~6months	
	
	// COVID TEST POLICY
	//parameter "number of tests" var: number_of_tests_per_step init: 10 min: 0 max: 10000 among: [10, 100];
	//parameter var:only_untested_ones among: [true, false];
	//parameter var:only_symptomatic_ones among: [true, false];
	
	permanent {
		
		display "charts" toolbar: false background: #black{
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
		
		display "Cumulative incidence" toolbar: false background: #black{
			chart "Cumulative incidence" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.total_number_of_infected color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
	}

}

experiment "Unconfined Individuals Headless" parent: "Abstract Batch Headless" {
	parameter "Percentage of people allowed" var: percentage_of_people_allowed init: 0.0 min: 0.0 max: 0.5 step: 0.05;
	parameter "Nbr of cases needed to start the policy" var:nb_cases init:0 min:0 max: 100 step: 5;
	parameter "Nbr of days of lockdown" var:nb_days init: 7 min: 7 max: 182 step: 7; // Max ~6months	
}