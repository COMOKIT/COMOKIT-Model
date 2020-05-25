/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"


experiment "Comparison" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		
		create simulation with: [dataset_path::shape_path, seed::simulation_seed] {
			name <- "School closed";
			ask Authority {
				policy <- create_school_work_closure_policy(false, true);
			}
		}

		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{
			name <- "No Containment";
			ask Authority { 
				policy <- create_no_containment_policy();
			}
		}

		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{
			name <- "Home Containment";
			ask Authority {
				policy <- create_school_work_closure_policy(false, false);
			}
		}
		
	}
	
	permanent {
		display "charts" parent: infected_cases {}
	}

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;
		display "Main" parent: default_display {}
	}
}