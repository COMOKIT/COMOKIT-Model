/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Example of experiments with COMOKIT Building.
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/
model CoVid19



import "../Experiments/Abstract Experiment.gaml"

global {
	
	
	list<Room> available_rooms;
	map<string,rgb> room_type_color <- [RESTAURANT::#orange,OFFICE::#gray,MEETING_ROOM::#cyan];
	
	action create_individuals {
		available_rooms <- list(Room);
		create DefaultWorker number: 500;
		
	}

} 

 
 
experiment no_intervention type: gui parent: "Abstract Experiment"{
	
	action _init_
	{   
		create simulation ;
	}
	
	output {
		display building_map parent: map_global{}
		display map_1_floor type: opengl background: #black {
			camera #default dynamic: true target: selected_bd = nil ? world : selected_bd distance: distance_camera ;
			species Building ;
			species Room ;
			species Elevator ;
			species Wall;
			species DefaultWorker;
			
		}
		display evolution_chart parent:states_evolution_chart{}
		
	}
}
