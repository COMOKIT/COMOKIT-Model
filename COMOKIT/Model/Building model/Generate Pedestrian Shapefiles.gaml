/**
* Name: Generate Pedestrian Shapefiles
* Description: Adapted from 'Plugin models/Pedestrian Skill/models/Generate pedestrian paths.gaml'
* Author: minhduc0711
*/

model GeneratePedestrianShapefiles

global {
	shape_file walls_file <- file("../includes/walls.shp");
	shape_file closed_walls_file <- shape_file("../includes/closed_walls.shp");
	string output_dir <- "../generated/";
	
	bool display_free_space <- false parameter: true;
	float P_shoulder_length <- 0.2 parameter: true;
	
	float simplification_dist <- 0.5; //simplification distance for the final geometries
	bool add_points_open_area <- true;//add points to open areas
 	bool random_densification <- false;//random densification (if true, use random points to fill open areas; if false, use uniform points), 
 	float min_dist_open_area <- 0.1;//min distance to considered an area as open area, 
 	float density_open_area <- 0.01; //density of points in the open areas (float)
 	bool clean_network <-  true; 
	float tol_cliping <- 1.0; //tolerance for the cliping in triangulation (float; distance), 
	float tol_triangulation <- 0.1; //tolerance for the triangulation 
	float min_dist_obstacles_filtering <- 0.0;// minimal distance to obstacles to keep a path (float; if 0.0, no filtering),


	geometry open_area;
	geometry shape <- envelope(closed_walls_file);

	init {
		geometry room_geoms <- copy(shape);
		// Rooms need to be generated using closed walls (no doors)
		create Wall from: closed_walls_file;
		ask Wall {
			room_geoms <- room_geoms - (shape + P_shoulder_length);
		}
		//write(room_geoms.height);
		//write(room_geoms.width);
		create Room from: room_geoms.geometries;
		ask Room {
			if shape.area < 5 or shape.area > 1000 {
				do die;
			}
		}
		

		// Create walls with doors this time, in order to compute pedestrian paths
		ask Wall {
			do die;
		}
		create Wall from: walls_file;
		open_area <- copy(shape);
		ask Wall {
			open_area <- open_area - (shape + P_shoulder_length);
		}
		list<geometry> generated_lines <- generate_pedestrian_network([],[open_area],add_points_open_area,random_densification,min_dist_open_area,density_open_area,clean_network,tol_cliping,tol_triangulation,min_dist_obstacles_filtering,simplification_dist);
		create pedestrian_path from: generated_lines {
			do initialize bounds:[open_area] 
				distance: min(10.0, (Wall closest_to self) distance_to self) 
				masked_by: [Wall] distance_extremity: 1.0;
		}

		save Room type: shp to: output_dir + "unlabeled_rooms.shp";
		save pedestrian_path type: shp to: output_dir + "pedestrian_paths.shp";
		save open_area type: shp to: output_dir + "open_area.shp";
		save pedestrian_path collect each.free_space type: shp to: output_dir + "free_spaces.shp";
	} 

}

species Wall {
	aspect default {
		draw shape + P_shoulder_length color: #grey;
	}
}

species Room {
	rgb color <- rnd_color(255);
	aspect default {
		draw shape color: color;
	}
}

species pedestrian_path skills: [pedestrian_road]{
	rgb color <- rnd_color(255);
	aspect default {
		draw shape  color: color;
	}
	aspect free_area_aspect {
		if(display_free_space and free_space != nil) {
			draw free_space color: #cyan border: #black;
		}
	}
}

experiment Generate type: gui {
	output {
		display "My display" type: opengl {
	 		species Room;
			species Wall refresh: false;
//			graphics "open_area" {
//				draw open_area color: #lightpink;
//			}
//			species pedestrian_path aspect:free_area_aspect transparency: 0.5 ;
//			species pedestrian_path refresh: false;
			graphics "shape"{
				draw shape color: #grey;
			}

		}
	}
}
