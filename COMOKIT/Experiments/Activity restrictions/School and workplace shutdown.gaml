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
			list<bool> c <- world.ask_closures();
			ask world {do console_output(sample(c),"School and workplace shutdown.gaml");}
			policy <- createPolicy(not(c[1]), not(c[0])); 
		}
	}
	
	list<bool> ask_closures {
		return list<bool>(user_input("Select closure politics: ", [enter("School closure",true),enter("Workplace closure",true)]).values);
	}
		
}

experiment "School Off" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
		}
	}
}