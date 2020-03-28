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
				policies << noContainment;
			}

		}}

	}
	
	permanent {
		
//		display "charts" toolbar: false background: #black refresh: every(24 #cycle){
//			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
//			loop s over: simulations {
//				data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 
//				
//			}}
//		}
	}


	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;


		display name synchronized: false type: opengl background: #black draw_env: false  {
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): "../../data/Default/satellite.png" transparency: 0.5 refresh: false;
			
			species Building transparency: 0.7 refresh:false{
				draw shape depth: rnd(50) color:  #lightgrey empty: false width: 2;
			}
			agents "Other" value: Individual where (each.status = recovered or each.status=susceptible) transparency: 0.5 {
				draw sphere(30) color:  (status = recovered?#blue:#green)at: location - {0,0,30};
			}
			
			
			agents "Exposed" value: Individual where (each.status = exposed) transparency: 0.5 {
				draw sphere(30) color: #yellow at: location - {0,0,30};
			}
			
			agents "Infectious" value: Individual where (each.is_infectious()) transparency: 0.5 {
				draw sphere(50) color: #red at: location - {0,0,50};
			}
			species title {
				draw world.name  font: default at: {0, world.shape.height/2 - 30#px} color:world.color.brighter.brighter anchor: #top_left;
			}
			agents "Title" value: title{
				draw ("Day " + int((current_date - starting_date) /  #day)) + " | " + ("Cases " + world.number_of_infectious)  font: default at: {0, world.shape.height/2 - 50#px}  color: world.color.brighter.brighter anchor: #top_left;
			}

		}
	}

}