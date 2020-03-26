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

	// Create an authority 
		write "Create an authority ";
		create Authority;
		write "ask auth";
		ask Authority {
			policies << createLockDownPolicy();
		}

	}

}

experiment "Lock Down" parent: "Abstract Experiment" {
	output {
		display "Main" parent: d1 {
		}

	}

}