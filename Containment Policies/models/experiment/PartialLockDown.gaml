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
experiment "Partial Lock Down" parent: "Abstract Experiment" {
	
	float ask_tolerance {
		float t <- -1.0;
		loop while: (t > 1) or (t < 0) {
			t <- float(user_input("Tolerance with respect to activites (betwee, 0.0: no tolerance, and 1.0: no constraint) ", ["Your choice"::0.1])["Your choice"]);
		}
		return t;
	}

	action _init_ {
		float tolerance <- ask_tolerance();
		create simulation {
			name <- "Partial lockdown with " + int(tolerance * 100) + "% of tolerance";
			ask Authority {
				policies << createLockDownPolicyWithToleranceOf(tolerance);
			}

		}

	}

	output {
		display "Main" parent: d1 {
		}

	}

}