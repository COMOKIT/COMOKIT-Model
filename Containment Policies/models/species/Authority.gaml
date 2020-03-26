/***
* Name: Authority
* Author: drogoul
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Authority

import "Policy.gaml"

/* Describes the main authority in charge of the health policies to implement */
species Authority {
	list<Policy> policies;
	Policy lockDown <- createPolicy(false, false);
	Policy noContainment <- createPolicy(true, true);
	Policy noSchool <- createPolicy(false, true);


	Policy createPolicy (bool school, bool work) {
		create Policy returns: result {
			allowed_activities[a_school.name] <- false;
			allowed_activities[a_work.name] <- false;
		}

		return Policy(result);
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