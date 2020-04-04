/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"

global {
	font default <- font("Helvetica", 18, #bold);
	rgb text_color <- world.color.brighter.brighter;
	rgb background <- world.color.darker.darker;
	int number_of_infectious <- 0 update: length(Individual where (each.is_infectious()));

	init { 
		do init_epidemiological_parameters;
		do global_init;
		do create_authority;
	}

}


experiment "Abstract Experiment" virtual:true{

	

	string ask_dataset_path {
		int index <- -1;
		string question <- "Available datasets : ";
		list<string> dirs <- self.gather_dataset_names();
		loop i from: 0 to: length(dirs) - 1 {
			question <- question + (i+1) + "- " + dirs[i] + " | ";
		}

		loop while: (index < 0) or (index > length(dirs) - 1) {
			index <- int(user_input(question, ["Your choice"::1])["Your choice"]) - 1;
		}
		return "../../data/" + dirs[index] + "/";
	}
	
	
	list<string> gather_dataset_names {
		list<string> dirs <- folder("../../data").contents  ;
		dirs <- dirs where folder_exists("../../data/" + each);
		return dirs;
	}
	
	
	
	
	output {
		display "default_display" synchronized: false type: opengl background: background virtual: true draw_env: false {
			
			overlay position: { 5, 5 } size: { 700 #px, 200 #px }  transparency: 0 
            {
           		draw world.name  font: default at: { 20#px, 20#px} anchor: #top_left color:text_color;
           		draw ("Day " + int((current_date - starting_date) /  #day)) + " | " + ("Cases " + world.number_of_infectious)  font: default at: { 20#px, 50#px} anchor: #top_left color:text_color;
            }
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): "../../data/Default/satellite.png" transparency: 0.5 refresh: false;
			
			species Building {
				draw shape color:  viral_load>0?rgb(255*viral_load,0,0):#lightgrey empty: true width: 2;
			}
			agents "Individual"  value: Individual where not (each.is_outside){
				draw square(status=susceptible or status=recovered? 10: 20) color: status = exposed ? #yellow : (self.is_infectious() ? #orangered : (status = recovered?#blue:#green)) ;	
			}

		}
		
		display "default_3D_display" synchronized: false type: opengl background: #black draw_env: false virtual: true {
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): "../../data/Default/satellite.png" transparency: 0.5 refresh: false;
			
			species Building transparency: 0.7 refresh:false{
				draw shape depth: rnd(50) color:  #lightgrey empty: false width: 2;
			}
			agents "Other" value: Individual where (not each.is_outside and each.status = recovered or each.status=susceptible) transparency: 0.5 {
				draw sphere(30) color:  (status = recovered?#blue:#green)at: location - {0,0,30};
			}
			
			
			agents "Exposed" value: Individual where (not each.is_outside and each.status = exposed) transparency: 0.5 {
				draw sphere(30) color: #yellow at: location - {0,0,30};
			}
			
			agents "Infectious" value: Individual where (not each.is_outside and each.is_infectious()) transparency: 0.5 {
				draw sphere(50) color: #red at: location - {0,0,50};
			}

		}
		
		
		display "simple_display" parent: default_display synchronized: false type: opengl background: #black virtual: true draw_env: false {
			
			species Building {
				draw shape color:  #lightgrey empty: true width: 2;
			}
			agents "Individual" value:Individual where not (each.is_outside) {
				draw square(self.is_infectious() ? 30:10) color: status = exposed ? #yellow : (self.is_infectious() ? #orangered : (status = recovered?#blue:#green));
			}
			

		}


		display "default_white_chart" virtual: true {
			chart "sir" background: #white axes: #black {
				data "susceptible" value: length(Individual where (each.status=susceptible)) color: #green marker: false style: line;
				data "exposed" value: length(Individual where (each.is_exposed())) color: #orange marker: false style: line;
				data "infected" value: length(Individual where (each.is_infectious())) color: #red marker: false style: line;
				data "recovered" value: length(Individual where (each.status = recovered)) color: #blue marker: false style: line;
				data "dead" value: length(Individual where (each.status = dead)) color: #black marker: false style: line;
			}

		}
		
		display "cumulative_incidence" virtual: true {
			chart "cumulative incidence" background: #white axes: #black {
				data "cumulative incidence" value: total_number_of_infected color: #red marker: false style: line;
			}

		}

	}

}