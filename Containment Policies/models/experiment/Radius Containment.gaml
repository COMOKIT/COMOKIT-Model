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
	list<Individual> sources <- [];

	action define_policy {
		ask Authority {
			ask 2 among Individual {
				sources << self;
				status <- symptomatic_with_symptoms;
			}

			list<AbstractPolicy> policies <- [];
			loop i over: sources {
				policies << create_lockdown_policy_in_radius(i.location, 200 #m);
			}

			policy <- combination(policies);
		}

	}

}

experiment "Radius Quarantine" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
			agents "Sources" value: sources transparency: 0.7{
				draw circle(200 #m) empty: false color: #red;
			}
		}

	}

}