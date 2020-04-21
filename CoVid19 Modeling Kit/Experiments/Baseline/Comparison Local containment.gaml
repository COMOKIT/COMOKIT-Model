/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
***/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"


experiment "Comparison Local" parent: "Abstract Experiment" autorun: true {

//	string dataSetPath <- "../../Datasets/Vinh Phuc/";
	string dataSetPath <- "../../Datasets/Test 1/";
	

	action _init_ {
		
/* 		create simulation with: [dataset::dataSetPath] {
			
			ask Authority {
				policy <- create_no_containment_policy();
			}
		}
		
		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 300;
			float percentage_ <- 0.1;			
			
			name <- "Realistic lockdown with " + int(percentage_ * 100) + "% of essential workers and " + number_of_tests_ + " daily tests";
			transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, true);
				AbstractPolicy l <- create_lockdown_policy_except([act_home, act_shopping]);
				AbstractPolicy p <- create_positive_at_home_policy();
				l <- with_percentage_of_allowed_individual(l, percentage_);
				policy <- combination([d, p, l]);
			}
		}
		
		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 300;
			float percentage_ <- 0.1;
			
			name <- "Family + lockdown";
			transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, true);
				AbstractPolicy l <- create_lockdown_policy_except([act_home, act_shopping]);
				create FamilyOfPositiveAtHome returns: p;
			//	AbstractPolicy p <- create_positive_at_home_policy();
				l <- with_percentage_of_allowed_individual(l, percentage_);
				policy <- combination([d, first(p), l]);
			}

		}	
		
		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 300;
			float percentage_ <- 0.1;
			
			name <- "Family only";
			transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, true);
				create FamilyOfPositiveAtHome returns: p;
			//	AbstractPolicy p <- create_positive_at_home_policy();
				policy <- combination([d, first(p)]);
			}
		}	
*/		
		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 300;
			float percentage_ <- 0.1;
			
			name <- "Family ";
			transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, true);
				create FamilyOfPositiveAtHome returns: famP;				
				policy <- combination([d, first(famP)]);
			}

		}		
		
		create simulation  with: [dataset::dataSetPath]  {
			int number_of_tests_ <- 300;
			float percentage_ <- 0.1;
			
			name <- "Family + space";
			transmission_building <- true;
			ask Authority {
				AbstractPolicy d <- create_detection_policy(number_of_tests_, false, true);
				AbstractPolicy lock <- create_lockdown_policy()	;
				
				create DynamicSpatialPolicy returns: spaceP {
					radius <- 200#m;
					target <- first(lock);
				}			
							
				policy <- combination([d, first(spaceP)]);
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