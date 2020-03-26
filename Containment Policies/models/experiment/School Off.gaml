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
		do create_authority;
		ask Authority {
			policies << noSchool; 
		}

	}

}

experiment "School Off" parent: "Abstract Experiment" {
	output {
		display "Main" parent: d1 {
		}

	}

}