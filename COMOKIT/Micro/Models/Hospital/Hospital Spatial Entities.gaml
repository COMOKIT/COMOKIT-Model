/**
* Name: HospitalSpatialEntities
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


model HospitalSpatialEntities

import "Hospital Experiments.gaml"

global {
	action external_initilization {
		string beds_path <- dataset_path + "Beds.shp" ;
	
		create Bed from: file(beds_path) {
			my_room <- Room first_with (each.id = room_id);
		}
	}
	
}
species Bed {
	bool is_occupied <- false;
	Room my_room;
	int floor;
	int building;
	int room_id;
	
	rgb color <- #brown;
	aspect default {
		draw rectangle(people_size, 2) depth: 1 color: color;
	}
} 

