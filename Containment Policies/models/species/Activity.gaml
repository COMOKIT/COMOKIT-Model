/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
* 
***/

@no_experiment

model Species_Activity

import "../Constants.gaml"

import "../Global.gaml"

import "Individual.gaml"
import "Building.gaml"


global {
	// A map of all possible activities
	map<string, Activity> Activities;
	
	action create_activities {
		
		loop s over: Activity.subspecies { 
			create s returns: new_activity;
			Activities[first(new_activity).name] <- Activity(first(new_activity)) ;
		}
		map<string,list<Building>> buildings_per_activity <- Building group_by (each.type);
		
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
	int duration_min <- 1;
	int duration_max <- 8;
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
/*
species a_shop parent: Activity {
	string type_of_building <- t_shop;
}

species a_market parent: Activity {
	string type_of_building <- t_market;
}

species a_supermarket parent: Activity {
	string type_of_building <- t_supermarket;
}

species a_bookstore parent: Activity {
	string type_of_building <- t_bookstore;
}

species a_movie parent: Activity {
	string type_of_building <- t_cinema;
}

species a_game parent: Activity {
	string type_of_building <- t_gamecenter;
}

species a_karaoke parent: Activity {
	string type_of_building <- t_karaoke;
}

species a_restaurant parent: Activity {
	string type_of_building <- t_restaurant;
}

species a_coffee parent: Activity {
	string type_of_building <- t_coffeeshop;
}

species a_farm parent: Activity {
	string type_of_building <- t_farm;
}

species a_play parent: Activity {
	string type_of_building <- t_playground;
}

species a_visit parent: Activity {
	string type_of_building <- t_hospital;
}

species a_collect parent: Activity {
	string type_of_building <- t_supplypoint;
}

species a_sport parent: Activity {
	string type_of_building <- t_sport;
}



species a_admin_task parent: Activity {
	string type_of_building <- t_admin;
}

species a_park parent: Activity {
	string type_of_building <- t_park;
}

species a_workship_place parent: Activity {
	string type_of_building <- t_place_of_worship;
}

species a_meeting parent: Activity {
	string type_of_building <- t_meeting;
}

species a_repair parent: Activity {
	string type_of_building <- t_repairshop;
}
 */


