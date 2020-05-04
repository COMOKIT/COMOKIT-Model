/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi
* Tags: covid19,epidemiology
***/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {

	action define_policy{  
		ask Authority {
			policy <- create_lockdown_policy();
		}
	}

}

experiment "Lock Down" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {}
	}

}