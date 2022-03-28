/**
* Name: BaseExperiment
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

model NoPolicy 
 
import "Abstract Experiment.gaml"

global {
  action define_policy{   
		ask Authority {
			name <- "No containment policy";
			policy <- create_no_containment_policy();
		}
	}	
}
 
experiment "No Containment" parent: abstract_experiment autorun: true  {
	string name_sim <- "No Containment";
	
	action _init_ {
		do create_simulation;
	}
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" parent: map {}
		display "Plot" parent: states_evolution_chart {}	
	}
}