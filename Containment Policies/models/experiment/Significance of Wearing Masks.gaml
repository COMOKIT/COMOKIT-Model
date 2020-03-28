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

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- brewer_colors("Paired");
		
		loop proportion over: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0] {
			create simulation with: [color::(colors at int(proportion*5)), factor_contact_rate_wearing_mask::0.3, dataset::shape_path, seed::simulation_seed, proportion_wearing_mask::proportion] {
				name <- string(int(proportion*100)) + "% with mask";
				ask Authority {
					policies << noContainment;
				}

			}

		}
	}

	permanent {
		display "charts" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Infected cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 14, #bold) title_visible: false {
				loop s over: simulations {
					data s.name value: s.number_of_infectious color: s.color marker: false style: line	 thickness: 2;
				}

			}

		}

	}

	output {
				
		display "d2" synchronized: false type: opengl background: #black virtual: true draw_env: false camera_pos: {1279.4829,1684.2932,3227.1738} camera_look_pos: {1279.4829,1684.2369,0.0084} camera_up_vector: {0.0,1.0,0.0} {
			
			species Building {
				draw shape color:  #lightgrey empty: true width: 2;
			}
			species Individual {
				draw square(self.is_infectious() ? 30:10) color: status = exposed ? #yellow : (self.is_infectious() ? #orangered : (status = recovered?#blue:#green));
			}
			species title {
				draw world.name  font: default at: {0, world.shape.height/2 - 30#px} color:world.color anchor: #top_left;
			}
			agents "Title" value: title{
				draw ("Day " + int((current_date - starting_date) /  #day)) + " | " + ("Cases " + world.number_of_infectious)  font: default at: {0, world.shape.height/2 - 50#px}  color: world.color anchor: #top_left;
			}

		}
		
		
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: false;
		display "Main" parent: d2 {
		}

	}

}