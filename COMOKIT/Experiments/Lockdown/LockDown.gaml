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

	action define_policy{  
		ask Authority {
			policy <- create_lockdown_policy();
		}
	}

}

experiment "Lockdown" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {}
	}

}