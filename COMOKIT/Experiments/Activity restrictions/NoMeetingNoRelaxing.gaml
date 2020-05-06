/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi
* Tags: covid19,epidemiology
***/


model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

/*
 * Initialize a policy based on activity restrictions: working, studying and leisure (including go to eat or making sport outside) 
 */
global { 

	action define_policy{   
		ask Authority {
			policy <- create_no_meeting_policy();
		}

	}

}

experiment "No Meeting No Relaxing" parent: "Abstract Experiment" {
	
	output {
		display "Main" parent: default_display {
		}

	}

}