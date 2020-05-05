/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi, Alexis Drogoul
* Tags: covid19,epidemiology
***/

model CoVid19

import "../Model/Global.gaml"

global {
	font default <- font("Helvetica", 18, #bold);
	rgb text_color <- world.color.brighter.brighter;
	rgb background <- world.color.darker.darker;
	int number_of_infectious <- 0 update: length(Individual where (each.is_infectious));

	init { 
		do init_epidemiological_parameters;
		do global_init;
		do create_authority;
	}

}


experiment "Abstract Experiment" virtual:true{

	string ask_dataset_path {
		int index <- -1;
		string question <- "Available datasets :\n ";
		list<string> dirs <- world.gather_dataset_names();
		loop i from: 0 to: length(dirs) - 1 {
			question <- question + (i+1) + "- " + dirs[i] + " \n ";
		}

		loop while: (index < 0) or (index > length(dirs) - 1) {
			index <- int(user_input(question, [enter("Your choice",1)])["Your choice"]) -1;
		}
		return dataset_folder + dirs[index] + "/";
	}
	
	output {
		display "default_display" synchronized: false type: opengl background: background virtual: true draw_env: false {
			
			overlay position: { 5, 5 } size: { 700 #px, 200 #px }  transparency: 1
            {
           		draw world.name  font: default at: { 20#px, 20#px} anchor: #top_left color:text_color;
           		draw ("Day " + int((current_date - starting_date) /  #day)) + " | " + ("Cases " + world.number_of_infectious)  font: default at: { 20#px, 50#px} anchor: #top_left color:text_color;
            }
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): dataset_folder+"Default/satellite.png" transparency: 0.5 refresh: false;
			
			species Building {
				draw shape color:  viral_load>0?rgb(255*viral_load,0,0):#lightgrey empty: true width: 2;
			}
			agents "Individual"  value: Individual where not (each.is_outside){
				draw square(state=susceptible or clinical_status=recovered? 10: 20) color: state = latent ? #yellow : (self.is_infectious ? #orangered : (clinical_status = recovered?#blue:#green)) ;	
			}

		}
		
		display "default_3D_display" synchronized: false type: opengl background: #black draw_env: false virtual: true {
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): dataset_folder+"Default/satellite.png" transparency: 0.5 refresh: false;
			
			species Building transparency: 0.7 refresh:false{
				draw shape depth: rnd(50) color:  #lightgrey empty: false width: 2;
			}
			agents "Other" value: Individual where (not each.is_outside and each.clinical_status = recovered or each.state=susceptible) transparency: 0.5 {
				draw sphere(30) color:  (clinical_status = recovered?#blue:#green)at: location - {0,0,30};
			}
			
			
			agents "Exposed" value: Individual where (not each.is_outside and each.clinical_status = latent) transparency: 0.5 {
				draw sphere(30) color: #yellow at: location - {0,0,30};
			}
			
			agents "Infectious" value: Individual where (not each.is_outside and each.is_infectious) transparency: 0.5 {
				draw sphere(50) color: #red at: location - {0,0,50};
			}

		}
		
		
		display "simple_display" parent: default_display synchronized: false type: opengl background: #black virtual: true draw_env: false {
			
			species Building {
				draw shape color:  #lightgrey empty: true width: 2;
			}
			agents "Individual" value:Individual where not (each.is_outside) {
				draw square(self.is_infectious ? 30:10) color: state = latent ? #yellow : (self.is_infectious ? #orangered : (clinical_status = recovered?#blue:#green));
			}
			

		}


		display "default_white_chart" virtual: true {
			chart "sir" background: #white axes: #black {
				data "susceptible" value: length(Individual where (each.state=susceptible)) color: #green marker: false style: line;
				data "latent" value: length(Individual where (each.is_latent())) color: #orange marker: false style: line;
				data "infected" value: length(Individual where (each.is_infectious)) color: #red marker: false style: line;
				data "recovered" value: length(Individual where (each.clinical_status = recovered)) color: #blue marker: false style: line;
				data "dead" value: length(Individual where (each.clinical_status = dead)) color: #black marker: false style: line;
			}

		}
		
		display "cumulative_incidence" virtual: true {
			chart "cumulative incidence" background: #white axes: #black {
				data "cumulative incidence" value: total_number_of_infected color: #red marker: false style: line;
			}

		}

	}

}