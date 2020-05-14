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

global {
	float percentage_of_people_allowed <- 0.1;
	float start_lockdown_until_prop <- 0.01; 
	float small_test_sample <- 0.001;
	float large_test_sample <- 0.1;
	int stay_at_home_age_limit <- 50;
	
	bool with_hospital_policy <- true;
	int number_of_test_in_hospital <- 2;
	
	list<string> policies <- ["no policy", "french style", "south corean style", "britain style"];
	string my_policy <- "no policy";
	
	action define_policy {
		if empty(Authority) { error "there is no authority created"; }
		do console_output("Initializing "+my_policy+" policy", "Comparison of Realistic Actions.gaml");
		result_folder <-  "../../batch_output/"+my_policy + "/";
		switch my_policy {
			match "french style" { do build_french_style_action(Authority[0]); }
			match "south corean style" { do build_south_corean_style_action(Authority[0]); }
			match "britain style" { do build_britain_style_plan(Authority[0]); }
			default {
				ask Authority {
					if with_hospital_policy { policy <- create_hospitalisation_policy(true, true, number_of_test_in_hospital); } 
					else {policy <- create_no_containment_policy();}
				}
			}
		}
	}
	
		/*
	 * Few test and (consequently) late lockdown
	 */
	action build_french_style_action(Authority authority) {
		ask authority { 
			// Test policy
			AbstractPolicy d <- create_detection_policy(
				length(Individual)*small_test_sample, // 0.1% of the population 
				true, // only_symptomatic_ones = true 
				true // only_untested_ones
			);
			// Lockdown policy with 10% of people doing they activities starting from 10% population confirmed case
			// TODO : better model for Frensh lock down policy allowance
			AbstractPolicy l <- from_min_cases(
				with_tolerance(create_lockdown_policy(), percentage_of_people_allowed),
				length(Individual)*start_lockdown_until_prop
			);
			AbstractPolicy r <- create_positive_at_home_policy();
			if with_hospital_policy { policy <- combination([d, l, r, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);} 
			else { policy <- combination([d, l, r]); }
		}
	}
	
	/*
	 * Mass test and confirmed case household stay at home
	 */
	action build_south_corean_style_action(Authority authority) {
		ask authority { 
			// Test policy
			AbstractPolicy d <- create_detection_policy(
				length(Individual)*large_test_sample, // 10% of the population 
				false, // only_symptomatic_ones = true 
				false // only_untested_ones
			);
			// confirmed case household stay at home
			AbstractPolicy l <- create_family_of_positive_at_home_policy(); 
			if with_hospital_policy { policy <- combination([d, l, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);} 
			else { policy <- combination([d, l]); }
		}
	}
	
	/*
	 * No test, at-risk people (50+ years old) stay home
	 */
	action build_britain_style_plan(Authority authority) {
		ask authority {
			AbstractPolicy l <- with_age_group_at_home_policy(policy,[(stay_at_home_age_limit::120)]);
			AbstractPolicy r <- create_positive_at_home_policy();
			if with_hospital_policy {
				policy <- combination([l, r, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);
			}
		}
	}
	
}

experiment "Comparison of realistic actions" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		
		// --------------------------------------
		// FRENCH TYPE OF POLICY
		// --------------------------------------
		create simulation with: [dataset_path::shape_path, seed::simulation_seed] {
			name <- "Limited tests and late lockdown";
			ask Authority { 
				// Test policy
				AbstractPolicy d <- create_detection_policy(
					int(length(Individual)*small_test_sample), // 1% of the population 
					true, // only_symptomatic_ones = true 
					true // only_untested_ones
				);
				// Lockdown policy with 10% of people doing they activities starting from 10% population confirmed case
				// TODO : better model for French lockdown policy allowance
				AbstractPolicy l <- from_min_cases(
					with_tolerance(create_lockdown_policy(), percentage_of_people_allowed),
					int(length(Individual)*start_lockdown_until_prop)
				);
				AbstractPolicy r <- create_positive_at_home_policy();
				if with_hospital_policy { policy <- combination([d, l, r, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);} 
				else { policy <- combination([d, l, r]); }
				 
			}

		}

		// --------------------------------------
		// SOUTH KOREAN TYPE OF POLICY
		// --------------------------------------
		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{
			name <- "Mass test and confirmed cases' households quarantine";
			ask Authority { 
				// Test policy
				AbstractPolicy d <- create_detection_policy(
					int(length(Individual)*large_test_sample), // 10% of the population 
					false, // only_symptomatic_ones = true 
					false // only_untested_ones
				);
				// confirmed case household stay at home
				AbstractPolicy l <- create_family_of_positive_at_home_policy(); 
				if with_hospital_policy { policy <- combination([d, l, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);} 
				else { policy <- combination([d, l]); }
			}
		}

		// -------------------------------
		// GREAT BRITAIN EARLY POLICY
		// -------------------------------
		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{
			name <- "No test and people at risk stay home";
			ask Authority {
				AbstractPolicy l <- with_age_group_at_home_policy(policy,[(stay_at_home_age_limit::120)]);
				AbstractPolicy r <- create_positive_at_home_policy();
				if with_hospital_policy {
					policy <- combination([l, r, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);
				}
			}
		}
		
		// NO CONTAINMENT BASELINE
		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{ 
			name <- "No policy";
			ask Authority {
				if with_hospital_policy { policy <- create_hospitalisation_policy(true, true, number_of_test_in_hospital); } 
				else {policy <- create_no_containment_policy();}
			}
		}
	}
	
	///////////
	// CHART //
	permanent {
		
		display "charts" toolbar: false background: #black refresh: every(24 #cycle) {
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
		
		display "charts Deaths" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Dead cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data s.name value: length(s.Individual where(each.clinical_status=dead)) color: s.color marker: false style: line	 thickness: 2;
				}
			}
		}
	}

	/////////////
	// DISPLAY //
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;
		display "Main" parent: default_display {}

	}
}

/*
 *	BATCH runs
 */
experiment "Comparison of realistic actions batch" parent: "Abstract Batch Experiment" 
	type: batch repeat: 1 until: world.sim_stop() keep_seed: true
{ 
	
	parameter "my_policy" var:my_policy among:["french style", "south corean style", "britain style", "no policy"];
	method exhaustive;

}

/*
 *	BATCH exploration
 */
experiment "Realistic actions batch exploration" parent: "Abstract Batch Experiment" 
	type: batch repeat: 20 keep_simulations:false until: world.sim_stop() 
{
	method exhaustive;
	
	// FRENCH STYLE OF ACTIONS
	parameter "Percentage of people allowed" var: percentage_of_people_allowed init: 0.0 min: 0.0 max: 0.5 step: 0.05;
	parameter "Start lockdown until proportion of confirmed cases" var: start_lockdown_until_prop init:0.1 min:0.0 max:0.4 step:0.1;
	parameter "Proportion of tested people per step" var:small_test_sample init:0.01 min:0.01 max:0.05 step:0.01;
	
	// SOUTH KOREAN STYLE OF ACTIONS
	parameter "Proportion of tested people per step" var:large_test_sample init:0.1 min:0.1 max:0.5 step:0.1;
	
	// GREAT BRITAIN STYLE ACTION PLAN
	parameter "Age limit until stay-at-home forced" var:stay_at_home_age_limit init:50 min:0 max:100 step:5;
	

}

