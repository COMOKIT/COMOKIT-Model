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
	
	int duration_min <- 1;
	int duration_max <- 8;
	int nb_candidat<-3;
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
		return nb_candidat among (Building where (each.type_activity = "shop"));
	}

}

species goToMarket parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "market"));
	}

}

species goToSuperMarket parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "supermarket"));
	}

}

species goToBookStore parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "bookstore"));
	}

}

species goToCinema parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "cinema"));
	}

}

species goToGameCenter parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "gamecenter"));
	}

}

species goToKaraoke parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "karaoke"));
	}

}

species goToRestaurant parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "restaurant"));
	}

}

species goToCoffee parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "coffeshop"));
	}

}

species goToFarm parent: Activity {
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "farm"));
		//TODO land parcel? 
	}

}

species exchangeProduct parent: Activity {
//	list<Building> outside_commune<-Building where
	list<Building> find_target (Individual i) {
		return nb_candidat among (Building where (each.type_activity = "coffeshop"));
	}

}

species kidsPlayingInTheStreet parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species visitSickPeopleAtHospital parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species takeSupplyProducts parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species visitNeighbors parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species visitRelativeOrFriends parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species goToThepark parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species publicmeeting parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species spreadingFlyers parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}

species repareHouse parent: Activity {
	list<Building> find_target (Individual i) {
		return [i.school];
	}

}


