/**
* Name: generatingroomsfromwalls
* Generate a shapefile of rooms from walls 
* Author: Patrick Taillandier
* Tags: 
*/

model generatingbuildingfromwalls

global {
	
	shape_file buildings_lines_shape_file <- shape_file("../../Datasets/Danang Hospital/buildings_lines.shp");
	shape_file areas_lines_shape_file <- shape_file("../../Datasets/Danang Hospital/areas_lines.shp");
	shape_file roads_lines_shape_file <- shape_file("../../Datasets/Danang Hospital/roads_lines.shp");

	geometry shape <-areas_lines_shape_file = nil ? envelope(buildings_lines_shape_file) : envelope(envelope(buildings_lines_shape_file) + envelope(areas_lines_shape_file)) ;
	map<string, rgb> color_per_type;
	
	init {
		create wall from: buildings_lines_shape_file;
		create wall from: areas_lines_shape_file;
		
		geometry area <- copy(shape);
		ask wall {
			area <- area - (shape + 0.1);
		}
		
		create building from: area.geometries {
			if (shape.area/convex_hull(self).area < 0.6) {
				do die;
			}
		}
		
		save building to:"../../Datasets/Danang Hospital/buildingss.shp" type: shp;
	}
	
}

species wall {
	
	aspect default {
		draw shape color: #red; 
	}
	
}

species building {
	string type;
	
	
	aspect default {
		draw shape color: type in color_per_type.keys ? color_per_type[type] : #lightgray border: #black; 
	}
	
}
experiment generate_building type: gui {
	output {
		display map {
			species wall;
			species building;
		}
		
	}
}
