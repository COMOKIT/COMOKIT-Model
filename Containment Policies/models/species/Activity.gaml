/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
* 
***/

@no_experiment

model Species_Activity

import "../Global.gaml"

import "Individual.gaml"
import "Building.gaml"


global {
	// A map of all possible activities
	map<string, Activity> Activities;
	map<string,list<Building>> buildings_per_activity;
	action create_activities {
		loop s over: Activity.subspecies { 
			create s returns: new_activity;
			Activities[string(s)] <- Activity(first(new_activity)) ;
		}
		buildings_per_activity <- Building group_by (each.type_activity);
		buildings_per_activity["outside"] <-  Building where !(each overlaps world.shape);
		
		
	}

}

species Activity {
	string type_of_building <- nil;
	bool chose_nearest <- false;
	int duration_min <- 1;
	int duration_max <- 8;
	int nb_candidat <- 3;
	
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [buildings_per_activity[type_of_building] closest_to self];
		} else {
			return nb_candidat among buildings_per_activity[type_of_building];
		}

	}

	aspect default {
		draw shape + 10 color: #black;
	}

} 

species a_work parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.office];
	}

}

species a_school parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species a_home parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.home];
	}

}
	
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

species a_trade parent: Activity {
	string type_of_building <- "outside";
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

species a_neighbours parent: Activity {
	
	list<Building> find_target (Individual i) {
		return i.bound.get_neighbors();
	}

}

species a_friends parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (i.relatives collect (each.home));
	}

}

species a_park parent: Activity {
	string type_of_building <- t_park;
}

species a_meeting parent: Activity {
	string type_of_building <- t_meeting;
}

species a_spread parent: Activity {
	list<Building> find_target (Individual i) {
		return list(Building) - i.bound;
	}

}

species a_repair parent: Activity {
	string type_of_building <- t_repairshop;
}



