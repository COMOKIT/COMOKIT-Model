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
	//shape_file the_world <- shape_file("../includes/world_pseudo_mercator.shp");
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
	
	// Mobility -----------
	
	csv_file mob_meta <- csv_file("../includes/KCMD_DDH_meta_KCMD-EUI GMP_ Estimated trips.csv");
	int meta_header <- 6;
	
	map<string,string> code_to_country;
	csv_file mob_data <- csv_file("../includes/KCMD_DDH_data_KCMD-EUI GMP_ Estimated trips.csv");
	list<int> mob_years <- [2011,2012,2013,2014,2015,2016];
	
	map<int,int> max_mobility;
	graph mobility_graph <- spatial_graph([]);
	
	// Other --------------
	
	list<rgb> demo_palette <- [rgb(255,255,178),rgb(254,217,118),rgb(254,178,76),
		rgb(253,141,60),rgb(240,59,32),rgb(189,0,38)
	];
	
	// INIT ---------------
	init {
		matrix pop_data <- matrix(world_pop);
		matrix popage_data <- matrix(world_pop_age);
		
		// Simplify boarders for faster computation
		create country from:the_world with:[color::#gray] {
			shape <- simplification(shape,0.05);
		}
		
		// Match demographic data with GIS countrie' objects
		// TODO : their is still not Taiwan population
		loop i from: 0 to: pop_data.rows -1{
			country c <- country first_with (each.CNTRY_NAME = pop_data[1,i]);
			if c!=nil {c.pop <- pop_data[8,i];}
		}	
		loop i from: 0 to: popage_data.rows-1 {
			country c <- country first_with (each.CNTRY_NAME = popage_data[1,i]);
			if c!=nil {c.pop_age[get_age_range(popage_data[6,i])] <- popage_data[11,i];}
		}
		
		// Read meta data mobilities
		matrix meta_mat <- matrix(mob_meta);
		loop i from: meta_header to: meta_mat.rows-1 {
			string code <- meta_mat[0,i];
			string cntr <- replace(string(meta_mat[1,i]),'"',"");
			code_to_country[code] <- cntr;
			country bc <- country first_with (each.CNTRY_NAME=cntr);
			if bc!=nil { bc.mob_code <- code; }
		}
		
		// Error message when travel data have not been retrieve for a country
		if country one_matches (each.mob_code=nil or each.mob_code="") { 
			list<country> cs <- country where (each.mob_code=nil or each.mob_code="");
			write "List of unkown country mobility: "+sample(cs collect (each.CNTRY_NAME));
			error "There is "+length(cs)+" countries without mobility code";
		}
		
		// Read trans-border mobilities and bound them to countries
		matrix data_mat <- matrix(mob_data);
		loop i from:0 to:data_mat.rows-1 step:length(mob_years) {
			country reporting <- country first_with (each.mob_code=data_mat[0,i]);
			country secondary <- country first_with (each.mob_code=data_mat[1,i]); 
			if reporting!=nil and secondary!=nil {
				loop j from:0 to:length(mob_years)-1 {
					reporting.mobility_map[mob_years[j]][secondary] <- data_mat[3,i+j]; 
				}
			}
		}
		
		// Build mobility graph
		do build_mobility_graph(last(mob_years));
		
		// Assigne color to country for population
		min_pop <- min(country collect (each.pop));
		max_pop <- max(country collect (each.pop));
		ask country {
			if pop = 0 {demo_color <- #white;}
			else {demo_color <- world.get_rgb_palette(demo_palette, min_pop, max_pop, pop);}
		}
		
	}
	
	action build_mobility_graph(int year) {
		ask country { mobility_graph <- mobility_graph add_node self; }
		map<pair<point,point>,int> mobility_weights;
		ask country { 
			loop linked over:mobility_map[year].keys { 
				mobility_graph <- mobility_graph add_edge (self::linked);
				mobility_weights[mobility_graph edge_between (self::linked)] <- mobility_map[year][linked];
			} 
		}
		mobility_graph <- mobility_graph with_weights mobility_weights;
		
		loop i from:0 to:10 {
			country o <- any(country);
			country d <- any(country-o);
			write "Does mobility graph contains an edge between "+o.mob_code+" and "+d.mob_code+" : "+
				mobility_graph contains_edge link(o,d);
			write "There have been "+ mobility_graph weight_of link(o,d) +" estimated trips between "
				+o.mob_code+" and "+d.mob_code;
			write "As of "+sample(mobility_weights[mobility_graph edge_between (o::d)]);
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

/*
 * Agent that represent a country
 */
species country {
	
	// Country name
	string CNTRY_NAME;
	
	// Demographics
	float pop;
	map<point,float> pop_age;
	
	// Mobility
	string mob_code;
	map<int,map<country,int>> mobility_map;
	
	// ---------------
	// SIR
	
	////////////////////
	// INITIALIZATION //
	////////////////////
	
	init {
		loop y over:mob_years { mobility_map[y] <- []; }
	}
	
	// ---------------
	// Display section 
	rgb color;
	rgb demo_color;
	
	aspect default { draw shape color:#white border:#black; }
	
	aspect population { draw shape color: demo_color border:#black; }
	
	
}

experiment visualization type:gui {
	output {
		display "world population" type:java2D {
			species country aspect:population;
		}
		display "inter-borders mobilities" type:java2D {
			species country;
			graphics "mobility web" {
				loop e over:mobility_graph.edges { 
					draw geometry(e) color:#red size: 100#km; // ln(mobility_graph weight_of e)/ln(max_mobility[last(mob_years)])*100#km;
				}
			}
		}
	}
}