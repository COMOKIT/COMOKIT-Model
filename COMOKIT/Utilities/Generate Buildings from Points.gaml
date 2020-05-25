/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* A global model that generates buildings from  a shapefile of points.
* 
* Author: Kevin Chapuis, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

model Buildingsfrompoints

/*
 * TODO: add the ability to generate building from a shapefile of roads with arbitrary parameter to
 * generate building along the roads
 */
global {
	
	// MANDATORY : The path to your data set with boundary shape
	string dataset_path <- "../External Datasets/MY_DATASET/";
	
	file building_bounds_file <- file(dataset_path+ "boundary.shp");
	geometry shape <- envelope(building_bounds_file);
	
	// OPTIONAL : Blocks of building
	file building_blocks_file <- file(dataset_path+ "MY_DATASET_BLOCKS.shp");
	// OPTIONAL : TODO - Roads (to define block with when no one wants to digitalize the area)
	string roads_file;
	
	// OPTIONAL POINT LOCATIONS : the set of point locations for building
	file building_points_file <- file(dataset_path+ "MY_DATASET_POINTS.shp");
	
	// Parameter to choose to fit inside or overflows outside building_blocks_file
	bool overflow <- false;
	
	// Output
	string output_building_file_path <- dataset_path+"buildings.shp";
	
	// Debug mode
	bool DEBUG <- true;
	
	init {
		
		create building_point from:shape_file(building_points_file);
		create building_block from:shape_file(building_blocks_file);
		
		if file_exists(dataset_path+"satellite.png") { write "background image should be ok";}
		
		if DEBUG {write "There is "+length(building_block)+" building blocks";}
		
		ask building_point {
			building_block bb <- one_of(building_block overlapping self);
			if bb=nil { bb <- building_block with_min_of (each.shape.centroid distance_to self); }  
			bb.linked_points <+ self;
		}
		
		if DEBUG {write "There is "+length(building_point)+" building points ("+(building_block sum_of (length(each.linked_points)))+")";}
		
		ask building_block where not(empty(each.linked_points)) {
			list<geometry> sub_blocks <- self.shape to_squares (length(linked_points),overflow);
			if length(sub_blocks) < length(linked_points) {
				error "Does not create the proper number of building from points";
			} 
			loop pt over: linked_points {
				geometry sub_block <- sub_blocks with_min_of (each.centroid distance_to pt);
				sub_blocks >> sub_block;
				create output_building with: [shape::sub_block, related::pt] {
					loop k over: related.shape.attributes.keys {
						shape.attributes[k] <- related.shape.attributes[k];
					}
				}
			}
			 
		}
		list<string> atts <- first(building_point).shape.attributes.keys; 
			
		if DEBUG {
			write "Attributes to save:" + atts;
		}
		
		
		save (output_building collect each.shape) to:output_building_file_path type:shp attributes:atts;		
	}
	
}

/*
 * The species that represents building blocks
 */
species building_block {
	list<building_point> linked_points; 
	aspect default {draw shape color:#grey; draw string(length(linked_points)) at:shape.centroid font:font(5) color:#white;}
}

/*
 * The species that represents point location of building 
 */
species building_point { aspect default {draw circle(1) color:#red;}} 

/*
 * The generated output building
 */
species output_building {
	building_point related; 
	aspect default {draw shape.contour buffer 1 color:#white;}
} 

/*
 * Display output for debug and verification
 */
experiment xp {
	output {
		display map type: opengl draw_env: false background: #black {
			image (file_exists(dataset_path+"satellite.png") ? (dataset_path+"satellite.png"): "white.png")  transparency: 0.2;
			species building_block;
			species output_building;
			species building_point;
		}
	}
}