/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "../species/Policy.gaml"
import "Abstract.gaml"

global {

	init {  
		do global_init;
		do create_authority;
		ask Authority {
			policies << lockDown;
		}

	}

}

experiment "Lock Down" parent: "Abstract Experiment" {
	output {
		display "Main" parent: d1 {
		}

	}

}