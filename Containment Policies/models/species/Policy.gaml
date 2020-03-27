/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/

@no_experiment

model Policy

import "Individual.gaml"
species Policy {
	map<string, bool> allowed_activities;
	bool is_allowed (Individual i, Activity activity) {
		if (allowed_activities[species_of(activity).name] != nil) {
			return allowed_activities[species_of(activity).name];
		} else {
			return true;
		}

	}

}

species SpatialPolicy parent: Policy {
	geometry application_area;
	bool is_allowed (Individual i, Activity activity) {
		if (application_area overlaps i) {
			if (allowed_activities[species_of(activity).name] != nil) {
				return allowed_activities[species_of(activity).name];
			} else {
				return true;
			}

		}else{
			return true;
		}

	}

}