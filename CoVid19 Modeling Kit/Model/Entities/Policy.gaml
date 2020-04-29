/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul, Benoit Gaudou, Damien Philippon
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

/**
 * The policy used to use hospitals for cure  */
species HospitalisationPolicy parent: AbstractPolicy{
	bool is_allowing_ICU;
	bool is_allowing_hospitalisation;
	
	action add_individual_to_hospital(Individual an_individual){
		if(an_individual.status != dead){
			list<Hospital> available_hospitals <- Hospital where(each.capacity_hospitalisation>0);
			if(an_individual.hospitalisation_status=need_ICU){
				available_hospitals <- Hospital where(each.capacity_ICU>0);
			}
			if(length(available_hospitals)>0){
				Hospital the_hospital <- one_of(available_hospitals);
				if(an_individual.hospitalisation_status=need_ICU){
					add an_individual to: the_hospital.ICU_individuals;
					the_hospital.capacity_ICU <- the_hospital.capacity_ICU-1;
					an_individual.is_ICU <- true;
					an_individual.is_hospitalised <- false;
					ask an_individual{
						do enter_building(the_hospital);
					}
				}else{
					add an_individual to: the_hospital.hospitalised_individuals;
					the_hospital.capacity_hospitalisation<- the_hospital.capacity_hospitalisation-1;
					an_individual.is_ICU <- false;
					an_individual.is_hospitalised <- true;
					ask an_individual{
						do enter_building(the_hospital);
					}
				}
			}else{
				ask an_individual{
					is_ICU <- false;
					is_hospitalised <- false;
					do enter_building(self.home);
				}
			}
		}
	}
	
	action update_individuals_in_hospital{
		loop a_hospital over: Hospital{
			if(length(a_hospital.individuals)>0){
				//Removing dead individuals
				ask a_hospital.ICU_individuals where(each.status=dead){
					remove self from: a_hospital.ICU_individuals;
					self.is_ICU <- false;
					self.is_hospitalised <- false;
					self.hospitalisation_status <- no_need_hospitalisation;
					a_hospital.capacity_ICU <- a_hospital.capacity_ICU+1;
				}
				ask a_hospital.hospitalised_individuals where(each.status=dead){
					remove self from: a_hospital.hospitalised_individuals;
					self.is_ICU <- false;
					self.is_hospitalised <- false;
					self.hospitalisation_status <- no_need_hospitalisation;
					a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation+1;
				}
				
				
				//Changing ICU individuals
				loop an_individual over: a_hospital.ICU_individuals where(each.hospitalisation_status!=need_ICU){
					remove an_individual from: a_hospital.ICU_individuals;
					a_hospital.capacity_ICU <- a_hospital.capacity_ICU+1;
					an_individual.is_ICU <- false;
					an_individual.is_hospitalised <- false;
					if((an_individual.status!=recovered)and(an_individual.hospitalisation_status=need_hospitalisation)){
						if(a_hospital.capacity_hospitalisation>0){
							a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation-1;
							add an_individual to: a_hospital.hospitalised_individuals;
							an_individual.is_hospitalised <- true;
						}else{
							do add_individual_to_hospital(an_individual);
						}
					}else{
						ask an_individual{
							do enter_building(self.home);
						}
					}
				}
				
				//Changing hospitalised individuals needing ICU
				loop an_individual over:a_hospital.hospitalised_individuals where(each.hospitalisation_status=need_ICU){
					remove an_individual from: a_hospital.hospitalised_individuals;
					a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation+1;
					an_individual.is_ICU <- false;
					an_individual.is_hospitalised <- false;
					if(a_hospital.capacity_ICU>0){
						add an_individual to: a_hospital.ICU_individuals;
						a_hospital.capacity_ICU <- a_hospital.capacity_ICU -1;
						an_individual.is_ICU <- true;
					}else{
						do add_individual_to_hospital(an_individual);
					}
				}
				
				//Changing hospitalised individuals needing to be release
				loop an_individual over:a_hospital.hospitalised_individuals where((each.hospitalisation_status=no_need_hospitalisation) or (each.status=recovered)){
					remove an_individual from: a_hospital.hospitalised_individuals;
					a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation+1;
					an_individual.is_ICU <- false;
					an_individual.is_hospitalised <- false;
					ask an_individual{
						do enter_building(self.home);
					}
				}
			}
		}
	}
	
	action apply{
		//Updating individuals in the hospitals
		do update_individuals_in_hospital;
		
		//Look for new individuals to put to the hospital
		if(is_allowing_ICU){
			loop an_individual over: Individual where((each.hospitalisation_status=need_ICU) and (each.status!=dead) and (each.is_ICU=false)){
				do add_individual_to_hospital(an_individual);
				total_number_ICU <- total_number_ICU +1;
			}
		}
		if(is_allowing_hospitalisation){
			loop an_individual over: Individual where((each.hospitalisation_status=need_hospitalisation) and (each.status!=recovered) and (each.status!=dead) and (each.is_hospitalised=false) and (each.is_ICU=false)){
				do add_individual_to_hospital(an_individual);
				total_number_hospitalised <- total_number_hospitalised+1;
			}
		}
	}
	
	bool is_allowed (Individual i, Activity activity){
		if(i.is_ICU){
			return false;
		}else{
			if(i.is_hospitalised){
				return false;
			}
		}
		return true;
	}
}