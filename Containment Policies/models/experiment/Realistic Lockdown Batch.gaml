/***
* Name: RealisticLockdownBatch
* Author: drogoul
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model RealisticLockdownBatch

import "../Global.gaml"
import "../species/Policy.gaml"
import "Abstract Experiment.gaml"
/*
 * Init for the realistic lock down batch exploration
 */
global {
	float percentage;
	int number_of_tests;

	init {
		transmission_building <- true;
		ask Authority {
			AbstractPolicy d <- create_detection_policy(number_of_tests, false, true);
			AbstractPolicy l <- create_lockdown_policy_except([act_home, act_shopping]);
			AbstractPolicy p <- create_positive_at_home_policy();
			l <- with_percentage_of_allowed_individual(l, percentage);
			policy <- combination([d, p, l]);
		}

		dataset <- "../../data/Test dataset 1/";
	}

	bool sim_stop {
		return time > 2 #week and total_number_of_infected = 0;
	}

	list<int> nb_infected;

	reflex look_at_infected {
		nb_infected <+ total_number_of_infected;
	}

	string output_folder <- "../../output/test.csv";
}

experiment "Realistic Lock Down Batch" parent: "Abstract Experiment" type: batch repeat: 30 keep_seed: true until: world.sim_stop() {
	parameter "percentage" var: percentage init: 0.0 min: 0.0 max: 1.0 step: 0.5;
	parameter "number of tests" var: number_of_tests init: 10 min: 0 max: 10000 among: [10, 100];
	method exhaustive;

	reflex nbi {
		ask simulations {
			save [percentage, number_of_tests, nb_infected] type: csv to: output_folder rewrite: false;
		}

	}
	
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