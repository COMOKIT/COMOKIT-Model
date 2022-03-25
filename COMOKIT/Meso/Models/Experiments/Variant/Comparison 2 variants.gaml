/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Benoit Gaudou
* 
* Description: 
* 	Comparison of infection by 2 variaantss: it creates one simulation with a no containment policy 
* 		and plots the evolution of the number of individuals infecte by each variant.
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology
******************************************************************/

model Comparison2variants

import "../Abstract Experiment.gaml"

global {
	//number of infected individuals by the original strain at the initialization of the simulation
	int num_infected_init <- 2; 
	//number of infected individuals by the B.1.1.7  (UK) variant at the initialization of the simulation	
	int num_infected_init_variant <- 2;
	virus variant;
	
	//scenario of later introduction
	bool delay_scenario <- true;
	float new_variant_delay <- 2#week;
	int infected_threshold <- 50;
	
	bool DEBUG <- true;
		
	/*
	 * Used to initialize a second variant infection
	 */
	action after_init {
		variant <- VOC first_with (each.name = "Beta");
		if not delay_scenario {
			ask num_infected_init_variant among (all_individuals where (each.state = susceptible)) { 
				do define_new_case(variant);
			}
		}
	}	
	
	action define_policy{   
		ask Authority {
			name <- "No containment policy";
			policy <- create_no_containment_policy();
		}
	}	
	
	reflex introduce_variant when:delay_scenario and cycle*step>=new_variant_delay or total_number_of_infected>=infected_threshold {
		ask num_infected_init_variant among (all_individuals where (each.state = susceptible)) { 
			do define_new_case(variant);
		}
		delay_scenario <- false;
	}
}

experiment "No Containment" parent: "Abstract Experiment" autorun: true {
	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		monitor nb_prevented_reinfection value:sum(all_individuals accumulate (each.infectious_contacts_with.values count (each=true)));
		monitor nb_reinfection value:all_individuals count (length(each.infection_history)>1);
		
		display "Main" parent: default_display {}
		display "Infections by variants" parent: infections_by_variant {}
	}
}
