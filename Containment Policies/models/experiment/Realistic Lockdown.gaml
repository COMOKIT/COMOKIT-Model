/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "../species/Policy.gaml"
import "Abstract Experiment.gaml"

experiment "Realistic Lock Down" parent: "Abstract Experiment" {
	map<string, unknown> ask_values {
		float p <- -1.0;
		map<string, unknown> result;
		loop while: (p > 1) or (p < 0) {
			result <- user_input("Initialization", ["Proportion (between 0 and 1) of essential workers allowed to go out"::0.1, "Daily number of tests"::300]);
			p <- float(result["Proportion (between 0 and 1) of essential workers allowed to go out"]);
		}

		return result;
	}

	action _init_ {
		map<string, unknown> input <- ask_values();
		float percentage_ <- float(input["Proportion (between 0 and 1) of essential workers allowed to go out"]);
		int number_of_tests_ <- int(input["Daily number of tests"]);
		create simulation {
			name <- "No containment policy";
			ask Authority {
				policy <- create_no_containment_policy();
			}

		}

		create simulation {
			name <- "Realistic lockdown with " + int(percentage_ * 100) + "% of essential workers and " + number_of_tests_ + " daily tests";
			transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, true);
				AbstractPolicy l <- create_lockdown_policy_with_percentage(percentage_);
				policy <- combination([d, l]);
			}

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

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: false;
		
		display "Main" parent: default_display {
		}

	}

}

/*
 * Init for the realistic lock down batch exploration
 */
global { 
	float percentage; 
	int number_of_tests; 
	init {
		ask Authority { 
			transmission_building <- true;
			AbstractPolicy d <- create_detection_policy(number_of_tests, false, true);
			AbstractPolicy l <- create_lockdown_policy_with_percentage(percentage);
			policy <- combination([d, l]);
		} 
		dataset <- "../../data/Test dataset 1/";
	} 
	
	bool sim_stop { return time > 2#week and total_number_of_infected = 0; }
	
	list<int> nb_infected;
	reflex look_at_infected { nb_infected <+ total_number_of_infected; }
	string output_folder <- "../../output/test.csv";
}

experiment "Realistic Lock Down Batch" parent:"Abstract Experiment" type:batch 
	repeat: 30 keep_seed: true until: world.sim_stop() {
	
	parameter "percentage" var:percentage init:0.0 min:0.0 max:1.0 step:0.5;
	parameter "number of tests" var:number_of_tests init:10 min:0 max:10000 among:[10,100]; 
	
	method exhaustive;
	
	reflex nbi { ask simulations { 
		save [percentage,number_of_tests,nb_infected] type:csv to:output_folder rewrite:false;
	} }
}