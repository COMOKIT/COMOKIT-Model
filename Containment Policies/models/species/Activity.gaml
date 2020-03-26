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

species goToWork parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.office];
	}

}

species goToSchool parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species goBackHome parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.home];
	}

}

species goShopping parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "shop") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "shop"));
		}

	}

}

species goToMarket parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "market") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "market"));
		}

	}

}

species goToSuperMarket parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "supermarket") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "supermarket"));
		}

	}

}

species goToBookStore parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "bookstore") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "bookstore"));
		}

	}

}

species goToCinema parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "cinema") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "cinema"));
		}

	}

}

species goToGameCenter parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "gammecenter") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "gamecenter"));
		}

	}

}

species goToKaraoke parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "karaoke") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "karaoke"));
		}

	}

}

species goToRestaurant parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "restaurant") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "restaurant"));
		}

	}

}

species goToCoffee parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "coffeeshop") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "coffeeshop"));
		}

	}

}

species goToFarm parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "farm") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "farm"));
		} //TODO land parcel? 
	}

}

species exchangeProduct parent: Activity {
	list<Building> building_outside_commune <- Building where !(each overlaps world.shape);
	list<Building> find_target (Individual i) {
		return nb_candidat among (building_outside_commune);
	}

}

species kidsPlayingInTheStreet parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "playground") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "playground"));
		}

	}

}

species visitSickPeopleAtHospital parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "hospital") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "hospital"));
		}

	}

}

species takeSupplyProducts parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "supplypoint") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "supplypoint"));
		}

	}

}

species visitNeighbors parent: Activity {
	list<Building> find_target (Individual i) {
		return [Building closest_to self];
	}

}

species visitRelativeOrFriends parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (i.relatives collect (each.home));
	}

}

species goToThepark parent: Activity {
	list<Building> find_target (Individual i) {
		if (chose_nearest) {
			return [Building where (each.type_activity = "park") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "park"));
		}

	}

}

species publicmeeting parent: Activity {
	list<Building> find_target (Individual i) {

		if (chose_nearest) {
			return [Building where (each.type_activity = "meeting") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "meeting"));
		}	
	}

}

species spreadingFlyers parent: Activity {
	list<Building> find_target (Individual i) {
		return Building at_distance 5#km;
	}

}

species repareHouse parent: Activity {
	list<Building> find_target (Individual i) { 
		if (chose_nearest) {
			return [Building where (each.type_activity = "repare") closest_to self];
		} else {
			return nb_candidat among (Building where (each.type_activity = "repare"));
		}	
	}

}



