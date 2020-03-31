/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "../species/Policy.gaml"
import "Abstract Experiment.gaml"

global {

	action define_policy{  
		ask Authority {
			loop i over: Individual where (each.status=asymptomatic or each.status=symptomatic_without_symptoms or each.status=symptomatic_with_symptoms){				
				policies << createQuarantinePolicyAtRadius(i.location, 200#m);
			}
		}

	}

}

experiment "Radius Quarantine" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
		}

	}

}