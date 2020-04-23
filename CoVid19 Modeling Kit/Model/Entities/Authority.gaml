/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Alexis Drogoul
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Policy.gaml"
import "ActivitiesMonitor.gaml"

global {

	action create_authority {
		write "Create an authority ";
		create Authority;
		do define_policy;

	}
	
	action define_policy{}
 
}

/* 
 * Describes the main authority in charge of the health policies to implement
 */
species Authority {
	AbstractPolicy policy <- create_no_containment_policy(); // default
	ActivitiesMonitor act_monitor;
	
	reflex apply_policy {
		ask policy {
			do apply();
		}
	}

	reflex init_stats when: every(#day) and (act_monitor != nil) {
		ask act_monitor { do restart_day;}
	}
	
	action update_monitor(Activity act, bool allowed) {
		if(act_monitor != nil){
			ask act_monitor { 
				do update_stat(act, allowed);
			}			
		} 
	}

	bool allows (Individual i, Activity activity) { 
		bool allowed <- policy.is_allowed(i,activity);
		do update_monitor(activity, allowed);
		return allowed ;
	}
	
	int limitGroupActivity (Individual i, Activity activity) { 
		return policy.max_allowed(i,activity);
	}
	
	
/**
 * Set of constructor functions used to build policies
 */
	
	
	SpatialPolicy in_area (AbstractPolicy p, geometry area) {
		create SpatialPolicy with: [target::p, application_area::area] returns: result;
		return first(result);
	}
	
	TemporaryPolicy during (AbstractPolicy p, int nb_days) {
		create TemporaryPolicy with: [target::p, duration::(nb_days #day)] returns: result;
		return first(result);
	}
	
	CaseRangePolicy from_min_cases (AbstractPolicy p, int min) {
		create CaseRangePolicy with: [target::p, min::min] returns: result;
		return first(result);
	}
	
	CaseRangePolicy until_max_cases (AbstractPolicy p, int max) {
		create CaseRangePolicy with: [target::p, max::max] returns: result;
		return first(result);
	}
	
	CompoundPolicy combination(list<AbstractPolicy> policies) {
		create CompoundPolicy with: [targets::policies] returns: result;
		return first(result);
	}
	
	PartialPolicy with_tolerance(AbstractPolicy p, float tolerance) {
		create PartialPolicy with: [target::p, tolerance::tolerance] returns: result;
		return first(result);
	}
	
	ActivitiesListingPolicy create_lockdown_policy {
		create ActivitiesListingPolicy returns: result {
			loop s over: Activities.keys {
				allowed_activities[s] <- false;
			}
		}
		return first(result);
	}
	
	PositiveAtHome create_positive_at_home_policy {
		create PositiveAtHome  returns: result;
		return first(result);
	}
	
	FamilyOfPositiveAtHome create_family_of_positive_at_home_policy {
		create FamilyOfPositiveAtHome returns: result;				
		return first(result);
	}
	
	ActivitiesListingPolicy create_lockdown_policy_except(list<string> allowed) {
		create ActivitiesListingPolicy returns: result {
			allowed_activities <- Activities.keys as_map (each::allowed contains each);
		}
		return first(result);
	}
	
	AllowedIndividualsPolicy with_percentage_of_allowed_individual(AbstractPolicy a, float p) {
		create AllowedIndividualsPolicy with: [target::a, percentage_of_essential_workers::p]  returns: result;
		return (first(result));
	}

	
	SpatialPolicy create_lockdown_policy_in_radius(point loc, float radius){		
		SpatialPolicy p <- in_area(create_lockdown_policy(), circle(radius) at_location loc);
		return p;
	}
	
	AbstractPolicy create_no_meeting_policy {
		create ActivitiesListingPolicy returns: result {
			loop s over: meeting_relaxing_act {
				allowed_activities[s] <- false;
			}
		}
		return (first(result));
	}
	
	
	AbstractPolicy create_detection_policy(int nb_people_to_test, bool only_symptomatic, bool only_not_tested) {
		create DetectionPolicy returns: result {
			nb_individual_tested_per_step <- nb_people_to_test;
			symptomatic_only <- only_symptomatic;
			not_tested_only <- only_not_tested;
		}
		return (first(result));
	}
	
	
	AbstractPolicy createConditionalContainmentPolicy (int nb_days, int min_cases) {
		AbstractPolicy p <- from_min_cases(during(create_lockdown_policy(), nb_days),min_cases);
		return p;
	}
	
	
	AbstractPolicy create_no_containment_policy {
		create NoPolicy returns: result;
		return first(result);
	}
	
	AbstractPolicy createPolicy (bool school, bool work) {
		create ActivitiesListingPolicy returns: result {
			allowed_activities[studying.name] <- school;
			allowed_activities[working.name] <- work;
		}

		return (first(result));
	}

}  