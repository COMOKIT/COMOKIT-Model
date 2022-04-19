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
	rgb color <- #gray;
	
	Building my_building;
	list<RoomEntry> entrances;
	
	
	float ceiling_height <- 3#m;
	
	aspect default {
		draw shape color: color;
	}
	
}




species Building {
	int nb_floors;
	list<BuildingEntry> entrances;
	map<int,list<Room>> rooms;
	map<int,list<Elevator>> elevators;
	aspect default {
		draw shape color: #pink;
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
	
	aspect default {
		draw shape  color: #lightgray border: #black;
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
		draw shape color: #red ;
	}
}


// TODO: viral_load is now a map
species unit_cell parent: AbstractPlace  schedules: unit_cell where (each.viral_load[original_strain] > 0) {
	bool allow_transmission -> {allow_local_transmission};
	float viral_decrease -> {basic_viral_local_decrease_per_day };
	int building;
	int floor;
	aspect default{
		if (display_infection_grid){
			//TODO: viral_load is now a map
			draw shape color:blend(#green, #red, 1 - (coeff_visu_virus_load_cell * viral_load[original_strain]))  ;	
		}
	}
}