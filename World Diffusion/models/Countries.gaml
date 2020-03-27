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
	
	// Epidemio -----------
	
	string base_url_timeseries <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/";
	
	string confirmed_file <- "time_series_covid19_confirmed_global.csv";
	string dead_file <- "time_series_covid19_deaths_global.csv";
	string recovered_file <- "time_series_covid19_recovered_global.csv";
	
	file cf <- text_file(base_url_timeseries+confirmed_file); 
	string CONFIRMED <- "Confirmed case";
	file df <- text_file(base_url_timeseries+dead_file);
	string DEAD <- "Dead case";
	file rf <- text_file(base_url_timeseries+recovered_file);
	string RECOVERED <- "Recovered case";  
	
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
			//error "There is "+length(cs)+" countries without mobility code";
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
		do build_mobility_graph(last(mob_years),false);
		
		// Build covid19 epidemiological history
		do build_epidemic_history();
		
		// Assigne color to country for population
		min_pop <- min(country collect (each.pop));
		max_pop <- max(country collect (each.pop));
		ask country {
			if pop = 0 {demo_color <- #white;}
			else {demo_color <- world.get_rgb_palette(demo_palette, min_pop, max_pop, pop);}
		}
		
	}
	
	/*
	 * Build a graph using cross border estimateed mobilities in a given year
	 * TODO : fix the graph/weights
	 */
	action build_mobility_graph(int year, bool debug <- true) {
		ask country { mobility_graph <- mobility_graph add_node self; }
		map<pair<point,point>,int> mobility_weights;
		ask country { 
			loop linked over:mobility_map[year].keys {
				if mobility_map[year][linked] > 0 { 
					mobility_graph <- mobility_graph add_edge (self::linked);
					mobility_weights[link(self,linked)] <- mobility_map[year][linked];
				}
			} 
		}
		mobility_graph <- mobility_graph with_weights mobility_weights;
		
		if debug {
			loop k over:sample(mobility_weights.keys,10,false) {
				country o <- country first_with (each.location=first(k));
				country d <- country first_with (each.location=last(k));
				write "Does mobility graph contains an edge between "+o.mob_code+" and "+d.mob_code+" : "+
					mobility_graph contains_edge k;
				write "Graph weight between the two country: "+ sample(mobility_graph weight_of k);
				write "Weights report on the map "+sample(mobility_weights[k]);
			}
		}
	}
	
	/*
	 * Build epidemiological history for countries around the world using data from:
	 * https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data
	 */
	action build_epidemic_history {
		
		matrix mat_cc <- csv_file(cf);
		matrix mat_dc <- csv_file(df);
		
		if not(mat_cc.rows = mat_dc.rows and mat_cc.columns = mat_dc.columns) {
			error "Confirmed and dead data do not match";
		}
			
		list<date> history;
		loop j from:4 to:mat_cc.columns-1{
			if mat_cc[j,0]!=nil {
				list<string> d <- string(mat_cc[j,0]) split_with "/";
				history <+ date([int("20"+last(d)),int(first(d)),int(d[1])]);
			}
		}
		
		list<string> c_name;
		loop i from:1 to:mat_cc.rows-1 {
			c_name <+ mat_cc[1,i];
		}
		
		loop i from:1 to:mat_cc.rows-1 {
			country c <- country first_with (country_match(each.CNTRY_NAME,mat_cc[1,i]));
			if c!=nil {
				loop j from:4 to:mat_cc.columns-1 {
					try {
						date the_date <- history[j-4];
						if c.epi_history[the_date]=nil { c.epi_history[the_date] <- []; }
						else { 
							c.epi_history[the_date][CONFIRMED] <- int(mat_cc[j,i]);
							c.epi_history[the_date][DEAD] <- int(mat_dc[j,i]);
						}
					} catch {
						if length(history) > j-4 { error "Error reading epistemological history";}
					}
				} 
			} else {
				if not(nan contains mat_cc[1,i]) {
					error "No country match for epidemiological record of "+mat_cc[1,i];
				}
			}
		}
		
		matrix mat_rc <- csv_file(rf);
		
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
	
	list<list<string>> cc <- [
		["US","United States"],["Myanmar","Burma"],["Tanzania","United Republic of Tanzania"],
		["Vietnam","Viet Nam"],["Laos","Lao People's Democratic Republic"],["Cabo Verde","Cape Verde"],
		["Cote d'Ivoire","Ivory Coast"],["Congo (Brazzaville)","Congo"],["Bahamas, The","Bahamas"],
		["Congo (Kinshasa)","Zair","Democratic Republic of the Congo"],["Gambia, The","Gambia"],
		["Iran","Iran (Islamic Republic of)"],["Moldova","Republic of Moldova"],["Saint Lucia","St. Lucia"],
		["Korea","Republic of Korea","\"Korea"],["Taiwan","Taiwan*"],["West Bank and Gaza","Gaza Strip"],
		["St. Vincent and the Grenadines","Saint Vincent and the Grenadines"],
		["St. Kitts and Nevis","Saint Kitts and Nevis"]
	];
	
	list<string> nan <- ["Diamond Princess","Holy See","Timor-Leste","Antarctica","Kosovo"];
	
	/*
	 * Cope with the various country names across data sources
	 */
	bool country_match(string c1, string c2) {
		if lower_case(c1) = lower_case(c2) {return true;}
		list<string> cl <- cc first_with (each contains c1);
		return cl = nil ? false : cl contains c2;
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
	// Epidemio
	map<date,map<string,int>> epi_history;
	// SIR
	
	////////////////////
	// INITIALIZATION //
	////////////////////
	
	init {
		loop y over:mob_years { mobility_map[y] <- []; }
		epi_history <- [];
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