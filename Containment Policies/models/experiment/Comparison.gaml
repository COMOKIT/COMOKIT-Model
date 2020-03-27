/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract.gaml"




experiment "Comparison" parent: "Abstract Experiment" {

	file grid_data <- image_file('../data/Vinh Phuc/satellite_modified.tif') ;
	action _init_ {
		string shape_path <- self.ask_dataset_path();
		create simulation with: [dataset::shape_path] {
			name <- "School closed";
			ask Authority {
				policies << noSchool;
			}

		}
//
//		create simulation with: [dataset::shape_path]{
//			name <- "No Containment";
//			ask Authority { 
//				policies << noContainment;
//			}
//
//		}
//
//		create simulation with: [dataset::shape_path]{
//			name <- "Home Containment";
//			ask Authority {
//				policies << lockDown;
//			}
//
//		}

	}
	
	permanent {
		
		display "charts" toolbar: false background: #black{
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.number_of_infected color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
	}


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;
		display "Main" {
			image grid_data;
		}

	}

}