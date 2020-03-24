/***
* Name: Countries
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Countries

/* Insert your model definition here */

global {
	
	// GIS ----------------
	shape_file the_world <- shape_file("../includes/Countries_WGS84.shp","EPSG:3395");
	geometry shape <- envelope(the_world);
	
	// Demographics -------
	file world_pop <- file("../includes/popWorld.csv");
	file world_pop_age <- file("../includes/popWorld_age.csv"); 
	
	float pop_scale <- 1/1000;
	float max_pop;
	float min_pop;
	
	list<string> age_ranges <- [
		"0-4","5-9","10-14","15-19","20-24","25-29","30-34",
		"35-39","40-44","45-49","50-54","55-59","60-64","65-69","70-74","75-79",
		"80-84","85-89","90-94","95-99","100+"
	];
	int max_age <- 130;
	
	// Other --------------
	
	list<rgb> demo_palette <- [rgb(255,255,178),rgb(254,217,118),rgb(254,178,76),
		rgb(253,141,60),rgb(240,59,32),rgb(189,0,38)
	];
	
	// INIT ---------------
	init {
		matrix pop_data <- matrix(world_pop);
		matrix popage_data <- matrix(world_pop_age);
		create country from:the_world with:[color::#gray] {
			shape <- simplification(shape,0.05);
		}
		loop i from: 1 to: pop_data.rows -1{
			country c <- country first_with (each.CNTRY_NAME = pop_data[1,i]);
			if c!=nil {c.pop <- pop_data[8,i];}
		}	
		loop i from: 1 to: popage_data.rows-1 {
			country c <- country first_with (each.CNTRY_NAME = popage_data[1,i]);
			if c!=nil {c.pop_age[get_age_range(popage_data[6,i])] <- popage_data[11,i];}
		}
		min_pop <- min(country collect (each.pop));
		max_pop <- max(country collect (each.pop));
		ask country {
			if pop = 0 {demo_color <- #white;}
			else {demo_color <- world.get_rgb_palette(demo_palette, min_pop, max_pop, pop);}
		}
	}
	
	/*
	 * Returns proper range encoding from string
	 */
	point get_age_range(string range){
		if range contains "+" {
			return {int(replace(range,"+","")),max_age};
		} else {
			list<string> split <- range split_with "-";
			return {int(split[0]),int(split[1])};
		}
	} 
	
	/*
	 * Transposes a value into color taken from a palette
	 */
	rgb get_rgb_palette(list<rgb> palette, float min, float max, float value, 
		bool log <- true, float epsilon <- 1/100000
	){
		float p_value <- (log ? ln(value)/ln(max) : (value-min) / (max-min)) * (length(palette)-1);
		float relica <- abs(p_value - round(p_value));  
		if relica <= epsilon { return palette[round(p_value)]; }
		int min_bound <- int(p_value);
		int max_bound <- round(p_value) = min_bound ? round(p_value)+1 : round(p_value);
		return blend(palette[min_bound],palette[max_bound],1-relica);
	}
}

species country {
	string CNTRY_NAME;
	float pop;
	map<point,float> pop_age;
	
	rgb color;
	rgb demo_color;
	
	aspect population {
		draw shape color: demo_color border:#black;
	}
}

experiment pandemic type:gui {
	output {
		display world type:java2D {
			species country aspect:population;
		}
	}
}