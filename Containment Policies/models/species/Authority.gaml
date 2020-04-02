/***
* Name: Authority
* Author: drogoul
* Description: 
* Tags: Tag1, Tag2, TagN
***/

@no_experiment

model Authority

import "../Parameters.gaml"

import "Policy.gaml"

global {
	action create_authority {
		write "Create an authority ";
		create Authority;
		do define_policy;

	}
	
	action define_policy{}
 
}
/* Describes the main authority in charge of the health policies to implement */
species Authority {
	AbstractPolicy policy <- create_no_containment_policy(); // default
	
	reflex apply_policy {
		if (policy.can_be_applied()) {
			ask policy {
				do apply();
			}
		}
	}

	bool allows (Individual i, Activity activity) { 
		if (policy = nil) {return true;}
		return policy.can_be_applied() and policy.is_allowed(i,activity);
	}
	
	/**
 * Set of constructor functions used to build policies
 */
	
	
	SpatialPolicy in_area (AbstractPolicy p, geometry area) {
		create SpatialPolicy with: [target::p, application_area::area] returns: result;
		return first(result);
	}
	
	TemporaryPolicy during (AbstractPolicy p, date start, int duration_in_seconds) {
		create TemporaryPolicy with: [target::p, start:: start, duration::duration_in_seconds] returns: result;
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
	
	AbstractPolicy create_lockdown_policy {
		create ActivitiesListingPolicy returns: result {
			loop s over: Activities.keys {
				allowed_activities[s] <- false;
			}
		}
		return first(result);
	}
	
	AbstractPolicy create_lockdown_policy_with_percentage(float p) {
		create LockdownPolicy returns: result {
			percentage_of_essential_workers <- p;
		}
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
		AbstractPolicy p <- from_min_cases(during(create_lockdown_policy(), current_date, int(nb_days #day)),min_cases);
		return p;
	}
	
	
	AbstractPolicy create_no_containment_policy {
		return createPolicy(true, true);
	}
	
	AbstractPolicy createPolicy (bool school, bool work) {
		create ActivitiesListingPolicy returns: result {
			allowed_activities[studying.name] <- school;
			allowed_activities[working.name] <- work;
		}

		return (first(result));
	}

}  