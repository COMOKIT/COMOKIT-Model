/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
***/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

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
				policy <- with_tolerance(create_lockdown_policy(),tolerance);
			}

		}

	}

	output {
		display "Main" parent: default_display {
		}
		display "Chart" parent: default_white_chart {
		}
		display "Cumulative incidence" parent: cumulative_incidence {
		}
	}

}