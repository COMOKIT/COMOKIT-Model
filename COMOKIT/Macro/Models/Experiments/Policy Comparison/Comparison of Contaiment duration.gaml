/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	Model comparing 3 durations of lockdown
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology,policy comparison
******************************************************************/

model CoVid19

import "../Abstract Experiment.gaml"



experiment "Comparison"  parent: abstract_experiment autorun: true {
	float simulation_seed <- 1.0;
	
	action _init_ {
		
			
		create simulation  with:(name: "No containment policy", seed:simulation_seed ) {
			ask Authority {
				name <- "No containment policy";
				policy <- create_no_containment_policy();
				
			}
		
		}
		
		create simulation with:(name: "Lockdown 7 days",seed:simulation_seed ){
			name <- "Lockdown 7 days";
			ask Authority {
				policy <- create_lockdown_policy();
				policy <- during(policy, 7); 
				policy <- with_tolerance(policy,0.05);
			}
		
		}

			
		create simulation with:(name: "Lockdown 15 days",seed:simulation_seed ){
			name <- "Lockdown 15 days";
			ask Authority {
				policy <- create_lockdown_policy();
				policy <- during(policy, 15); 
				policy <- with_tolerance(policy,0.05);
			}
		
		}

		create simulation with:(name: "Lockdown 60 days", seed:simulation_seed ){
			name <- "Lockdown 60 days";
			ask Authority {
				policy <- create_lockdown_policy();
				policy <- during(policy, 60); 
				policy <- with_tolerance(policy,0.05);
			}
		}
	}
	
	output {
		
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Plot" parent: states_evolution_chart {}	
	}
}
	