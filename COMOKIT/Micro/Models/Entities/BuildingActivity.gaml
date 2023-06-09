/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* An activity that can perform in a building.
* 
* Author:Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19
 
import "BuildingIndividual.gaml"

import "../Constants.gaml"

import "Building Spatial Entities.gaml"


global {
	action create_activities {
		loop i over: BuildingActivity.subspecies{
			create i;
			loop k over: species(i).subspecies {
				create k;
			}
		}
	}
	
}

// A "singleton" species that provides the destination for different activities
species BuildingActivity virtual: true {
	list<Room> activity_places;
	float wandering_in_room <- -1.0;
	bool can_be_advanced <- true;
	map get_destination(BuildingIndividual p) virtual: true;
	
	Room selectedRoom(list<Room> possible_rooms) {
		if min_distance_between_people > 0  {
			list<Room> free_rooms <- possible_rooms where (not each.compute_geom_free or (each.geom_free != nil and each.geom_free.area > 0));
			if empty(free_rooms) {
				return one_of(possible_rooms);
			}
			else {
				return one_of(free_rooms);
			}
		}
		return one_of(possible_rooms);
	}
	
}


species ActivityLeaveArea parent: BuildingActivity {
	map get_destination(BuildingIndividual p) {
		map results;
		AreaEntry ea <- AreaEntry closest_to p;
		if (ea = nil) {
			ea <- AreaEntry with_min_of (each distance_to self);
		}
		results[key_room] <- ea;
		return results; 
	}
}

species ActivityGoToOffice parent: BuildingActivity {
	map get_destination(BuildingIndividual p) {
		DefaultWorker w <- DefaultWorker(p);
		Room r <- w.working_place;
		map results;
		results[key_room] <- r;
		return results; 
	}
}


species ActivityGotoRestaurant parent: BuildingActivity {
	bool can_be_advanced <- false;
	
	map get_destination(BuildingIndividual p) {
		if (min_distance_between_people > 0 ) {
			
		}
		Room r <- one_of(Room where (each.type = RESTAURANT));
		map results;
		results[key_room] <- r;
		return results; 
	}
}



species ActivityGotoRoom parent: BuildingActivity {
	bool same_building_if_possible <- true;
	bool same_floor_if_possible <- true;
	bool closest <-false;
	string type <-nil;
	map get_destination(BuildingIndividual p) {
		map results;
		Room a_room <- choose_room(p);
		results[key_room] <- a_room;
		return results; 
	}
	
	Room choose_room(BuildingIndividual p) {
		Room r <- nil;
		bool same_floor_if_possible_tmp <- same_floor_if_possible;
		bool same_building_if_possible_tmp <- same_building_if_possible;
		loop while: r = nil {
			list<Room> possible_rooms;
			if (same_floor_if_possible_tmp) and p.current_building != nil {
				possible_rooms <- p.current_building.rooms[p.current_floor];
				if type != nil {possible_rooms <- possible_rooms where (each.type = type);}
				same_floor_if_possible_tmp <- false;
			} else if (same_building_if_possible_tmp) and p.current_building != nil {
				possible_rooms <- (p.current_building.rooms accumulate each);
				if type != nil {possible_rooms <- possible_rooms where (each.type = type);}
				same_building_if_possible_tmp <- false;
			} else {
				possible_rooms <- type != nil ? (Room where (each.type = type)) :(list(Room));
				if empty(possible_rooms) {return nil;}
			} 
			if not empty(possible_rooms) {
				return closest ? possible_rooms closest_to self : one_of(possible_rooms);
			}
		}
	}
}
