/***
* Name: Countries
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Countries

/* Insert your model definition here */

global {
	
	shape_file the_world <- shape_file("../includes/Countries_WGS84.shp","EPSG:3395");
	file world_pop <- file("../includes/popWorld.csv");
	file world_pop_age <- file("../includes/popWorld_age.csv"); 
	geometry shape <- envelope(the_world);
	
	float pop_scale <- 1/1000;
	
	init {
		matrix pop_data <- matrix(world_pop);
		create country from:the_world with:[color::#gray] {
			shape <- simplification(shape,0.05);
		}
		loop i from: 1 to: pop_data.rows -1{
			loop j from: 0 to: pop_data.columns -1{
				country c <- country first_with (each.CNTRY_NAME = pop_data[1,i]);
				if c!=nil {c.pop <- pop_data[8,i];}
			}	
		}	
	}
	
}

species country {
	string CNTRY_NAME;
	float pop;
	map<point,float> pop_age;
	rgb color;
}

experiment pandemic type:gui {
	output {
		display world type:java2D {
			species country;
		}
	}
}