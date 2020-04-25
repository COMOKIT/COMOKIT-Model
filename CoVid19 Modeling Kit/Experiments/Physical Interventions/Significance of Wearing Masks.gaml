/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul, Damien Philippon
* Tags: covid19,epidemiology
***/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

experiment "Wearing Masks" parent: "Abstract Experiment" autorun: true {
	
	float factor <- 0.1;

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- brewer_colors("Paired");
		
		loop proportion over: [0.0,1.0] {
			create simulation with: [color::(colors at int(proportion*5)), init_all_ages_factor_contact_rate_wearing_mask::factor, dataset::shape_path, seed::simulation_seed, init_all_ages_proportion_wearing_mask::proportion, force_parameters::list(epidemiological_proportion_wearing_mask, epidemiological_factor_wearing_mask)] {
				name <- string(int(proportion*100)) + "% with mask";
				ask Authority {
					policy <- create_no_containment_policy();
				}

			}

		}
	}

	permanent {
		display "charts" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Infected cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data s.name value: s.number_of_infectious color: s.color marker: false style: line	 thickness: 2;
				}

			}
			graphics "title" {
				draw ("Day " + int((current_date - starting_date) /  #day))  font: default at: {100#px, 0} color:#white anchor: #top_left;
				draw  "Mask Efficiency " + round(factor * 100) + "%" font: default at: {100#px, 30#px}  color: #white anchor: #top_left;
			}

		}

	}

	output {
		
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: false;
		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {0, world.shape.height/2 - 30#px} color:world.color anchor: #top_left;
			}
		}

	}

}