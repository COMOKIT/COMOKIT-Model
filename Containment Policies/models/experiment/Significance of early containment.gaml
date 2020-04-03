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
		int nb_cases <- 20;
		loop nb_days over: [0,15,30,45,60] {
			create simulation with: [color::(colors at int(color_browser)), dataset::shape_path, seed::simulation_seed] {
				name <- string(nb_days) + " days of containment from " + nb_cases + " reported cases";
				ask Authority {
					AbstractPolicy d <- create_detection_policy(10,true,true);
					AbstractPolicy p <- create_lockdown_policy_with_percentage(0.1);
					p <- from_min_cases(p, nb_cases);
					p <- during(p, nb_days);
					policy <- combination([d,p]);
				}

			}
			color_browser <- color_browser+1;

		}
	}

	permanent {
		display "charts" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Infected and reported cases" background: #black axes: #black color: #white title_font: default legend_font: font("Helvetica", 12, #bold) title_visible: true {
				loop s over: simulations {
					data s.name + " (infected)" value: s.number_of_infectious color: s.color marker: false style: line	 thickness: 2;
					data s.name + " (reported)" value: s.total_number_reported color: s.color marker: true line_visible: false thickness: 1;
				}

			}
			graphics "title" {
				draw ("Day " + int((current_date - starting_date) /  #day))  font: default at: {100#px, 0} color:#white anchor: #top_left;
			}

		}
	}

	output {
		
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: false;
		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {5#px, 5#px} color:world.color anchor: #top_left;
				
			}
		}

	}

}