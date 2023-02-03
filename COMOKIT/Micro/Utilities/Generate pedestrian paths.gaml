/***
* Name: generate_pedestrian_path
* Author: Patrick Taillandier
* Description: Show how to create pedestrian path and associated free space
* Tags: * Tags: pedestrian, gis, shapefile, graph, agent_movement, skill, transport
***/

model generate_pedestrian_path

import "../Models/Constants.gaml"


global {
	
	string name_of_dataset <- "LFAY";
	string project_path <- "..";
	string dataset_path <- project_path +"/Datasets/" + name_of_dataset;
	string obstacles_path <- dataset_path + "/Walls.shp";
	string rooms_path <- dataset_path + "/Rooms.shp";
	
	geometry shape <- envelope(obstacles_path);
	bool display_free_space <- false parameter: true;
	float P_shoulder_length <- 0.45 parameter: true;
	float min_open_area <- 5.0;
	float simplification_dist <- 0.5; //simplification distance for the final geometries
	
	bool add_points_open_area <- true;//add points to open areas
 	bool random_densification <- false;//random densification (if true, use random points to fill open areas; if false, use uniform points), 
 	float min_dist_open_area <- 0.1;//min distance to considered an area as open area, 
 	float density_open_area <- 0.05; //density of points in the open areas (float)
 	bool clean_network <-  true; 
	float tol_cliping <- 0.1; //tolerance for the cliping in triangulation (float; distance), 
	float tol_triangulation <- 0.01; //tolerance for the triangulation 
	float min_dist_obstacles_filtering <- 0.0;// minimal distance to obstacles to keep a path (float; if 0.0, no filtering), 
	
	
	action process_data {
		create Wall from:file(obstacles_path);
		do generate_path(shape,Wall as list,-1,0);
		save OpenArea type: shp to: dataset_path+"/open area.shp" attributes: ["building", "floor"];
		save PedestrianPath type: shp to: dataset_path+"/pedestrian paths.shp" attributes: ["building", "floor", "area"];
	}
	
	init {
		do process_data;
	}
	
	list<list<agent>> generate_path(geometry consider_geom, list<geometry> obstacles, int id_bd, int id_floor) {
		geometry open <- copy(consider_geom);
		loop g over: obstacles {
			open <- open -(g buffer (P_shoulder_length/2.0));
		}
		if open != nil and open.area > min_open_area {
			create OpenArea from: open.geometries with: (building:id_bd, floor:id_floor) returns: oa;
			list<geometry> generated_lines <- generate_pedestrian_network([],open.geometries,add_points_open_area,random_densification,min_dist_open_area,density_open_area,clean_network,tol_cliping,tol_triangulation,min_dist_obstacles_filtering,simplification_dist);
			write sample(length(generated_lines));
			create PedestrianPath from: generated_lines with: (building:id_bd, floor:id_floor)  returns: pp{
				area <- min(10.0,(Wall closest_to self) distance_to self) * shape.perimeter;
				
			}
			return [oa,pp];
		}
		return [];
		
		
	}
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
	aspect default {
		draw shape  color: color;
	}
}


species Wall {
	int floor;
	int building;
	aspect default {
		draw shape + (P_shoulder_length/2.0) color: #gray border: #black;
	}
}


