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
			policy <- createTotalLockDownPolicy();
		}
	}
}

experiment "No Containment" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
		}
		display "Chart" parent: default_white_chart {
		}
		display "Cumulative incidence" parent: cumulative_incidence {
		}
	}

}