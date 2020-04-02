/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract Experiment.gaml"
experiment "Early containment" parent: "Abstract Experiment" autorun: true {
	
	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- brewer_colors("Paired");
		int color_browser <- 0;
		loop nb_days over: [0,5,15,30,45,60] {
			create simulation with: [color::(colors at int(color_browser)), dataset::shape_path, seed::simulation_seed] {
				name <- string(nb_days) + " days of containment";
				ask Authority {
					policy <- combination([create_detection_policy(1,true,true), createConditionalContainmentPolicy(nb_days,1)]);
				}

			}
			color_browser <- color_browser+1;

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
			}

		}
		display "Cumulative incidence" {
			chart "Cumulative incidence" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.total_number_of_infected color: s.color marker: false style: line thickness: 2; 
				
			}}
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