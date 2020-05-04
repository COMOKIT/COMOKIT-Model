/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
***/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"


experiment "Comparison" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		create simulation with: [dataset::shape_path, seed::simulation_seed] {
			name <- "School closed";
			ask Authority {
				policy <- createPolicy(false, true);
			}

		}

		create simulation with: [dataset::shape_path, seed::simulation_seed]{
			name <- "No Containment";
			ask Authority { 
				policy <- create_no_containment_policy();
			}

		}

		create simulation with: [dataset::shape_path, seed::simulation_seed]{
			name <- "Home Containment";
			ask Authority {
				policy <- createPolicy(false, false);
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
	}


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;
		display "Main" parent: default_display {}

	}

}