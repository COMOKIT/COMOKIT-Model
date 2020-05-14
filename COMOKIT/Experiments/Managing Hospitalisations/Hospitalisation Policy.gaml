/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

experiment "Opening Hospitals" parent: "Abstract Experiment" autorun: true {
	
	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- [#blue, #cyan, #green, #red];
		
		create simulation with: [color::(colors at 0),dataset_path::shape_path, seed::simulation_seed] {
			name <- "No Hospitalisation";
			ask Authority {
				policy <- create_no_containment_policy();
			}
		}
		create simulation with: [color::(colors at 1),dataset_path::shape_path, seed::simulation_seed] {
			name <- "Only ICU hospitalisation";
			ask Authority {
				policy <- create_hospitalisation_policy(true, false,2);
			}
		}
		create simulation with: [color::(colors at 2),dataset_path::shape_path, seed::simulation_seed] {
			name <- "ICU and Hospitalisation";
			ask Authority {
				policy <- create_hospitalisation_policy(true, true,2);
			}
		}
		create simulation with: [color::(colors at 3),dataset_path::shape_path, seed::simulation_seed] {
			name <- "ICU and Hospitalisation for 5 tests";
			ask Authority {
				policy <- create_hospitalisation_policy(true, true,5);
			}
		}
	}

	permanent {
		display "charts Infected" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Infected cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data s.name value: s.number_of_infectious color: s.color marker: false style: line	 thickness: 2;
				}
			}
		}
		
		display "charts Hospitalized" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Hospitalized cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data s.name value: length(s.Individual where(each.is_hospitalised)) color: s.color marker: false style: line	 thickness: 2;
				}
			}
		}
		display "charts ICU" toolbar: false background: #black  {
			chart "ICU cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data s.name value: length(s.Individual where(each.is_ICU)) color: s.color marker: false style: line	 thickness: 2;
				}
			}
		}
		display "charts Deaths" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Dead cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data s.name value: length(s.Individual where(each.clinical_status=dead)) color: s.color marker: false style: line	 thickness: 2;
				}
			}
		}
	}
	
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {5 #px, 5 #px} color: world.color anchor: #top_left;
			}

		}

	}
}