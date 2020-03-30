/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract Experiment.gaml"
experiment "Wearing Masks" parent: "Abstract Experiment" autorun: true {
	
	float factor <- 0.1;

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- brewer_colors("Paired");
		
		loop proportion over: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0] {
			create simulation with: [color::(colors at int(proportion*5)), factor_contact_rate_wearing_mask::factor, dataset::shape_path, seed::simulation_seed, proportion_wearing_mask::proportion] {
				name <- string(int(proportion*100)) + "% with mask";
				ask Authority {
					policies << noContainment;
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
				draw  "Mask Efficiency " + round(100 - (factor * 100)) + "%" font: default at: {100#px, 30#px}  color: #white anchor: #top_left;
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