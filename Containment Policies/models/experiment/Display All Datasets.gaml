/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract Experiment.gaml"




experiment "Datasets" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		list<string> dirs <- self.gather_dataset_names();

		float simulation_seed <- rnd(2000.0);
		loop s over:  dirs {
		create simulation with: [dataset::"../../data/" + s + "/", seed::simulation_seed] {
			name <- s;
			ask Authority {
				policy <- create_no_containment_policy();
			}

		}}

	}


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;


		display name synchronized: false type: opengl background: #black draw_env: false parent: default_3D_display {

			graphics "Simulation Name" {
				draw world.name  font: default at: {0, world.shape.height/2 - 30#px} color: text_color anchor: #top_left;
			}
			graphics "Day and Cases" {
				draw ("Day " + int((current_date - starting_date) /  #day)) + " | " + ("Cases " + world.number_of_infectious)  font: default at: {0, world.shape.height/2 - 50#px}  color: text_color anchor: #top_left;
			}

		}
	}

}