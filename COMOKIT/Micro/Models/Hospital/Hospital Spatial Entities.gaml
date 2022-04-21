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
		ask Room {
			if type in room_type_color.keys {
				color <- room_type_color[type];
			}
		}
		string beds_path <- dataset_path + "Beds.shp" ;
	
		create Bed from: file(beds_path) {
			my_room <- Room first_with (each.id = room_id);
			location <- location + {0,0, floor * floor_high};
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
		if (building = building_map) and (floor = floor_map) {
			draw shape depth: 0.5 color: color;
		}
	}
} 

