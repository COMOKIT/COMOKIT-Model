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
	int number_of_infected <- 0 update: length(Individual where (each.status = symptomatic_with_symptoms or each.status = symptomatic_without_symptoms or each.status = asymptomatic));

	init { 
		do global_init;
		do create_authority;
		create title;
	}

}

species title {
	point location <- {0,0};
}

experiment "Abstract Experiment" virtual:true{

	

	string ask_dataset_path {
		int index <- -1;
		
		
		string question <- "Available datasets : ";
		list<string> dirs <- folder("../../data").contents  ;
		dirs <- dirs where folder_exists("../../data/" + each);
		loop i from: 0 to: length(dirs) - 1 {
			question <- question + (i+1) + "- " + dirs[i] + " | ";
		}

		loop while: (index < 0) or (index > length(dirs) - 1) {
			index <- int(user_input(question, ["Your choice"::1])["Your choice"]) - 1;
		}
		return "../../data/" + dirs[index] + "/";
	}
	
	
	
	
	output {
		display "d1" synchronized: false type: opengl background: color.darker.darker virtual: true draw_env: false {
			
			overlay position: { 5, 5 } size: { 700 #px, 100 #px } background: # black transparency: 0.5 border: #black rounded: true
            {
           		draw world.name + (" - Day " + int((current_date - starting_date) /  #day)) + (" - Cases " + world.number_of_infected) font: default perspective: true at: { 20#px, 20#px} anchor: #top_left color: #white;// world.color.brighter;
			
        
           }
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): "../../data/Default/satellite.png"  refresh: false;
			
			//species Boundary {
			//	draw shape color: #yellow empty:false;	
			//}
			species River {
				draw shape color: color.darker empty:false ;
			}
			/* species Road {
				draw shape + 1 color: #red ;
			}*/
			species Building {
				draw shape color:  #lightgrey empty: true width: 2;
			}
			species Individual {
				draw square(20) color: status = exposed ? #yellow : ((status = symptomatic_without_symptoms)or(status = symptomatic_with_symptoms)or(status = asymptomatic) ? #orangered : (status = recovered?#blue:#lime));
				//draw circle(10) color: status = exposed ? #orange : (status = infected ? #red : #green);
			}
			/*species title position: {0,0.9} {
				draw world.name + (" - Day " + int((current_date - starting_date) /  #day)) + (" - Cases " + world.number_of_infected) font: default perspective: true anchor: #top_left color: #white;// world.color.brighter;
			}*/
		}

		display "chart" virtual: true {
			chart "sir" background: #white axes: #black {
				data "susceptible" value: length(Individual where (each.status=susceptible)) color: #green marker: false style: line;
				data "exposed" value: length(Individual where (each.status = exposed)) color: #orange marker: false style: line;
				data "infected" value: length(Individual where (each.status = asymptomatic or each.status=symptomatic_without_symptoms or each.status = symptomatic_with_symptoms)) color: #red marker: false style: line;
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