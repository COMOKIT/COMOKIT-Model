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
		ask Authority {
			lockDown <- createLockDownPolicy();
			noContainment <- createPolicy(true, true);
			noSchool <- createPolicy(false, true);
			noMeetingRelaxing<-createNoMeetingPolicy();
		}
		
		do define_policy;

	}
	
	action define_policy{}
 
}
/* Describes the main authority in charge of the health policies to implement */
species Authority {
	list<Policy> policies;
	Policy lockDown ;
	Policy noContainment ;
	Policy noSchool ;
	Policy noMeetingRelaxing ;
	
	Policy createLockDownPolicy {
		create Policy returns: result {
			loop s over: Activities.keys {
				allowed_activities[s] <- false;
			}
		}
		return first(result);
	}
	
	PartialPolicy createLockDownPolicyWithToleranceOf(float p) {
		create PartialPolicy returns: result {
			tolerance <- p;
			loop s over: Activities.keys {
				allowed_activities[s] <- false;
			}
		}
		return first(result);
	}
	
	SpatialPolicy createQuarantinePolicyAtRadius(point loc, float radius){		
		create SpatialPolicy returns: result {
			loop s over: Activities.keys {
				allowed_activities[s] <- false;
			}
		} 
		SpatialPolicy p<-first(result);
		p.application_area<-circle(radius) at_location loc;
		return p;
	}
	
	Policy createNoMeetingPolicy {
		create Policy returns: result {
			loop mp over: meeting_relaxing_act {
				allowed_activities[mp] <- false;
			}
		}

		return (first(result));
	}
	Policy createDetectionPolicy(int nb_people_to_test, bool only_symptomatic, bool only_not_tested)
	{
		create DetectionPolicy returns: result{
			nb_individual_tested_per_step <- nb_people_to_test;
			symptomatic_only <- only_symptomatic;
			not_tested_only <- only_not_tested;
		}
		return (first(result));
	}
	
	
	Policy createConditionalContainmentPolicy (float nb_days, int min_cases) {
		create TemporaryWithDetectedPolicy returns: result {
			time_applied <- nb_days;
			min_reported <- min_cases;
			applied <- false;
			applying <- false;
		}

		return (first(result));
	}
	
	Policy createLockDownPolicyWithPercentage(float p) {
		create LockdownPolicy returns: result {
			percentage_of_essential_workers <- p;
		}
		return (first(result));
	}
	
	Policy createPolicy (bool school, bool work) {
		create Policy returns: result {
			allowed_activities[studying.name] <- school;
			allowed_activities[working.name] <- work;
		}

		return (first(result));
	}

	bool allows (Individual i, Activity activity) { 
		loop p over: policies { 
			if (!p.is_allowed(i, activity)) {
				return false;
			}
		}
		return true;
	}

}  