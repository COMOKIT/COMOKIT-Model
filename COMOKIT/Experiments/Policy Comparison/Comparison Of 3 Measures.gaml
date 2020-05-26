/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	Model comparing 3 measures: no containment, school closed and home containement (workplaces and schools are closed).
* 	One simulation on the same case study and with the same Random Number Generator seed  is created for each measure scenario.
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology,policy comparison
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"


experiment "Comparison" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);

		/*
		 * Initialize a simulation with a school closed policy  
		 */		
		create simulation with: [dataset_path::shape_path, seed::simulation_seed] {
			name <- "School closed";
			ask Authority {
				policy <- create_school_work_allowance_policy(false, true);
			}
		}

		/*
		 * Initialize a simulation with a no containment policy  
		 */		
		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{
			name <- "No Containment";
			ask Authority { 
				policy <- create_no_containment_policy();
			}
		}

		/*
		 * Initialize a simulation with a policy closing schools and workplaces  
		 */	
		create simulation with: [dataset_path::shape_path, seed::simulation_seed]{
			name <- "Home Containment";
			ask Authority {
				policy <- create_school_work_allowance_policy(false, false);
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