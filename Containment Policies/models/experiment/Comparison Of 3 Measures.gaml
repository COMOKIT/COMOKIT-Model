/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract Experiment.gaml"
import "../species/Policy.gaml"




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
				policy <- createNoContainmentPolicy();
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