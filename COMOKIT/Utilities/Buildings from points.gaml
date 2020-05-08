/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Kevin Chapuis
* Tags: covid19,epidemiology
******************************************************************/

model Buildingsfrompoints


global {
	
	string dataset_path <- "../External Datasets/Domiz - refugee camp/";
	
	// Blocks
	string building_blocks_file <- "Domiz_Shelters_block.shp";
	// Roads (to define block with when no one wants to digitalize the area)
	string roads_file;
	
	// Mandatory
	string building_points_file <- "Domiz_Shelters.shp";
	
	init {
		
		if file_exists(dataset_path+building_points_file) { create building_point from:shape_file(dataset_path+building_points_file,"EPSG:4326"); }
		else { error "Building points shapefile is mandatory"; }
		
		if file_exists(dataset_path+building_blocks_file) { create building_block from:shape_file(dataset_path+building_blocks_file,"EPSG:4326"); }
		
		write "There is "+length(building_block)+" building blocks";
		/* 
		ask building_point {
			building_block bb <- building_block closest_to self;
			write sample(bb.linked_points);  
			bb.linked_points <+ self;
			write sample(bb.linked_points);
		}
		write "There is "+length(building_point)+" building points ("+sum(building_block collect (length(each.linked_points)))+")";
		
		ask building_block {
			list<geometry> sub_blocks <- self.shape to_squares length(linked_points);
			create output_building from:sub_blocks;
		}
		* 
		*/
		
	}
	
}

species building_block {
	list<building_point> linked_points; 
	aspect default {draw shape color:#grey;}
}

species building_point {} 

species output_building {} 

experiment xp {
	output {
		display map type: opengl draw_env: false background: #black {
			//image (file_exists(dataset_path+"satellite.png") ? (dataset_path+"satellite.png"): "white.png")  transparency: 0.2;
			species building_block;
			species building_point;
		}
	}
}