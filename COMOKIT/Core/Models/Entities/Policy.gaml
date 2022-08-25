/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* All the base policies provided with COMOKIT. Most of their combinations
* are indeed declared in the actions of the Authority agent.
* 
* Author: Alexis Drogoul, Benoit Gaudou, Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19 

import "Abstract Individual.gaml"


species AbstractPolicy virtual: true { 
	int max_number_individual_group <- int(#max_int);
	list<AbstractIndividual> targeted_individuals <- list(all_individuals);
	
	bool is_active {
		return true;
	}

	/**
	 * This action is called by the authority every step 
	 */
	action apply virtual: true;

	/**
	 * This action returns whether or not a given Individual is allowed to undertake a given Activity
	 */
	bool is_allowed (AbstractIndividual i, AbstractActivity activity) virtual: true;
	
	/**
	 * This action returns the max number of Individual is allowed to undertake a given Activity in group
	 */
	int max_allowed (AbstractIndividual i, AbstractActivity activity) {
		return max_number_individual_group;
	}
	
	/**
	 * This action - defined for the macro model - returns the rate of individuals coming from source area to carry out a given activity in a given type of building into a target area 
	 */
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type, float tested_susceptible, float tested_infected) virtual: true;
}


species NoPolicy parent: AbstractPolicy {

	bool is_active { return false; }

	action apply {
	// Nothing to do
	}
	
	bool is_allowed (AbstractIndividual i, AbstractActivity activity){
		return true;
	}
	
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type,float tested_susceptible, float tested_infected) {
		return [1.0,1.0];
	}
}

/**
 * A policy described by a listing of allowed or disallowed activities. Not explicitly disallowed activities are considered as allowed
 */
species ActivitiesListingPolicy parent: AbstractPolicy {
	map<string, bool> allowed_activities;


	action apply {
	// Nothing to do
	}

	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		if (allowed_activities[activity.name] != nil) {
			return allowed_activities[activity.name];
		} else {
			return true;
		}
	}
	
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type,float tested_susceptible, float tested_infected) {
		return allowed_activities[activity_str] ? [1.0,1.0] : [0.0,0.0];
	}
	
	

}

/**
 * A lockdown policy that forbids people tested positive to move away from home
*/
species PositiveAtHome parent: AbstractPolicy {
	
	action apply {
	// Nothing to do
	}

	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		if (i.report_status = tested_positive and activity.name != act_home) {
			return false;
		}
		return true;
	}
	
	//@todo : TO IMPLEMENT
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type,float tested_susceptible, float tested_infected) {
		return [1.0,1.0];
	}
}


/**
 * A lockdown policy that forbids people tested positive and its family to move away from home
*/
species FamilyOfPositiveAtHome parent: AbstractPolicy {
	
	action apply {
	// Nothing to do
	}

	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		if( ((i.relatives + i) one_matches (each.report_status = tested_positive)) and activity.name != act_home) {
			return false;
		}
		return true;
	}
	//@TODO  : TO IMPLEMENT
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type, float tested_susceptible, float tested_infected) {
		if activity_str = act_home {
			return [1.0,1.0];
		}
		
		return [1.0 - tested_susceptible,1.0 - tested_infected];
	}
}

/**
 * This policy represents a list of policies. */
species CompoundPolicy parent: AbstractPolicy {
	list<AbstractPolicy> targets;

	bool is_active {
		return targets all_match (each.is_active());
	}
	
	action apply {
		ask targets {
			do apply;
		}
	}
	
	bool is_allowed(AbstractIndividual i, AbstractActivity activity) {
		loop p over: targets {
			if ( !p.is_allowed(i, activity)) {
				return false;
			}
		}
		return true;
	}
	
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type, float tested_susceptible, float tested_infected) {
		list<float> rate <- [1.0,1.0];
		loop p over: targets {
			list<float> r <-  p.allowed(source_area, target_area, activity_str, building_type, tested_susceptible, tested_infected);
			rate <- [rate[0] * r[0],rate[1] * r[1]];
		}
		return rate;
	}
}

/**
 * This policy forwards all of its calls to a target policy
  */
species ForwardingPolicy parent: AbstractPolicy {
	AbstractPolicy target;
	
	bool is_active {
		return target.is_active();
	}

	action apply {
		ask target {
			do apply();
		}
	}

	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		return target.is_allowed(i, activity);
	}
	
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type,float tested_susceptible, float tested_infected) {
		return target.allowed(source_area, target_area, activity_str, building_type, tested_susceptible,  tested_infected);
	}

}



/**
 * A policy that accepts a proportion of normally forbidden activities
 */
species PartialPolicy parent: ForwardingPolicy {
	
	float tolerance; // between 0 (no tolerance) and 1.0
	
	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		if flip(tolerance) {
			return true;
		}
		return super.is_allowed(i, activity);
	}
	
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type, float tested_susceptible, float tested_infected) {
		list<float> r <- super.allowed(source_area, target_area, activity_str, building_type, tested_susceptible, tested_infected) ;
		float tol <- ( 1 - tolerance) ;
		return [r[0] * tol, r[1] * tol];
	}

}

/**
 * A policy that restricts the application of another policy to a given geographical area. If outside, it allows everything
 * The area is recomputed everyday, given the infected people. 
 */

species DynamicSpatialPolicy parent: CompoundPolicy {
	AbstractPolicy target;
	float radius ;
	
	action apply {
		if(every(1#day)) {
			list<AbstractIndividual> infecteds <- all_individuals where(each.report_status = tested_positive);
			ask targets {do die;}
			targets <- [];
			loop i over: infecteds {
				create SpatialPolicy with: [target::target, application_area::(circle(radius) at_location i.location)] returns: result;
								
				targets << first(result);
			}
		}
	}
}

/**
 * A policy that restricts the application of another policy to a given geographical area. If outside, it allows everything
*/
species SpatialPolicy parent: ForwardingPolicy {
	geometry application_area;
	
	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		if (application_area overlaps i) {
			return super.is_allowed(i, activity);
		} else {
			return true;
		}

	}

}

/**
 * A policy that allows certain people ("allowed_workers") to undertake any activity. They are initially determined as a percentage of the population
 */
species AllowedIndividualsPolicy parent: ForwardingPolicy {
	float percentage_of_essential_workers <- 0.1;
	map<AbstractIndividual,bool> allowed_workers <- [];

	action apply {
		invoke apply();
		if empty(allowed_workers) and percentage_of_essential_workers > 0 {
			allowed_workers <- ((percentage_of_essential_workers * length(all_individuals)) among all_individuals) as_map (each::true);
		}
	}

	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		if (allowed_workers contains_key i) {
			return allowed_workers[i];
		} else {
			return super.is_allowed(i, activity);
		}
	}

}

/*
 * Abstract method to limit the targeted population of a policy  
 */
species GroupTargetPolicy parent: ForwardingPolicy {
	
	action apply {
		if empty(targeted_individuals) { targeted_individuals <- targeted_individuals();}
		invoke apply();
	}
	
	list<AbstractIndividual> targeted_individuals virtual:true {}
	
}

//Target a sub-set of individuals based on an age range (age_range)
species AgeTargetPolicy parent:GroupTargetPolicy {
	point age_range;
	list<AbstractIndividual> targeted_individuals  { return all_individuals where (not(each.clinical_status!=dead) and age_range.x <= each.age and each.age <= age_range.y);}	
}

//Target a sub-set of individuals based on their epidemiological states
species StateTargetPolicy parent:GroupTargetPolicy {
	list<string> states;
	
	list<string> hidden_states <- [latent, presymptomatic, asymptomatic]; 
	bool real_state <- false;
	float test_time_frame <- #week;
	
	list<AbstractIndividual> targeted_individuals  {
		if not(real_state) and states one_matches ([latent, presymptomatic, asymptomatic] contains each) {
			list<string> current_hidden_states <- [latent, presymptomatic, asymptomatic] where (states contains each);
			list<string> current_observable_states <- states - current_hidden_states;
			return all_individuals where (current_observable_states contains each.state or 
				(each.last_test*step < test_time_frame and current_hidden_states contains each.state));
		}  else {
			return all_individuals where (states contains each.clinical_status);
		}
	}
}

/**
 * A policy that restricts the duration of another policy. If before, or after, everything is allowed */
 
species TemporaryPolicy parent: ForwardingPolicy {
	date start_date <- starting_date;
	
	date start;
	bool started <- false;
	bool finished <- false;
	
	int duration; // in seconds
	
	
	bool is_active {
		return started and !finished;
	}
	
	action apply {
		invoke apply();
		if (!started and !finished) {
			if (target.is_active() and current_date >= start_date) {
				started <- true;
				finished <- false;
				start <- current_date;
			}
		} else {
			if (current_date >= start + duration) {
				finished <- true;
			}
		}
	}
	
	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		if (!is_active()) {
			return true;
		}
		return super.is_allowed(i, activity);
	}
	
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type, float tested_susceptible, float tested_infected) {
		if (!is_active()) {
			return [1.0,1.0];
		}
		return super.allowed(source_area, target_area, activity_str, building_type, tested_susceptible, tested_infected);
	}
	

	
}

/** 
 * A policy that only starts after a number of reported cases and stops after another
*/

species CaseRangePolicy parent: ForwardingPolicy {
	int min <- -1;
	int max <- int(#max_int);
	bool only_hospitalized <- false;
	
	bool is_active {
		return only_hospitalized ?
			total_number_hospitalised between (min-1, max) : 
			total_number_reported between (min -1, max);
	}
	
	bool is_allowed(AbstractIndividual i, AbstractActivity activity){
		if (!is_active()) {
			return true;
		}
		return super.is_allowed(i, activity);
	}
}

/**
 * The policy used to conduct tests  */
species DetectionPolicy parent: AbstractPolicy {
	int nb_individual_tested_per_step;
	bool symptomatic_only;
	bool not_tested_only;
	bool macro_model <- false;
	
	action apply {
		if (macro_model) {
			if (symptomatic_only) {
			} else {
				
			}
		} else {
			list<AbstractIndividual> individual_to_test;
			if (symptomatic_only) {
				individual_to_test <-  not_tested_only ? (all_individuals where (each.state = symptomatic and each.report_status = not_tested)) : (all_individuals where (each.state = symptomatic));
				ask nb_individual_tested_per_step among individual_to_test {
					do test_individual;
				}
			} else {
				individual_to_test <-  (not_tested_only ? all_individuals where (each.clinical_status != dead and each.report_status = not_tested) : all_individuals where (each.clinical_status != dead));
				ask nb_individual_tested_per_step among individual_to_test {
					do test_individual;
					
				}
			}
		}	
		
	}
	bool is_allowed (AbstractIndividual i, AbstractActivity activity) {
		return true;
	}

	list<float> allowed(int source_area, int target_area, string activity_str, string building_type, float tested_susceptible, float tested_infected) {
		return [1.0,1.0];
	}
}

/**
 * Vax policy 
 */
 species VaxPolicy parent:AbstractPolicy {

	covax v; 	
	
	int remaining_doses;
	int pending_doses;
	
 	float nb_vax_per_step;
 	
 	map<int,list<AbstractIndividual>> schedule;
 	
 	action apply {
 		
 		int remaining_vax <- int(nb_vax_per_step) + (flip(nb_vax_per_step-int(nb_vax_per_step))?1:0);
 		
 		if cycle = 0 {ask world {do console_output("Vax plan for "+myself.v.name+" with "+string(remaining_vax)+" doses this step and "+string(length(myself.targeted_individuals))+" vax target","VaxPolicy | Policy.gaml");}}
 		
 		// Start by scheduled vax
 		if schedule contains_key cycle {
	 		loop i over:schedule[cycle] {
	 			if pending_doses > 0 and remaining_vax > 0 { 
	 				ask i {do vaccination(myself.v);}  
	 				pending_doses <-  pending_doses - 1; 
	 				remaining_vax <- remaining_vax - 1;
	 			}
	 		}
 		}
 		
 		// Try to spent remaining vax 
 		loop times:remaining_vax {
 			
 			// Find relevant individual
 			list<AbstractIndividual> targets <- targeted_individuals - schedule accumulate (each);
 			
 			// Pick one and...
 			AbstractIndividual i <- any(targets);
 			
 			ask world {do console_output("Trying to vaccine "+i+"("+sample(i.vax_willingness)+") with "+myself.v,"VaxPolicy.apply",first(levelList));}
 			
 			// she/he is not an antivax, proceed to vaccination 
 			if flip(i.vax_willingness) {
 				
 				int dose_nb; 
 				ask i {dose_nb <- vaccination(myself.v);} 
 				remaining_doses <-  remaining_doses - 1;
 				
 				// If it is not last doses
 				if dose_nb <= length(v.vax_schedul) {
 					
 					// Randomly find a date corresponding to vax posology
 					pair<float,float> next_vax_sched <- v.vax_schedul[dose_nb-1]; 
 					float next_vax_time <- rnd(next_vax_sched.key, next_vax_sched.value);
 					int scheduled_cycle <- int(cycle+next_vax_time/step); 
 					
 					// Schedul future appointment
 					if schedule contains_key scheduled_cycle { schedule[scheduled_cycle] <+ i;}
 					else {schedule[scheduled_cycle] <- [i];}
 					remaining_doses <- remaining_doses - 1;
 					pending_doses <- pending_doses + 1; 
 				}
 			}
 		}
 		
 	} 
 	
 	bool is_allowed (AbstractIndividual i, AbstractActivity activity) { return true; }
 	
 	//@TODO  : TO IMPLEMENT
	list<float> allowed(int source_area, int target_area, string activity_str, string building_type, float tested_susceptible, float tested_infected) {
		return [1.0,1.0];
	}
 	
 } 
 
