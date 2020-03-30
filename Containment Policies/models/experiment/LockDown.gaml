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

	init {  
		ask Authority {
			policies << lockDown;
		}

	}

}

experiment "Lock Down" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {}
	}

}