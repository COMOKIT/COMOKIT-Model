/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
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
}