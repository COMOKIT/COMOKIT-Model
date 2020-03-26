/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "../species/Politics.gaml"
import "Abstract.gaml"

global {

	init {
		create Politics {
			Gov_policy <- self;
			authorsisation[schooling] <- false;
		}

	}

}

experiment "School_Off" parent: "Abstract Experiment" {
	output {
		display "Main" parent: d1 {
		}
	}
}