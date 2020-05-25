/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

experiment "Comparison of tolerance levels" parent: "Abstract Experiment" autorun: true {
	
	float factor <- 0.1;

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- brewer_colors("Paired");
		
		loop tolerance over: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0] {
			create simulation with: [color::(colors at int(tolerance*5)), dataset_path::shape_path, seed::simulation_seed] {
				name <- string(int(tolerance*100)) + "% of tolerance";
				ask Authority {
					policy <- with_tolerance(create_lockdown_policy(), tolerance);
				}

			}

		}
	}

	permanent {
		display "charts" parent: infected_cases refresh: every(24 #cycle) {
			graphics "title" {
				draw ("Day " + int((current_date - starting_date) /  #day))  font: default at: {100#px, 0} color:#white anchor: #top_left;
			}			
		}
	}

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		display "Main" parent: simple_display {
			graphics title {
				draw world.name  font: default at: {0, world.shape.height/2 - 30#px} color:world.color anchor: #top_left;
			}
		}

	}

}