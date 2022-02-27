/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* 
* Description: 
* 	Model with a total lockdown policy applied during a given number of days.
* 	In a total lockdown, no activities are allowed, and this is applied to all the Individuals.
* 	After this lockdown period, no policy is applied.
* 
* Parameters:
* 	- numb_days: defines the number of days for the lockdown application.
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology,lockdown
******************************************************************/

model CoVid19

import "Abstract Experiments.gaml"

global {
	action define_policy{  
		ask Authority {
			list<bool> c <- world.ask_closures();
			ask world {do console_output(sample(c),"School and workplace shutdown.gaml");}
			policy <- create_school_work_allowance_policy(not(c[0]), not(c[1])); 
		}
	}
	
	list<bool> ask_closures {
		map res <- user_input_dialog("Select closure politics: ", [enter("School closure",true),enter("Workplace closure",true)]);
		return list<bool>(res["School closure"],res["Workplace closure"]);
	}

}

experiment "School and Workplace closure" parent: abstract_experiment {
	action _init_ {
		create simulation with:(macro_model:true, shp_boundary_path: dataset + "/generated/boundary.shp", csv_boundary_path: dataset + "/generated/boundary.csv" );
	}
}