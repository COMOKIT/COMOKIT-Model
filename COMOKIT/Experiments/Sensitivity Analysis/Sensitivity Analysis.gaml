/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Arthur Brugiere <roiarthurb>
* 
* Description: 
* 	Experiments defined for a batch and headless sensitivity analysis.
* 	The objective is to explored the influence of the model stochasticity on the results (in terms of number of infected, duration...). 
* 	These simulations will stop when there is not infected Individual anymore (sim_stop() action) and a maximum simulation step is reached (cycle_limit). 
* 
* Parameters:
* 	- cycle_limit defines the maximum simulation steps. When this step is reached, the simulation stops.
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology,sensitivity,batch
******************************************************************/


model ReplicationSensitivity

import "../../Model/Global.gaml"
import "../Abstract Batch Experiment.gaml"

global {
	int cycle_limit <- 5000 const:true; 
}

experiment Sensitivity parent: "Abstract Batch" 
	type: batch repeat: 60 keep_seed: false until: world.sim_stop() or cycle>=cycle_limit {
	method exhaustive;
	
	permanent {
		
		display "charts" toolbar: false background: #black{
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
				loop s over: simulations {
					data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 	
				}
			}
		}
		
		display "Cumulative incidence" toolbar: false background: #black{
			chart "Cumulative incidence" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
				loop s over: simulations {
					data s.name value: s.total_number_of_infected color: s.color marker: false style: line thickness: 2; 
				}
			}
		}
	}
}

experiment SensitivityHeadless parent: "Abstract Headless"  {}
