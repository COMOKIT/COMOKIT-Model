/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul, Benoit Gaudou
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Individual.gaml"


species AbstractPolicy virtual: true {
	int max_number_individual_group <- int(#max_int);
	
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
	bool is_allowed (Individual i, Activity activity) virtual: true;
	
	/**
	 * This action returns the max number of Individual is allowed to undertake a given Activity in group
	 */
	int max_allowed (Individual i, Activity activity) {
		return max_number_individual_group;
	}
}


species NoPolicy parent: AbstractPolicy {


	action apply {
	// Nothing to do
	}
	
	bool is_allowed (Individual i, Activity activity){
		return true;
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

	bool is_allowed (Individual i, Activity activity) {
		if (allowed_activities[activity.name] != nil) {
			return allowed_activities[activity.name];
		} else {
			return true;
		}
	}
	
	

}

/**
 * A lockdown policy that forbids people tested positive to move away from home
*/
species PositiveAtHome parent: AbstractPolicy {
	
	action apply {
	// Nothing to do
	}

	bool is_allowed (Individual i, Activity activity) {
		if (i.report_status = tested_positive and activity.name != act_home) {
			return false;
		}
		return true;
	}

}


/**
 * A lockdown policy that forbids people tested positive and its family to move away from home
*/
species FamilyOfPositiveAtHome parent: AbstractPolicy {
	
	action apply {
	// Nothing to do
	}

	bool is_allowed (Individual i, Activity activity) {
		if( ((i.relatives + i) one_matches (each.report_status = tested_positive)) and activity.name != act_home) {
			return false;
		}
		return true;
	}

}

/**
 * This policy represents a list of policies. */
species CompoundPolicy parent: AbstractPolicy {
	list<AbstractPolicy> targets;

	
	action apply {
		ask targets {
			do apply;
		}
	}
	
	bool is_allowed(Individual i, Activity activity) {
		loop p over: targets {
			if ( !p.is_allowed(i, activity)) {
				return false;
			}
		}
		return true;
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

	bool is_allowed (Individual i, Activity activity) {
		return target.is_allowed(i, activity);
	}

}



/**
 * A policy that accepts a proportion of normally forbidden activities
 */
species PartialPolicy parent: ForwardingPolicy {
	
	float tolerance; // between 0 (no tolerance) and 1.0
	
	bool is_allowed (Individual i, Activity activity) {
		bool allowed <- super.is_allowed(i, activity);
		if (!allowed) {
			allowed <- flip(tolerance);
		}

		return allowed;
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
			list<Individual> infecteds <- Individual where(each.report_status = tested_positive);
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
	
	bool is_allowed (Individual i, Activity activity) {
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
	map<Individual,bool> allowed_workers <- [];

	action apply {
		invoke apply();
		if empty(allowed_workers) and percentage_of_essential_workers > 0 {
			allowed_workers <- ((percentage_of_essential_workers * length(Individual)) among Individual) as_map (each::true);
		}
	}

	bool is_allowed (Individual i, Activity activity) {
		if (allowed_workers contains_key i) {
			return true;
		} else {
			return super.is_allowed(i, activity);
		}
	}

}

/**
 * A policy that restricts the duration of another policy. If before, or after, everything is allowed */
 
species TemporaryPolicy parent: ForwardingPolicy {
	date start <- starting_date;
	bool started;
	bool finished;
	int duration; // in seconds
	
	
	bool is_active {
		return started and !finished;
	}
	
	action apply {
		invoke apply();
		if (!started and !finished) {
			if (target.is_active()) {
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
	
	bool is_allowed (Individual i, Activity activity) {
		if (!is_active()) {
			return true;
		}
		return super.is_allowed(i, activity);
	}

	
}

/** 
 * A policy that only starts after a number of reported cases and stops after another
*/

species CaseRangePolicy parent: ForwardingPolicy {
	int min <- -1;
	int max <- int(#max_int);
	
	
	bool is_active {
		return total_number_reported between (min -1, max);
	}
	
	bool is_allowed(Individual i, Activity activity){
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

	action apply {
		list<Individual> individual_to_test <- symptomatic_only ? (not_tested_only ? Individual where (each.status = symptomatic and
		each.report_status = not_tested) : Individual where (each.status = symptomatic)) : (not_tested_only ? Individual where (each.status != dead and
		each.report_status = not_tested) : Individual where (each.status != dead));
		ask nb_individual_tested_per_step among individual_to_test {
			do test_individual;
		}

	}

	bool is_allowed (Individual i, Activity activity) {
		return true;
	}

}
