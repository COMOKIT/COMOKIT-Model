/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 2.0, May 2021. See http://comokit.org for support and updates
* Author: Patrick Taillandier
* 
* Description: 
* 	Model with a lockdown policy applied during a given number of days. It used the precomputation mode to decrease the computation time.
* 	In a total lockdown, no activities are allowed, except stay at home, and this is applied to all the Individuals with a given tolerance.
* 	After this lockdown period, no policy is applied.
* 
* Parameters:
* 	- numb_days: defines the number of days for the lockdown application.
* 	- tolerance: defines the probabolity for an individual to carry out its activity in spite of the lockdown
* 
* Dataset: Default dataset (DEFAULT_CASE_STUDY_FOLDER_NAME in Parameters.gaml, i.e. Vinh Phuc)
* Tags: covid19,epidemiology,lockdown
******************************************************************/

model CoVid19

import "../Abstract Experiment.gaml"

global {
	//if true visualise the repartition of people (blue color); for full optimisation, set it to false
	bool display_map <- false;
	
	// Parameter used to define the duration of the lockdown policy
	int num_days <- 20 among: [0,10,20,30,60];

	//Parameter used to define the rate of individuals not following the lockdown - changing this value requires to recompute the building activity file (see Utilities/Generate activity precomputation)
	float tolerance <- 0.05;
	
	//define a lockdown policy for num_days number of days starting at cycle 0 - the individual has a probability "tolerance" to carry out their activity in spite of the lockdown (only acitivity allowed: stay at home)
	action define_policy{
		ask Authority {
			name <- "No containment policy";
			policy <- create_no_containment_policy();
		}
		ask Authority {
			if (num_days > 0) {
				policy <- with_tolerance(create_lockdown_policy_except([act_home]),tolerance); 
				policy <- during(policy, num_days); 
			}
		}
	}

}


experiment "Lockdown" parent: "Abstract Experiment" autorun: true{
	action _init_ {
		create simulation with:(
			use_activity_precomputation:true, //if true, used the precomputation mode
			nb_weeks_ref:2, // number of different weeks precomputated - agents are going to always use them - increasing this value requires to recompute the building activity file (see Utilities/Generate activity precomputation)
			udpate_for_display:display_map, // if true, make some additional computations to be able to display movement of people (color of buildings)
			file_activity_with_policy_precomputation_path:"activity_lockdown_precomputation", //precomputed activity file used when the policy is not applied
			file_activity_without_policy_precomputation_path:"activity_without_policy_precomputation", //precomputed activity  file used when the policy is applied
			num_infected_init: 20 //init number of infected individuals
		);
	}
	
	output {
		//layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;
		
		display "Main" refresh: display_map ? true : false parent: default_display {}
		display "Plot" parent: states_evolution_chart {}	
	}
}