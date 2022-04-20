/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Rooms represent in COMOKIT spatial entities where Individuals gather 
* to undertake their Activities. They are provided with a viral load to
* enable environmental transmission. 
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/

@no_experiment

model CoVid19
 

import "BuildingIndividual.gaml"

import "../Parameters.gaml"


import "../Constants.gaml"
 
species Outside parent: AbstractPlace;
	
species Room parent: AbstractPlace {
	string type;
	int building;
	int floor;
	int id;
	rgb color <- #lightgray;
	
	Building my_building;
	list<RoomEntry> entrances;
	
	
	float ceiling_height <- 3#m;
	
	aspect default {
		if (building = building_map) and (floor = floor_map) {
			draw shape color: color;
		}
	
	}
	
	aspect viral {
		draw shape color: rgb(255 * sum(viral_load.values),255 * (1 - sum(viral_load.values)), 0 );
	}
	
}




species Building {
	int nb_floors;
	list<BuildingEntry> entrances;
	map<int,list<Room>> rooms;
	map<int,list<Elevator>> elevators;
	map<int,list<BuildingIndividual>> people;
 
	user_command action: select_command;
 	
 	action select_command {
 		selected_bd <- self;
 		building_map <- int(self);
 		map  result <- user_input_dialog("Selection of a floor",[choose("Floor to inspect",int,0, rooms.keys)]);
 		floor_map <- int(result["Floor to inspect"]);
			
 	}
	aspect draw_infected {
		loop i over: people.keys {
			list<BuildingIndividual> inds <- people[i];
			float rate <- empty(inds) ? 0.0 : ((inds count each.is_infected) / length(inds)); 
			rgb col <- rgb(rate *255,255 * (1 - rate),0);
			draw shape color: col at: location + {0,0,i * floor_high} depth: floor_high;
		}
		
	}
	 
	aspect default {
		if int(self) = building_map {
			draw shape color: #pink;
		}
		
	}
}	


	
species AreaEntry parent: Room{
	rgb color <- #blue;
	string type <- "exit";
	Building my_building <- nil;
	list<RoomEntry> entrances <- nil;
	int floor <- 0;
	int building <- -1;
	
	
	reflex update_viral_load {}
}
	
species OpenArea{
	rgb color <- rnd_color(255);
	int floor;
	int building;
	aspect default {
		draw shape  color: color;
	}
}


species PedestrianPath{
	rgb color <- rnd_color(255);
	int floor;
	int building;
	float area;
	float coeff min: 0.1;
	float density;
	int nb_people;
	float surface;
	bool update_coeff <- false update: false;
	
	action coeff_computation {
		coeff <- density = 0.0 ? 1.0 : (1 - exp(- lambda  * (1 / density - 1/density_max_admi)));
	}
	
	
	aspect default {
		draw shape  color: color;
	}
}


species Wall {
	int floor;
	int building;
	
	aspect default {
		
		if (building = building_map) and (floor = floor_map) {
			draw shape  color: #lightgray border: #black;
		}
	}
}



species RoomEntry {
	int room_id;
	int floor;
	
	Room my_room;
	aspect default {
		draw shape color: #cyan ;
	}
}

species BuildingEntry {
	int building;
	Building my_building;
	aspect default {
		draw shape color: #magenta ;
	}
}
 

species Elevator parent: Room {
	aspect default {
		if (building = building_map) and (floor = floor_map) {
		
			draw shape color: #gold ;
			
		}
	}
}


// TODO: viral_load is now a map
species unit_cell parent: AbstractPlace  schedules: unit_cell where (each.viral_load[original_strain] > 0) {
	bool allow_transmission -> {allow_local_transmission};
	float viral_decrease -> {basic_viral_local_decrease_per_day };
	int building;
	int floor;
	aspect default{
		draw shape color:blend(#green, #red, 1 - (coeff_visu_virus_load_cell * viral_load[original_strain]))  ;	
		
	}
}