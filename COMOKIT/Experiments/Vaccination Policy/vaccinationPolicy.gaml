/**
* Name: vaccinationPolicy
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags: 
*/


model vaccinationPolicy

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	
	bool DEBUG <- false;
	int num_infected_init <- 20; 
	
	map<string,int> vaxxins <- [pfizer_biontech::2000,astra_zeneca::5000];
	map<string,int> vax_a_day <- [pfizer_biontech::20,astra_zeneca::50];
	map<string,point> vax_age_target <- [pfizer_biontech::point(18,45),astra_zeneca::point(46,120)];
	
	map<covax,date> vax_start;
	map<covax,int> vax_day_duration;
	
	action define_policy{
		ask Authority {
			name <- "Vaccination strategy";
			list<AbstractPolicy> policies;
			loop v over:vaxxins.keys {
				policies <+ create_vax_policy(vaccines first_with (each.name=v),vaxxins[v],vax_a_day[v],vax_age_target[v],true);
			}
			policy <- combination(policies);
		}
	}
	
	map<point,float> fd <- [point(18,34)::0.0,point(35,55)::0.0,point(56,65)::0.0,point(66,120)::0.0];
	map<point,float> sd <- [point(18,34)::0.0,point(35,55)::0.0,point(56,65)::0.0,point(66,120)::0.0];
	reflex compute_age_group_vax {
		loop ag over:[point(18,34),point(35,55),point(56,65),point(66,120)] {
			list<Individual> age_group <- all_individuals where (ag.x <= each.age and each.age <= ag.y ) ;
			fd[ag] <- age_group count (length(each.vaccine_history)=1) / length(age_group);
			sd[ag] <- age_group count (length(each.vaccine_history)=2) / length(age_group);
		}
	}
		
}


experiment "Vaccination campaign" parent: "Abstract Experiment" autorun: false {
	output {
		layout #split consoles: true editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
		display "States evolution" parent:states_evolution_chart {}
		
		/* 
		display "vaccination doses" refresh: every(24#cycle) {
			chart "Vaccinated population" background: #white axes: #black color: #black title_font: default legend_font: font("Helvetica", 14, #bold) {
				data "Nb individual with 1 dose" value: total_number_doses[0] marker: false style: line  legend: "1 dose";
				data "Nb individual with 2 doses" value: total_number_doses[1] marker: false style: line  legend: "2 doses";
			}
		}
		* 
		*/
		
		display "1 vax proportion" refresh:every(#day) {
			chart "First dose according to age" type:histogram 
				series_label_position: onchart
				label_font: font('Arial', 18, #bold) 
				x_serie_labels: ""
				x_label:"Age groups"
			{
				loop p over:fd.keys sort (each.x) {
					data legend:"["+p.x+" - "+p.y+"] = "+all_individuals count (p.x <= each.age and each.age <= p.y) value:with_precision(fd[p]*100,2) color:#green;
				}
			}
		}
		
		display "full vax proportion" refresh:every(#day) {
			chart "Second doses according to age" type:histogram 
				series_label_position: onchart
				label_font: font('Arial', 18, #bold)
				x_serie_labels: ""
				x_label:"Age groups"
			{
				loop p over:sd.keys sort (each.x) {
					data legend:"["+p.x+" - "+p.y+"] = "+all_individuals count (p.x <= each.age and each.age <= p.y) value:with_precision(sd[p]*100,2) color:#green;
				}
			}
		}
		
		display "vax doses" refresh: every(#day) {
			chart "Vax doses" background: #white axes: #black color: #black title_font: default legend_font: font("Helvetica", 14, #bold) {
				data "Nb of "+pfizer_biontech+" doses" value: total_number_doses_per_vax[vaccines first_with (each.name=pfizer_biontech)] marker: false style: line  legend: pfizer_biontech;
				data "Nb of "+astra_zeneca+" doses" value: total_number_doses_per_vax[vaccines first_with (each.name=astra_zeneca)] marker: false style: line  legend: astra_zeneca;
			}
		}
		
	}
}

