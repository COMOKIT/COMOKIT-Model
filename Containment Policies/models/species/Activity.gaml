/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
* 
***/
model Species_Activity

import "Individual.gaml"
import "Building.gaml"

global {
	// A map of all possible activities
	map<string, Activity> Activities;

	action create_activities {
		loop s over: Activity.subspecies {
			create s returns: new_activity;
			Activities[string(s)] <- Activity(first(new_activity)) ;
		}

	}

}

species Activity {
	string type;
	bool chose_nearest <- false;
	int duration_min <- 1;
	int duration_max <- 8;
	int nb_candidat <- 3;
	list<Building> find_target (Individual i) {
		return nil;
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
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_shop) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_shop));
		}

	}

}

species a_market parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_market) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_market));
		}

	}

}

species a_supermarket parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_supermarket) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_supermarket));
		}

	}

}

species a_bookstore parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_bookstore) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_bookstore));
		}

	}

}

species a_movie parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_cinema) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_cinema));
		}

	}

}

species a_game parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_gamecenter) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_gamecenter));
		}

	}

}

species a_karaoke parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_karaoke) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_karaoke));
		}

	}

}

species a_restaurant parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_restaurant) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_restaurant));
		}

	}

}

species a_coffee parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_coffeeshop) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_coffeeshop));
		}

	}

}

species a_farm parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_farm) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_farm));
		} //TODO land parcel? 
	}

}

species a_trade parent: Activity {
	list<Building> building_outside_commune <- Building where !(each overlaps world.shape);
	list<Building> find_target (Individual i) {
		return nb_candidat among (building_outside_commune);
	}

}

species a_play parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_playground) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_playground));
		}

	}

}

species a_visit parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_hospital) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_hospital));
		}

	}

}

species a_collect parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_supplypoint) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_supplypoint));
		}

	}

}

species a_neighbours parent: Activity {
	list<Building> find_target (Individual i) {
		return [Building closest_to self];
	}

}

species a_friends parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (i.relatives collect (each.home));
	}

}

species a_park parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_park) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_park));
		}

	}

}

species a_meeting parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_meeting) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_meeting));
		}

	}

}

species a_spread parent: Activity {
	list<Building> find_target (Individual i) {
		return Building at_distance 5 #km;
	}

}

species a_repair parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = t_repairshop) closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = t_repairshop));
		}

	}

}



