/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* Tags: covid19,epidemiology
******************************************************************/


model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

/*
 * Initialize a policy based on activity restrictions: working, studying and leisure (including having dinner or making sport outside) 
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