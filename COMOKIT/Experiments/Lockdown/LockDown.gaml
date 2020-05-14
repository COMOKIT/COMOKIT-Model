/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

import "../Abstract Batch Experiment.gaml"

global {
	int num_days <- 120;

	action define_policy{  
		result_folder  <- "../../batch_output_"+num_days+ "/";
		ask Authority {
			if (num_days > 0) {
				policy <- create_lockdown_policy();
				policy <- during(policy, num_days); 
			}
		}
	}

}

experiment "Lockdown" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {}
	}

}

experiment "Comparison num days Lockdown" parent: "Abstract Batch Experiment" 
	type: batch repeat: 20 keep_seed: true until: world.sim_stop() 
{		
	parameter var:num_days among: [0, 15,30, 60,90,120];
}