/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi
* Tags: covid19,epidemiology
***/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
 
	action define_policy{   
		ask Authority {
				policy <- create_hospitalisation_policy(true, true,2);
		}
	}
}

experiment "No Containment" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
		}
		display "Chart" parent: default_white_chart {
		}
		display "Cumulative incidence" parent: cumulative_incidence {
		}
		display "Precise chart" {
			chart "Precise" background: #white axes: #black {
				data "susceptible" value: length(Individual where (each.state=susceptible)) color: #green marker: false style: line;
				data "latent" value: length(Individual where (each.is_latent())) color: #orange marker: false style: line;
				data "presymptomatic" value: length(Individual where (each.state=presymptomatic)) color: #purple marker: false style: line;
				data "symptomatic" value: length(Individual where (each.state=symptomatic)) color: #red marker: false style: line;
				data "asymptomatic" value: length(Individual where (each.state=asymptomatic)) color: #darkred marker: false style: line;
				data "recovered" value: length(Individual where (each.clinical_status = recovered)) color: #blue marker: false style: line;
				data "dead" value: length(Individual where (each.clinical_status = dead)) color: #black marker: false style: line;
			}
		}
		display "Clinical chart" {
			chart "Clinical" background: #white axes: #black {
				data no_need_hospitalisation value: length(Individual where (each.clinical_status=no_need_hospitalisation)) color: #green marker: false style: line;
				data need_hospitalisation value: length(Individual where (each.clinical_status=need_hospitalisation)) color: #orange marker: false style: line;
				data need_ICU value: length(Individual where (each.clinical_status=need_ICU)) color: #red marker: false style: line;
				data recovered value: length(Individual where (each.clinical_status=recovered)) color: #blue marker: false style: line;
				data dead value: length(Individual where (each.clinical_status=dead)) color: #black marker: false style: line;
			}
		}
		display "Hospital chart" {
			chart "Hospital" background: #white axes: #black {
				data "Hospitalised" value: length(Individual where (each.is_hospitalised)) color: #green marker: false style: line;
				data "ICU" value: length(Individual where (each.is_ICU)) color: #red marker: false style: line;
			}
		}
	}

}