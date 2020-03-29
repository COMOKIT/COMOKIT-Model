/***
* Name: Authority
* Author: drogoul
* Description: 
* Tags: Tag1, Tag2, TagN
***/

@no_experiment

model Authority

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

	}

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
			loop s over: Activity.subspecies {
				allowed_activities[string(s)] <- false;
			}
		}
		return first(result);
	}
	
	PartialPolicy createLockDownPolicyWithToleranceOf(float p) {
		create PartialPolicy returns: result {
			tolerance <- p;
			loop s over: Activity.subspecies {
				allowed_activities[string(s)] <- false;
			}
		}
		return first(result);
	}
	
	SpatialPolicy createQuarantinePolicyAtRadius(point loc, float radius){		
		create SpatialPolicy returns: result {
			loop s over: Activity.subspecies {
				allowed_activities[string(s)] <- false;
			}
		}
		SpatialPolicy p<-first(result);
		p.application_area<-circle(radius) at_location loc;
		return p;
	}
	
	Policy createNoMeetingPolicy {
		create Policy returns: result {
			allowed_activities[a_school.name] <- false;
			allowed_activities[a_work.name] <- false;
			allowed_activities[a_supermarket.name] <- false;
			allowed_activities[a_movie.name] <- false;
			allowed_activities[a_game.name] <- false;
			allowed_activities[a_karaoke.name] <- false;
			allowed_activities[a_meeting.name] <- false;
			allowed_activities[a_park.name] <- false;
			allowed_activities[a_restaurant.name] <- false;
		}

		return (first(result));
	}

	Policy createPolicy (bool school, bool work) {
		create Policy returns: result {
			allowed_activities[a_school.name] <- school;
			allowed_activities[a_work.name] <- work;
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