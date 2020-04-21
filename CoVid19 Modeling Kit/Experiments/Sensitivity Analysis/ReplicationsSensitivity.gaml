/***
* Name: Sensitivity
* Author: Arthur Brugiere <roiarthurb>
* Description: Batch file extracting raw data to post-process them
* and analyze sensitivity in our model
* 
* Tags: Batch, sensitivity, extract data
***/

model ReplicationSensitivity

import "../../Model/Global.gaml"
import "../Abstract Batch Experiment.gaml"

global {
	/** Insert the global definitions, variables and actions here */
}

experiment Sensitivity parent: "Abstract Batch Experiment" 
	type: batch repeat: 500 keep_seed: false until: ((Individual count each.is_infected = 0) and had_infected_Individual) or world.sim_stop() 
{
	method exhaustive;
	
	permanent {
		
		display "charts" toolbar: false background: #black{
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
		
		display "Cumulative incidence" toolbar: false background: #black{
			chart "Cumulative incidence" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
			loop s over: simulations {
				data s.name value: s.total_number_of_infected color: s.color marker: false style: line thickness: 2; 
				
			}}
		}
	}

}

experiment SensitivityHeadless parent: "Abstract Batch Headless" 
{}