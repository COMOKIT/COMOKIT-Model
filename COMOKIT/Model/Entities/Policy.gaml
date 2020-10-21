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

	bool is_active { return false; }

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

	bool is_active {
		return targets all_match (each.is_active());
	}
	
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
			list<Individual> infecteds <- all_individuals where(each.report_status = tested_positive);
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
			allowed_workers <- ((percentage_of_essential_workers * length(all_individuals)) among all_individuals) as_map (each::true);
		}
	}

	bool is_allowed (Individual i, Activity activity) {
		if (allowed_workers contains_key i) {
			return allowed_workers[i];
		} else {
			return super.is_allowed(i, activity);
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
	bool only_hospitalized <- false;
	
	bool is_active {
		return only_hospitalized ?
			total_number_hospitalised between (min-1, max) : 
			total_number_reported between (min -1, max);
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
		list<Individual> individual_to_test <- symptomatic_only ? (not_tested_only ? all_individuals where (each.state = symptomatic and
		each.report_status = not_tested) : all_individuals where (each.state = symptomatic)) : (not_tested_only ? all_individuals where (each.clinical_status != dead and
		each.report_status = not_tested) : all_individuals where (each.clinical_status != dead));
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
	//Allowing ICU admission or not (example, Lao PDR does not have ICU capacity)
	bool is_allowing_ICU;
	//Allowing hospitalisation or not (example, not wanting symptomatic people that are not in the need of ICU to maintain other services)
	bool is_allowing_hospitalisation;
	//Minimum number of tests needed to be negative to discharge an individual
	int nb_minimum_tests;
	
	species<Hospital> hospital_species <- Hospital;
	container<Hospital> hospitals -> {container<Hospital>(hospital_species.population+(hospital_species.subspecies accumulate each.population))};
	
	//Remove an individual from ICU
	action remove_individual_from_ICU(Individual an_individual, Hospital a_hospital){
		remove an_individual from:a_hospital.ICU_individuals;
		a_hospital.capacity_ICU <- a_hospital.capacity_ICU+1;
		an_individual.is_ICU <- false;
	}
	
	//Remove an individual from being hospitalised (but could be later added in ICU)
	action remove_individual_from_hospitalised(Individual an_individual, Hospital a_hospital){
		remove an_individual from:a_hospital.hospitalised_individuals;
		a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation+1;
		an_individual.is_hospitalised <- false;
	}
	
	//Adding an individual to ICU
	action add_individual_to_ICU (Individual an_individual, Hospital a_hospital){
		add an_individual to: a_hospital.ICU_individuals;
		a_hospital.capacity_ICU <- a_hospital.capacity_ICU-1;
		an_individual.is_ICU <- true;
		ask an_individual{
			do enter_building(a_hospital);
		}
	}
	
	//Adding an individual to hospitalised individuals
	action add_individual_to_hospitalised (Individual an_individual, Hospital a_hospital){
		add an_individual to: a_hospital.hospitalised_individuals;
		a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation-1;
		an_individual.is_hospitalised <- true;
		ask an_individual{
			do enter_building(a_hospital);
		}
	}
	
	//Try to find a place for the individual according to its clinical status
	action try_add_individual_to_hospital(Individual an_individual){
		if(an_individual.clinical_status=need_hospitalisation){
			list<Hospital> possible_hospitals <- (hospitals where(each.capacity_hospitalisation>0));
			if(length(possible_hospitals)>0){
				do add_individual_to_hospitalised(an_individual,one_of(possible_hospitals));
			}else{
				//Send the individual back home when no place is available
				ask an_individual{
					do enter_building(self.home);
				}
			}
		}else{
			list<Hospital> possible_hospitals <- (hospitals where(each.capacity_ICU>0));
			if(length(possible_hospitals)>0){
				do add_individual_to_ICU(an_individual,one_of(possible_hospitals));
			}else{
				//send the individual back home when no place is available, could be changed to sending him to "normal" hospitalisation beds
				ask an_individual{
					do enter_building(self.home);
				}
			}
		}
	}
	
	//Update the individuals in hospital
	action update_individuals_in_hospital{
		loop a_hospital over: hospitals {
			
			//REMOVE DEAD PEOPLE
			loop an_individual over: a_hospital.hospitalised_individuals where(each.clinical_status=dead){
				do remove_individual_from_hospitalised(an_individual, a_hospital);
			}
			loop an_individual over: a_hospital.ICU_individuals where(each.clinical_status=dead){
				do remove_individual_from_ICU(an_individual, a_hospital);
			}
			
			//REMOVE RECOVERED PEOPLE FROM HOSPITALISED
			loop an_individual over: a_hospital.hospitalised_individuals where((each.state!=symptomatic) and (cycle-each.last_test>nb_step_for_one_day) and (each.number_negative_tests<nb_minimum_tests)){
				ask an_individual{
					do test_individual;
				}
				//If the individual has been tested negative enough times, discharge it
				if(an_individual.report_status=tested_negative){
					an_individual.number_negative_tests <- an_individual.number_negative_tests +1;
					if(an_individual.number_negative_tests>=nb_minimum_tests){
						do remove_individual_from_hospitalised(an_individual, a_hospital);
						if(an_individual.state=removed){
							an_individual.clinical_status <- recovered;
							ask an_individual{
								do enter_building(self.home);
							}
						}
					}
				}else{
					an_individual.number_negative_tests <- 0;
				}
			}
			
			//REMOVE ICU PEOPLE THAT JUST NEED HOSPITALISATION
			loop an_individual over: a_hospital.ICU_individuals where(each.clinical_status=need_hospitalisation){
				do remove_individual_from_ICU(an_individual,a_hospital);
				if(a_hospital.capacity_hospitalisation>0){
					do add_individual_to_hospitalised(an_individual,a_hospital);
				}else{
					do try_add_individual_to_hospital(an_individual);
				}
			}
			
			//ADD HOSPITALISED PEOPLE THAT NOW NEED ICU
			loop an_individual over: a_hospital.hospitalised_individuals where(each.clinical_status=need_ICU){
				do remove_individual_from_hospitalised(an_individual, a_hospital);
				if(a_hospital.capacity_ICU>0){
					do add_individual_to_ICU(an_individual,a_hospital);
				}else{
					do try_add_individual_to_hospital(an_individual);
				}
			}
		}
	}
	//Apply the policy
	action apply{
		//Updating individuals in the hospitals
		do update_individuals_in_hospital;
		if(is_allowing_hospitalisation){
			//ADD PEOPLE NEEDING ICU OR HOSPITALISATION NOT PRESENT YET
			loop an_individual over: all_individuals where((each.clinical_status=need_hospitalisation) and (each.is_hospitalised=false)){
				do try_add_individual_to_hospital(an_individual);
			}
		}
		if(is_allowing_ICU){
			loop an_individual over: all_individuals where((each.clinical_status=need_ICU) and (each.is_ICU=false)){
				do try_add_individual_to_hospital(an_individual);
			}
		}
	}
	//Preventing moving anywhere for people hospitalised
	bool is_allowed (Individual i, Activity activity){
		return not(i.is_ICU or i.is_hospitalised);
	}
}