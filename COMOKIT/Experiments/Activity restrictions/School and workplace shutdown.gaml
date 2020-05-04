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
			list<bool> c <- world.ask_closures();
			write c;
			policy <- createPolicy(not(c[0]), not(c[1])); 
		}
	}
	
	list<bool> ask_closures {
		return list<bool>(user_input("Select closure politics: ", ["School closure"::true,"Workplace closure"::true]).values);
	}
		
}

experiment "School Off" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
		}
	}
}