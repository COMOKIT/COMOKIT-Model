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

import "../../Entities/Biological Entity.gaml"


global {
	action create_activities {
		map<string, list<Room>> rooms_type <- Room group_by each.type;
		sanitation_rooms <- rooms_type[sanitation];
		if (use_sanitation and not empty(sanitation_rooms)) {
			create BuildingSanitation with:[activity_places::sanitation_rooms];
		}

		create ActivityLeaveBuilding;
		create ActivityGoToOffice;
		create ActivityVisitInpatient;
		create ActivityGoToMeeting;
		create ActivityGoToAdmissionRoom;
	}
}

// A "singleton" species that provides the destination for different activities
species BuildingActivity virtual: true {
	list<Room> activity_places;
	
	pair<Room, point> get_destination(BuildingIndividual p) virtual: true;
}

species ActivityGoToOffice parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- p.working_place;
		point pt <- p.working_desk.location;
		return r::pt;
	}
}

species ActivityVisitInpatient parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		// Find a ward with at least 1 patient, and a new one if this visitor has just visited another ward 
		list<Room> wards <- Room where (
			each.type = WARD and each != p.dst_room and 
			!empty(each.people_inside where (species(each) = Inpatient))
		);
		if empty(wards) {
			error p.name + " is trying to visit an inpatient but there are none in any ward!";
		}
		Room r <- one_of(wards);

		// Select a patient to go near
		BuildingIndividual patient_to_visit <- one_of(r.people_inside where (species(each) = Inpatient));
		geometry area_around_patient <- circle(rnd(1#m, 2#m), patient_to_visit.location); 
		point pt <- any_location_in(inter(r, area_around_patient));

		return r::pt;
	}
}

species ActivityGoToAdmissionRoom parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- one_of(Room where (each.type = ADMISSION_ROOM));
		point pt <- any_location_in(r);
		return r::pt; 
	}
}

species ActivityGoToMeeting parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- first(Room where (each.type = MEETING_ROOM));
		point pt <- any_location_in(r);
		return r::pt; 
	}
}

species ActivityLeaveBuilding parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r <- BuildingEntrance closest_to p;
		point pt <- r.location;
		return r::pt; 
	}
}

species BuildingSanitation parent: BuildingActivity {
	pair<Room, point> get_destination(BuildingIndividual p) {
		Room r;
		if flip(0.3) {
			r <- shuffle(activity_places) with_min_of length(first(each.entrances).people_waiting);
		} else {
			r <- activity_places closest_to p;
		}
		point pt <- any_location_in(r);
		return r::pt;
	}
}
