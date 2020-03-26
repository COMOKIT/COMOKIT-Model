/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "Abstract.gaml"

global {

	init {
	// Create an authority 
		write "Create an authority ";
		create Authority;
		ask Authority {
			policies << createPolicy(false, true);
		}

	}

}

experiment "School_Off" parent: "Abstract Experiment" {
	output {
		display "Main" parent: d1 {
		}

	}

}