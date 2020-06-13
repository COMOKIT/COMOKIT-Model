/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Kevin Chapuis
* 
* Description: 
* 	Model comparing 4 policies inspired by real ones: 
* 		- no containment, 
* 		- few test and lockdown policy with 10% of people doing they activities starting from 1% population confirmed cases (inspired by French policy)
* 		- mass test and confirmed case household stay at home (inspired by South-Korean policy)
*		- no test, at-risk individuals (50+ years old) stay home (inspired by UK policy)
* 	For each of the policies, the hospitalisation can (or not) be activated.
* 	One simulation on the same case study and with the same Random Number Generator seed  is created for each measure scenario.
* 
* Parameters:
* 	- Lockdown-related parameters:
* 		- percentage_of_people_allowed (default value: 0.1): ratio of the population allowed to do their activities
* 		- start_lockdown_until_prop (default value: 0.01): when more than start_lockdown_until_prop of the population is tested positive, the lockdown is decided  
* 		- stay_at_home_age_limit (default value; 50): age defining at-risk Individuals 
* 	- Test-related parameters:
* 		- small_test_sample (default value: 0.001): ratio of the population that is tested every step for few test policy
* 		- large_test_sample (default value: 0.005): ratio of the population that is tested every step for maass test policy
* 	- Hospitalization-related parameters:
* 		- number_of_test_in_hospital (default value: 2): the number of tests before releasing individuals can be changed in the policy initialization.
* 		- with_hospital_policy (boolean, default value: true): whether hospitalization policies are activated
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology,policy comparison
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	// Lockdown-related parameters
	float percentage_of_people_allowed <- 0.1;
	float start_lockdown_until_prop <- 0.01; 
	int stay_at_home_age_limit <- 50;
	
	// Tests-related parameters
	float small_test_sample <- 0.001;
	float large_test_sample <- 0.005;
	
	// Hospitalisation related parameters
	bool with_hospital_policy <- true;
	int number_of_test_in_hospital <- 2;
	
	string NO_POLICY <- "no policy";
	string FRENCH_POLICY <- "french style";
	string SOUTH_KOREAN_POLICY <- "south corean style";
	string BRITAIN_STYLE <- "britain style";
	string my_policy <- NO_POLICY;
	
	action define_policy {
		if empty(Authority) { 
			error "there is no authority created";
		}
		do console_output("Initializing "+my_policy+" policy", "Comparison of Realistic Actions.gaml");
				
		switch my_policy {
			match FRENCH_POLICY { do build_french_style_action(); }
			match SOUTH_KOREAN_POLICY { do build_south_corean_style_action(); }
			match BRITAIN_STYLE { do build_britain_style_plan(); }
			default {
				ask Authority {
					if with_hospital_policy { 
						policy <- create_hospitalisation_policy(true, true, number_of_test_in_hospital);
					} 
					else {
						policy <- create_no_containment_policy();
					}
				}
			}
		}
	}
	
	/*
	 * Few test and (consequently) late lockdown
	 */
	action build_french_style_action {
		ask Authority { 
			// Test policy
			AbstractPolicy d <- create_detection_policy(
				int(length(all_individuals) * small_test_sample), // 0.01% of the population 
				true, // only_symptomatic_ones = true 
				true // only_untested_ones
			);
			// Lockdown policy with 10% of people doing they activities starting from 10% population confirmed case
			AbstractPolicy l <- from_min_cases(
				with_tolerance(create_lockdown_policy(), percentage_of_people_allowed),
				int(length(all_individuals) * start_lockdown_until_prop)
			);
			AbstractPolicy r <- create_positive_at_home_policy();
			
			if with_hospital_policy { 
				policy <- combination([d, l, r, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);
			} 
			else { 
				policy <- combination([d, l, r]);
			}
		}
	}
	
	/*
	 * Mass test and confirmed case household stay at home
	 */
	action build_south_corean_style_action {
		ask Authority { 
			// Test policy
			AbstractPolicy d <- create_detection_policy(
				int(length(all_individuals) * large_test_sample), // 1% of the population 
				false, // only_symptomatic_ones = true 
				false // only_untested_ones
			);
			// confirmed case household stay at home
			AbstractPolicy l <- create_family_of_positive_at_home_policy(); 
			
			if with_hospital_policy { 
				policy <- combination([d, l, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);
			} 
			else { 
				policy <- combination([d, l]);
			}
		}
	}
	
	/*
	 * No test, at-risk people (50+ years old) stay home
	 */
	action build_britain_style_plan {
		ask Authority {
			AbstractPolicy l <- with_age_group_at_home_policy(policy,[(stay_at_home_age_limit::120)]);
			AbstractPolicy r <- create_positive_at_home_policy();
			if with_hospital_policy {
				policy <- combination([l, r, create_hospitalisation_policy(true, true, number_of_test_in_hospital)]);
			} else {
				policy <- combination([l,r]);
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
		create simulation with: [dataset_path::shape_path, seed::simulation_seed, 
			my_policy::FRENCH_POLICY
		] {
			name <- "Limited tests and late lockdown";
		}

		// --------------------------------------
		// SOUTH KOREAN TYPE OF POLICY
		// --------------------------------------
		create simulation with: [dataset_path::shape_path, seed::simulation_seed, 
			my_policy:: SOUTH_KOREAN_POLICY
		]{
			name <- "Mass test and confirmed cases' households quarantine";
		}

		// -------------------------------
		// GREAT BRITAIN EARLY POLICY
		// -------------------------------
		create simulation with: [dataset_path::shape_path, seed::simulation_seed,
			my_policy::BRITAIN_STYLE
		]{
			name <- "No test and people at risk stay home";
		}
		
		// NO CONTAINMENT BASELINE
		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{ 
			name <- "No policy";
		}
	}
	
	///////////
	// CHART //
	permanent {
		display "charts" parent: infected_cases refresh: every(24 #cycle) {}
		
		display "charts Deaths" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Dead cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data s.name value: length(s.all_individuals where(each.clinical_status=dead)) color: s.color marker: false style: line	 thickness: 2;
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
