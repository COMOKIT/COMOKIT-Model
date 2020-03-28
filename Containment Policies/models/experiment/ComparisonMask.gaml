/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract.gaml"




experiment "Comparison" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		create simulation with: [dataset::shape_path,seed::1202.02,proportion_wearing_mask::0.0]{
			name <- "No Mask";
			ask Authority { 
				policies << noContainment;
			}

		}

		create simulation with: [dataset::shape_path,seed::1202.02,proportion_wearing_mask::0.90]{
			name <- "With Mask";
			ask Authority {
				policies << noContainment;
			}

		}

	}
	
	permanent {
		
		display "charts" toolbar: false background: #black{
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) size:{1.0,0.5} position:{0.0,0.0}  {
			loop s over: simulations {
				data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 
				
			}}
			
			chart "Cumulative Incidence" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) size:{1.0,0.5} position:{0.0,0.5} {
			loop s over: simulations {
				data s.name value: s.total_number_of_infected color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
		display "chartsReported" toolbar: false background: #black{
			chart "Reported cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.total_number_reported color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
	}


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;
		display "Main" parent: d1 {}

	}

}