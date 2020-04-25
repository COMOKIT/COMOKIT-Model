/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Benoit Gaudou
* Tags: covid19,epidemiology
***/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"


experiment "Comparison Local" parent: "Abstract Experiment" autorun: true {

	string dataSetPath <- "../../Datasets/Vinh Phuc/";
//	string dataSetPath <- "../../Datasets/Test 1/";

	action _init_ {
		
 		create simulation with: [dataset::dataSetPath] {	
 			name <- "No containment";
 					
			ask Authority {
				policy <- create_no_containment_policy();
				create ActivitiesMonitor returns: result;
				act_monitor <- first(result);
			}
		}
		
		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 20;
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

		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 20;
			
			name <- "Family ";
			allow_transmission_building <- true;
			
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, false);
				FamilyOfPositiveAtHome famP <- create_family_of_positive_at_home_policy();
				policy <- combination([d, famP]);

				create ActivitiesMonitor returns: result;
				act_monitor <- first(result);
			}

		}		
		
		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 20;
			
			name <- "Dynamic spacial lockdown";
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
		
		display "charts" toolbar: false background: #black{
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
				loop s over: simulations {
					data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 
					
				}
			}
		}

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
		layout #split ;//consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;
		display "Main" parent: default_display {
			species SpatialPolicy {
				draw application_area empty: true color: #red;
			}
		}

	}

}