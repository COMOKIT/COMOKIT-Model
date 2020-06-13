/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* 
* Description: 
* 	Model illustrating the hospitalisation policy (without any other intervention policy).
* 	It defines several more precise charts to monitor the evolution of all_individualss clinical states and the number of all_individualss in hospitals. 
* 
* Parameters:
* 	The hospitalization policy accepts 3 parameters: create_hospitalisation_policy(is_allowing_ICU, is_allowing_hospitalisation, nb_minimum_tests):
* 	- is_allowing_ICU (boolean): whether hospitals allow ICU admission (set to true),
*	- is_allowing_hospitalisation: whether hospitals allow hospitalisation (set to true),
*	- nb_minimum_tests: the m inimum number of tests needed to be negative and to discharge an all_individuals (set to 2).
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology
******************************************************************/
model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	
	action define_policy{   
		ask Authority {
			policy <- create_hospitalisation_policy(true, true, 2);
		}
	}
}

experiment "No Containment" parent: "Abstract Experiment" autorun: true {

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
		display "Chart" parent: states_evolution_chart {}
		display "Cumulative incidence" parent: cumulative_incidence {}
		
		display "Precise chart" {
			chart "Precise" background: #white axes: #black {
				data "susceptible" value: length(all_individuals where (each.state=susceptible)) color: #green marker: false style: line;
				data "latent" value: length(all_individuals where (each.is_latent())) color: #orange marker: false style: line;
				data "presymptomatic" value: length(all_individuals where (each.state=presymptomatic)) color: #purple marker: false style: line;
				data "symptomatic" value: length(all_individuals where (each.state=symptomatic)) color: #red marker: false style: line;
				data "asymptomatic" value: length(all_individuals where (each.state=asymptomatic)) color: #darkred marker: false style: line;
				data "recovered" value: length(all_individuals where (each.clinical_status = recovered)) color: #blue marker: false style: line;
				data "dead" value: length(all_individuals where (each.clinical_status = dead)) color: #black marker: false style: line;
			}
		}
		
		display "Clinical chart" {
			chart "Clinical" background: #white axes: #black {
				data no_need_hospitalisation value: length(all_individuals where (each.clinical_status=no_need_hospitalisation)) color: #green marker: false style: line;
				data need_hospitalisation value: length(all_individuals where (each.clinical_status=need_hospitalisation)) color: #orange marker: false style: line;
				data need_ICU value: length(all_individuals where (each.clinical_status=need_ICU)) color: #red marker: false style: line;
				data recovered value: length(all_individuals where (each.clinical_status=recovered)) color: #blue marker: false style: line;
				data dead value: length(all_individuals where (each.clinical_status=dead)) color: #black marker: false style: line;
			}
		}
		
		display "Hospital chart" {
			chart "Hospital" background: #white axes: #black {
				data "Hospitalised" value: length(all_individuals where (each.is_hospitalised)) color: #green marker: false style: line;
				data "ICU" value: length(all_individuals where (each.is_ICU)) color: #red marker: false style: line;
			}
		}
	}
}
