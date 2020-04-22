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
	
	map<Building,list<Individual>> find_target (Individual i) {
		if flip(proba_go_outside) or  empty(buildings){
			return [the_outside::[]];
		}
		if not empty(i.activity_fellows ) {
			Individual fellow <- i.activity_fellows first_with (each.last_activity = self);
			if (fellow!= nil) {
				return [fellow.current_place::[]];
			} 
		}
		switch choice_of_target_mode {
			match closest {
				return [buildings closest_to self::[]];
			}
			match gravity {
				return i.building_targets[self] as_map (each::[]);
			}
			match random {
				return (nb_candidates among buildings) as_map(each::[]);
			}
		}
	}

	aspect default {
		draw shape + 10 color: #black;
	}

} 

species visiting_neighbor parent: Activity {
	string name <- act_neighbor;
	map<Building,list<Individual>> find_target (Individual i) {
		map<Building,list<Individual>> targets;
		loop neigh over: i.current_place.get_neighbors() where not empty(each.individuals) {
			Individual i <- one_of(neigh.individuals);
			targets[neigh] <- i.relatives + i;
		}
		return targets;
	}
}

species visiting_friend parent: Activity {
	string name <- act_friend;
	map<Building,list<Individual>> find_target (Individual i) {
		map<Building,list<Individual>> targets;
		loop friend over: (i.friends where each.is_at_home) {
			targets[i.home] <- i.relatives + i;
		}
		return targets;
	}
}

species working parent: Activity {
	string name <- act_working;
	map<Building,list<Individual>> find_target (Individual i) {
		return [i.working_place::i.colleagues];
	}

}

species studying parent: Activity {
	string name <- act_studying;
	map<Building,list<Individual>> find_target (Individual i) {
		return [i.school::i.colleagues];
	}

}

species staying_home parent: Activity {
	string name <- act_home;
	map<Building,list<Individual>> find_target (Individual i) {
		return [i.home::i.relatives];
	}
}
