/**
* Name: Buildingsfrompoints
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags: 
*/


model Buildingsfrompoints

/* Insert your model definition here */

global {
	
	string dataset_path <- "../External Datasets/Domiz - refugee camp/";
	
	// Blocks
	file building_blocks_file <- file(dataset_path+ "Domiz_Shelters_block.shp");
	file building_bounds_file <- file(dataset_path+ "boundary.shp");
	// Roads (to define block with when no one wants to digitalize the area)
	string roads_file;
	geometry shape <- envelope(building_bounds_file);
	// Mandatory
	file building_points_file <- file(dataset_path+ "Domiz_Shelters.shp");
	
	init {
		
		create building_point from:shape_file(building_points_file);
		create building_block from:shape_file(building_blocks_file);
		
		write "There is "+length(building_block)+" building blocks";
		
		ask building_point {
			building_block bb <- building_block closest_to self;  
			bb.linked_points <+ self;
		}
		write "There is "+length(building_point)+" building points ("+sum(building_block collect (length(each.linked_points)))+")";
		write sample(building_block(135))+" with "+length(building_block(135).linked_points)+" points inside";
		int count;
		ask building_block where not(empty(each.linked_points)) {
			list<geometry> sub_blocks <- self.shape to_squares length(linked_points);
			loop sb over:sub_blocks {create output_building with:[shape::sb];}
		}
		
	}
	
}

species building_block {
	list<building_point> linked_points; 
	aspect default {draw string(length(linked_points)) font:{10,0} color:#white; draw shape color:#grey;}
}

species building_point {} 

species output_building { aspect default {draw shape.contour color:#white;}} 

experiment xp {
	output {
		display map type: opengl draw_env: false background: #black {
			image (file_exists(dataset_path+"satellite.png") ? (dataset_path+"satellite.png"): "white.png")  transparency: 0.2;
			species output_building;
		}
	}
}