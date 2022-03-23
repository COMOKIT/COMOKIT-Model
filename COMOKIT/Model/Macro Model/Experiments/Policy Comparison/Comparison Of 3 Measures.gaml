/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	Model comparing 3 measures: no containment, school closed and home containement (workplaces and schools are closed).
* 	One simulation on the same case study and with the same Random Number Generator seed  is created for each measure scenario.
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology,policy comparison
******************************************************************/

model CoVid19

import "../Abstract Experiments.gaml"



experiment "Comparison"  parent: abstract_experiment autorun: true {
	
	float simulation_seed <- 1.0;
		
	action _init_ {
		
		
		/*
		 * Initialize a simulation with a no containment policy  
		 */		
		create simulation with:(name: "No Containment", macro_model:true, shp_boundary_path: bound_shapefile, csv_boundary_path:bound_csv,seed:simulation_seed ){
			name <- "No Containment";
			ask Authority { 
				policy <- create_no_containment_policy();
			}
		}
		
		
		/*
		 * Initialize a simulation with a policy closing schools and workplaces  
		 */	
		create simulation with:(name: "Home Containment", macro_model:true, shp_boundary_path: bound_shapefile, csv_boundary_path:bound_csv,seed:simulation_seed ){
			name <- "Home Containment";
			ask Authority {
				policy <- create_school_work_allowance_policy(false, false);
			}
		}
		
		/*
		 * Initialize a simulation with a school closed policy  
		 */		
		create simulation  with:(name: "School closed", macro_model:true, shp_boundary_path: bound_shapefile, csv_boundary_path:bound_csv,seed:simulation_seed ) {
			name <- "School closed";
			ask Authority {
				policy <- create_school_work_allowance_policy(false, true);
			}
		}

		
	}
	
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Plot" parent: states_evolution_chart {}	
	}
}
	