/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Benoit Gaudou
* 
* Description: 
* 	Model comparing 4 local measures: no containment, realistic lockdown, 
* 		family containment (the whole family at home when a signle member is positive to a test) 
* 		and dynamic local containment (all Individuals in an area around an Individual tested positive have to stay home).
* 	One simulation on the same case study and with the same Random Number Generator seed  is created for each measure scenario.
* 	Activity losses are also ploted.
* 
* Parameters:
* 	- number_of_tests_: set the number of tests executed (per simulation step, i.e. per hour)
* 	- the dynamic local containment is set to 20#m (defined in the dedicated experiment)
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology, policy comparison, local policy
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	int number_of_tests_ <- 20;
}

experiment "Comparison Local" parent: "Abstract Experiment" autorun: true {

	string shape_path <- self.ask_dataset_path();
	float simulation_seed <- rnd(2000.0);

	action _init_ {
		
		/*
		 * Initialize a simulation with a no containment policy  
		 */				
 		create simulation with: [dataset_path::shape_path, seed::simulation_seed] {	
 			name <- "No containment";
 					
			ask Authority {
				policy <- create_no_containment_policy();
				create ActivitiesMonitor returns: result;
				act_monitor <- first(result);
			}
		}
	
		/*
		 * Initialize a simulation with a realistic lockdown policy (only shopping activity allowed, 10% of allowed workers, test detection)
		 */			
		create simulation with: [dataset_path::shape_path, seed::simulation_seed]  {
			float percentage_ <- 0.1;			
			
			name <- "Realistic lockdown with " + int(percentage_ * 100) + "% of essential workers and " + number_of_tests_ + " daily tests";
			allow_transmission_building <- true;
			
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, true);
				AbstractPolicy l <- create_lockdown_policy_except([act_home, act_shopping]);
				AbstractPolicy p <- create_positive_at_home_policy();
				l <- with_percentage_of_allowed_individual(l, percentage_);
				policy <- combination([d, p, l]);
				
				create ActivitiesMonitor returns: result;
				act_monitor <- first(result);
			}
		}

		/*
		 * Initialize a simulation with a family containment policy: when an Individual is tested positive, all its family has to stay home
		 */			
		create simulation  with: [dataset_path::shape_path, seed::simulation_seed] {			
			name <- "Family containment when positive member";
			allow_transmission_building <- true;
			
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, false);
				FamilyOfPositiveAtHome famP <- create_family_of_positive_at_home_policy();
				policy <- combination([d, famP]);

				create ActivitiesMonitor returns: result;
				act_monitor <- first(result);
			}

		}		

		/*
		 * Initialize a simulation with a dynamic spatial lockdown: when an Individual is tested positive, 
		 * 		all the individuals in a given radius around this individual have to stay home.
		 */		
		create simulation  with: [dataset_path::shape_path, seed::simulation_seed] {
			name <- "Dynamic spatial lockdown";
			allow_transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, false);
				AbstractPolicy lock <- create_lockdown_policy()	;
				
				create DynamicSpatialPolicy returns: spaceP {
					radius <- 20#m;
					target <- first(lock);
				}			
							
				policy <- combination([d, first(spaceP)]);
				
				create ActivitiesMonitor returns: result;
				act_monitor <- first(result);				
			}

		}							
	}
	
	permanent {		
		display "charts" parent: infected_cases {}

		// Display the activity loss for 4 kinds of Activities
		display "activities" toolbar: false background: #black refresh: every(24.0) {
			chart "Work" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 10, #bold) position: {0,0} size: {0.5,0.5} {
				loop s over: simulations {
					data s.name value: s.decrease_act_work color: s.color marker: false style: line thickness: 2;
				}
			}

	 		chart "School" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 10, #bold) position: {0.5,0} size: {0.5,0.5} {
				loop s over: simulations {
					data s.name value: s.decrease_act_study color: s.color marker: false style: line thickness: 2;
				}
			}		
			
			chart "Eating" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 10, #bold) position: {0,0.5} size: {0.5,0.5} {
				loop s over: simulations {
					data s.name value: s.decrease_act_eat color: s.color marker: false style: line thickness: 2;
				}
			}	
			
			chart "Shopping" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 10, #bold) position: {0.5,0.5} size: {0.5,0.5} {
				loop s over: simulations {
					data s.name value: s.decrease_act_shopping color: s.color marker: false style: line thickness: 2;
				}
			}	 							
		}
	}		


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;
		
		display "Main" parent: default_display {
			species SpatialPolicy {
				draw application_area empty: true color: #red;
			}
		}
	}
}
