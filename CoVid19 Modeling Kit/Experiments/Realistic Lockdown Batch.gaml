/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Kevin Chapuis
* Tags: covid19,epidemiology
***/


model CoVid19

import "../Model/Global.gaml"
import "Abstract Batch Experiment.gaml"
/*
 * Init for the realistic lock down batch exploration
 */
global {
	
	// CONFINMENT POLICY
	int threshold_nb_cases_to_start_policy <- 10;
	int nb_days_long <- 1#month/#day;
	float percentage_of_people_allowed <- 0.05;
		// See Constant.gaml for the list of activities
	list<string> allowed_activities <- [act_home, act_shopping];
	
	// COVID TEST POLICY
	int number_of_tests_per_step <- 10;
	bool only_untested_ones <- true;
	bool only_symptomatic_ones <- true;

	init {
		transmission_building <- true;
		ask Authority {
					AbstractPolicy d <- create_detection_policy(number_of_tests_per_step, only_symptomatic_ones, only_untested_ones);
					AbstractPolicy l <- create_lockdown_policy_except(allowed_activities);
					AbstractPolicy p <- create_positive_at_home_policy();
					l <- with_percentage_of_allowed_individual(l, percentage_of_people_allowed);
					l <- from_min_cases(l, threshold_nb_cases_to_start_policy);
					l <- during(l, nb_days_long);
					policy <- combination([d, p, l]);
		}

		dataset <- "../Datasets/Test 1/";
	}

	list<int> nb_infected;

	reflex look_at_infected {
		nb_infected <+ total_number_of_infected;
	}

}

experiment "Realistic Lock Down Batch" parent: "Abstract Batch Experiment" 
	type: batch repeat: 2 keep_seed: true until:world.sim_stop() {
	parameter "percentage" var: percentage_of_people_allowed init: 0.0 min: 0.0 max: 1.0 step: 0.5;
	parameter "number of tests" var: number_of_tests_per_step init: 10 min: 0 max: 10000 among: [10, 100];
	method exhaustive;
	
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