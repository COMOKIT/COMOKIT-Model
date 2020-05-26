/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Declares the species and its sub-species representing the activities
* undertaken by Individuals. Associated actions are also declared in this file.
* 
* Author: Benoit Gaudou, Huynh Quang Nghi, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

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
						buildings[type] <-  buildings_per_activity[type];
					} 
				}
				
			}
		}
		
		if (csv_building_type_weights != nil) {
			weight_bd_type_per_age_sex_class <- [];
			matrix data <- matrix(csv_building_type_weights);
			list<string> types;
			loop i from: 3 to: data.columns - 1 {
				types <<string(data[i,0]);
			}
			loop i from: 1 to: data.rows - 1 {
				list<int> cat <- [ int(data[0,i]),int(data[1,i])];
				map<int,map<string, float>> weights <- (cat in weight_bd_type_per_age_sex_class.keys) ? weight_bd_type_per_age_sex_class[cat] : map([]);
				int sex <- int(data[2,i]);
				map<string, float> weights_sex;
				loop j from: 0 to: length(types) - 1 {
					weights_sex[types[j]] <- float(data[j+3,i]); 
				}
				
				weights[sex] <- weights_sex;
				weight_bd_type_per_age_sex_class[cat] <- weights;
			}
		}
		list<string> existing_bd_type;
		loop type over: weight_bd_type_per_age_sex_class.values {
			loop type_s over: type.values {
				existing_bd_type <- existing_bd_type + type_s.keys;
			}
		}
		existing_bd_type <- remove_duplicates(existing_bd_type);
		ask Activity {
			types_of_building <- types_of_building where ((each in existing_bd_type) or (each in buildings.keys));
		}
				
	}
	
	string building_type_choice(Individual ind, list<string> possible_building_types) {
		if (weight_bd_type_per_age_sex_class = nil ) or empty(weight_bd_type_per_age_sex_class) {
			return any(possible_building_types);
		}
		loop a over: weight_bd_type_per_age_sex_class.keys {
			if (ind.age >= a[0]) and (ind.age <= a[1]) {
				map<string, float> weight_bds <-  weight_bd_type_per_age_sex_class[a][ind.sex];
				list<float> proba_bds <- possible_building_types collect ((each in weight_bds.keys) ? weight_bds[each]:1.0 );
				if (sum(proba_bds) = 0) {return any(possible_building_types);}
				return possible_building_types[rnd_choice(proba_bds)];
			}
		}
		return any(possible_building_types);
		
	}
}

species Activity {
	list<string> types_of_building <- [];
	map<string,list<Building>> buildings;
	
	map<Building,list<Individual>> find_target (Individual i) {
		if not empty(i.activity_fellows ) {
			Individual fellow <- i.activity_fellows first_with (each.last_activity = self);
			if (fellow!= nil) {
				return [fellow.current_place::[]];
			} 
		}
		if flip(proba_go_outside) {
			return [the_outside::[]];
		}
		string type <- world.building_type_choice(i,types_of_building);
		list<Building> bds <- buildings[type];
		if (empty(bds)) {
			return [the_outside::[]];
		}	
		switch choice_of_target_mode {
			match closest {
				return [bds closest_to self::[]];
			}
			match gravity {
				return i.building_targets[self][type] as_map (each::[]);
			}
			match random {
				return (nb_candidates among bds) as_map(each::[]);
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
			if (i != nil) {
				targets[neigh] <- i.relatives + i;
			}
			
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
