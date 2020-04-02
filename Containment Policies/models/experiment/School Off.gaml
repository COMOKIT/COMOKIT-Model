/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract Experiment.gaml"

global {

	action define_policy{  
			ask Authority {
			policy <- createPolicy(false, true); 
		}

	}

}

experiment "School Off" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
		}

	}

}