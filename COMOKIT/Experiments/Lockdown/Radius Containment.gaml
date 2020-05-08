/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	
	list<Individual> sources <- [];

	action define_policy {
		ask Authority {
			ask 2 among Individual {
				sources << self;
				state <- symptomatic;
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