/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract.gaml"


global {

	init { 
		do global_init;
		do create_authority;
		create title;
	}

}

species title {
	point location <- {0,0};
	aspect default {
		draw world.name font: font("Helvetica", 36, #bold) perspective: true anchor: #top_left;
	}
}

experiment "Comparison" parent: "Abstract Experiment" {

	init {
		ask simulation {
			name <- "School closed";
			ask Authority {
				policies << noSchool;
			}

		}

		create simulation {
			name <- "No Containment";
			ask Authority {
				policies << noContainment;
			}

		}

		create simulation {
			name <- "Full Containment";
			ask Authority {
				policies << lockDown;
			}

		}

	}


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false;
		display "Main" parent: d1 {
			species title position: {0.1,0.8};

		}

	}

}