/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Benoit Gaudou, Huynh Quang Nghi, Patrick Taillandier
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Building.gaml"

global {
	// A map of all possible activities
	map<string, Activity> Activities;
	
	action create_activities {
		
		// Create one Activity agent for each species inheriting from Activity
		loop s over: Activity.subspecies { 
			create s returns: new_activity;
			Activities[first(new_activity).name] <- Activity(first(new_activity)) ;
		}
		
		// Local variable sorting all the Building agents given their type
		map<string,list<Building>> buildings_per_activity <- Building group_by (each.type);
		
		// Create in addition one Activity species for each meta-type of Activity as defined in the activities map
		loop tb over: activities.keys { 
			create Activity with:[name::tb, types_of_building::activities[tb]] {
				Activities[tb] <-self ;
				loop type over: types_of_building {
					if (type in buildings_per_activity.keys) {
						buildings <- buildings + buildings_per_activity[type];
					}
				}
			}
		}	
	}
}

species Activity {
	list<string> types_of_building <- [];
	list<Building> buildings;
	bool chose_nearest <- false;
	int nb_candidat <- 3;
	
	list<Building> find_target (Individual i) {
		if flip(proba_go_outside) or  empty(buildings){
			return [the_outside];
		}
		if (chose_nearest) {
			return [buildings closest_to self];
		} else {
			return nb_candidat among buildings;
		}

	}

	aspect default {
		draw shape + 10 color: #black;
	}

} 

species visiting_neighbor parent: Activity {
	string name <- act_neighbor;
	list<Building> find_target (Individual i) {
		return i.bound.get_neighbors();
	}
}

species visiting_friend parent: Activity {
	string name <- act_friend;
	list<Building> find_target (Individual i) {
		return nb_candidat among (i.relatives collect (each.home));
	}
}

species working parent: Activity {
	string name <- act_working;
	list<Building> find_target (Individual i) {
		return [i.working_place];
	}

}

species studying parent: Activity {
	string name <- act_studying;
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species staying_home parent: Activity {
	string name <- act_home;
	list<Building> find_target (Individual i) {
		return [i.home];
	}
}
