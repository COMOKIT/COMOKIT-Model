/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi
* 
* Description: 
* 	Model illustrating school and workplace closure policy:
* 	- school closure prevents children to go to school/university (instead they stay home)
* 	- workplace closure prevents adults with an employment to go to work (instead they stay home)
* 
* Parameters: 
* 	The model asks the user whether it wants to activate the school closure and whether it wants to activate the workplace closure.
* 	Default values are true to activate both closure policies.
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {

	/*
	 * Initialize a policy based on activity restrictions: working, studying, depending on the user choise
	 */
	action define_policy{  
		ask Authority {
			list<bool> c <- world.ask_closures();
			ask world {do console_output(sample(c),"School and workplace shutdown.gaml");}
			policy <- create_school_work_allowance_policy(not(c[0]), not(c[1])); 
		}
	}
	
	list<bool> ask_closures {
		map res <- user_input("Select closure politics: ", [enter("School closure",true),enter("Workplace closure",true)]);
		return list<bool>(res["School closure"],res["Workplace closure"]);
	}
		
}

experiment "Closures" parent: "Abstract Experiment" autorun: true {
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: default_display {}
		display "Plot" parent: states_evolution_chart {}				
	}
}