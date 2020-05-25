/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Given a boundary.shp shapefile that defines a zone, this model enables
* to create the GIS file of buildings from OSM, to get additional information
* from GoogleMap (types of buildings) and to download a background satellite image
* 
* Author: Patrick Taillandier
* Tags: covid19,epidemiology, gis
******************************************************************/


model CoVid19

global {
	
	/* ------------------------------------------------------------------ 
	 * 
	 *             MANDATORY PARAMETERS
	 * 
	 * ------------------------------------------------------------------
	 */
	//define the path to the dataset folder
	string dataset_path <- "../Datasets/Test Generate GIS Data";	
	
	//mandatory: define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "/boundary.shp");
	
	//if true, GAMA is going to use OSM data to create the building file
	bool use_OSM_data <- true;
	
	//if true, GAMA is going to use google map image to create the building file
	bool use_google_map_data <- true;
	
	//if true, GAMA is going to download the background satellite image (Bing image).
	bool download_satellite_image <- true;
	
	
	/* ------------------------------------------------------------------ 
	 * 
	 *             OPTIONAL PARAMETERS
	 * 
	 * ------------------------------------------------------------------
	 */
	// --------------- OSM data parameters ------------------------------
	//path to an existing Open Street Map file - if not specified, GAMA is going to directly download to correct data
	string osm_file_path <- dataset_path + "/map.osm";
	
	//for appartement, the mean area (in m^2) of flats (used when flats value is not specified) 
	float mean_area_flats <- 200.0 min: 10.0;
	
	//for hotel, the mean area (in m^2) of rooms (used when flats value is not specified) 
	float mean_area_rooms <- 100.0 min: 10.0;
	
	//min area to consider a building (in m^2)
	float min_area_buildings <- 20.0 min: 0.0;
	
	//type of feature considered
	map filtering <- ["building"::[], "shop"::[], "historic"::[], "amenity"::[], "sport"::[], "military"::[], "leisure"::[], "office"::[]];
	
	// --------------- google image parameters ------------------------------
	//path to an existing google map image - if not speciefied, GAMA can try to download the correct image - WARNING: can be blocked by google
	string googlemap_path <- dataset_path + "/googlemap.png";
	
	//possibles colors for buildings
	list<rgb> color_bds <- [rgb(241,243,244), rgb(255,250,241)];
	
	//type of markers considered with their associated color
	map<string,rgb> google_map_type <- ["restaurant"::rgb(255,159,104), "shop"::rgb(73,149,244)];
	
	//number of pixels per tile
	int TILE_SIZE <- 256;
	
	//when downloading google images, the level of zoom
	int zoom <- 18 min: 17 max: 20;
	
	//simplification distance for building (using Douglas Peucker algorithm)
	float simplication_dist <- 1.0 min: 0.0;
	
	//tolerance (distance in meters) for the union of "building" pixels 
	float tolerance_dist <- 0.2 min: 0.0;
	
	//tolerance for the color of building (for a pixel to be considered as a building pixel)
	int tolerance_color_bd <- 1 min: 0 max: 10;
	
	//tolerance for the color of markers (for a pixel to be considered as a marker pixel)
	int tolerance_color_type <- 7 min: 0 max: 20;
	
	//coefficient (area of the building/area of the convex hull of the building) to keep the convex hull of the building rather than its shape (if convex_hull_coeff = 0.0, the convex hull is never used)
	float convex_hull_coeff <- 0.05 min: 0.0 max: 1.0;
	
	//coeffient used to apply a buffer to the building (distance = buffer_coeff * width of a pixel).
	float buffer_coeff <- 0.5 min: 0.0;
	

	/* ------------------------------------------------------------------ 
	 * 
	 *              DYNAMIC VARIABLES
	 * 
	 * ------------------------------------------------------------------
	 */

	//geometry of the bounds
	geometry bounds_tile;
	
	//index used to read google map tiles
	int ind <- 0;
	
	//list of google map tile with their associated metadata
	map<string, map<string,int>> data_google; 
	
	//when using a google map image, the nomber of pixel of this image
	int nb_pixels_x <- (use_google_map_data and file_exists(googlemap_path)) ? matrix(image_file(googlemap_path)).columns :1;
	int nb_pixels_y <- (use_google_map_data and file_exists(googlemap_path)) ? matrix(image_file(googlemap_path)).rows :1;
	
	//geometry of the world
	geometry shape <- envelope(data_file);
	
	
	init {
		write "Start the pre-processing process";
		
		//creation of the boundary of the studied area
		create Boundary from: data_file;
		
		//load OSM data (if necessary)
		if (use_OSM_data) {
			do load_OSM_data;
		}
	
		//load google map image (if necessary)
		if (use_google_map_data) {
			//if the image already exists, just load this image and vectorize it
			if (file_exists(googlemap_path)) {
				do load_google_image;
			} else {
				//otherwise propose to download the image from google (WARNING: direct access to google map image without using the google api (and key) is recommended).
				map input_values <- user_input("Do you want to download google maps to fill in the data? (warning: risk of being blocked by google!)",[enter("Download data",false), enter("Delay (in s) between two requests",5.0)]);
				experiment.minimum_cycle_duration <- max(0.5, float(input_values["Delay (in s) between two requests"]));
	
				//if the user choose to download the data anyway, build and store the url to the needed tiles.
				if bool(input_values["Download data"]) {
					point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
					point top_left <- bottom_right - (bottom_right - CRS_transform(location, "EPSG:4326").location) * 2;
					list<int> indtl <- index_tile(top_left);
					list<int> indbr <- index_tile(bottom_right);
					
					int resolution_x <- abs(indbr[2] - indtl[2])  ;
					int resolution_y <- abs(indbr[3] - indtl[3]);	
					int id_x <- 0;
					int id_y <- 0;
					int offset_x <- min(indbr[0],indtl[0]);
					int offset_y <- min(indbr[1],indtl[1]);
					loop ind_tile_x from: 0 to: abs(indbr[0] - indtl[0])  {
						loop ind_tile_y from: 0 to:abs(indtl[1] - indbr[1]) {
							string img <- "http://mt2.google.com/vt/lyrs=m&x=" +(ind_tile_x + offset_x)+"&y="+ (ind_tile_y  + offset_y)+"&z="+zoom;
							data_google[img] <- ["ind_tile_x":: (ind_tile_x + offset_x) ,  "ind_tile_y"::(ind_tile_y + offset_y)];
						}
					}
				}
			}
		}
	
		//save the building using the pseudo mercator crs with the type, flats, heights and levels attributes
		save Building crs:"EPSG:3857" to:dataset_path +"/buildings.shp" type: shp attributes: ["type"::type, "flats"::flats,"height"::height, "levels"::levels];
		
		
		//for type of building, assign a random color
		map<string, list<Building>> buildings <- Building group_by (each.type);
		loop type over: buildings.keys {
			list<Building> ll <- buildings[type];
			rgb col <- (type in google_map_type.keys) ? google_map_type[type] : rnd_color(255);
			ask ll {
				color <- col;
			}
		}
		//write the existing type of buildings in the data
		write "OSM data clean: type of buildings: " +  buildings.keys;
		
		//if necessary download the satellite image from Bing
		if (download_satellite_image) {
			do load_satellite_image;
		}
		
	}
	
	action load_OSM_data {
		osm_file osmfile;
			if (file_exists(osm_file_path)) {
				osmfile  <- osm_file(osm_file_path, filtering);
			} else {
				//if the file does not exist, download the data needed 
				point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
				point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
				string adress <-"http://overpass.openstreetmap.ru/cgi/xapi_meta?*[bbox="+top_left.x+"," + bottom_right.y + ","+ bottom_right.x + "," + top_left.y+"]";
				osmfile <- osm_file<geometry> (adress, filtering);
			}
			
			write "OSM data retrieved";
			
			//just keep the data inside the boundary
			list<geometry> geom <- osmfile  where (each != nil and not empty(Boundary overlapping each));
			
			//create the building agents from the data
			create Building from: geom with:[building_att:: get("building"),shop_att::get("shop"), historic_att::get("historic"), 
				office_att::get("office"), military_att::get("military"),sport_att::get("sport"),leisure_att::get("lesure"),
				height::float(get("height")), flats::int(get("building:flats")), levels::int(get("building:levels"))
			];
			
			//clean agents with nil geometry
			ask Building {
				if (shape = nil) {do die;} 
			}
			list<Building> bds <- Building where (each.shape.area > 0);
			
			//use the agent with a point geometry to define the type of building;
			ask Building where (each.shape.area = 0) {
				list<Building> bd <- bds overlapping self;
				ask bd {
					sport_att  <- myself.sport_att;
					office_att  <- myself.office_att;
					military_att  <- myself.military_att;
					leisure_att  <- myself.leisure_att;
					amenity_att  <- myself.amenity_att;
					shop_att  <- myself.shop_att;
					historic_att <- myself.historic_att;
				}
				do die; 
			}
			
			//remove building which are too small.
			ask Building where (each.shape.area < min_area_buildings) {
				do die;
			}
			//define the type of the buildings
			ask Building {
				if (amenity_att != nil) {
					type <- amenity_att;
				}else if (shop_att != nil) {
					type <- shop_att;
				}
				else if (office_att != nil) {
					type <- office_att;
				}
				else if (leisure_att != nil) {
					type <- leisure_att;
				}
				else if (sport_att != nil) {
					type <- sport_att;
				} else if (military_att != nil) {
					type <- military_att;
				} else if (historic_att != nil) {
					type <- historic_att;
				} else {
					type <- building_att;
				} 
			}
			
			//delete building with no type
			ask Building where (each.type = nil or each.type = "") {
				do die;
			}
			
			//define the number of flats for each building;
			ask Building {
				if (flats = 0) {
					if type = "apartments" {
						if (levels = 0) {levels <- 1;}
						flats <- int(shape.area / mean_area_flats) * levels;
					} else if type = "hotel" {
						if (levels = 0) {levels <- 1;}
						flats <- int(shape.area / mean_area_rooms) * levels;
					}else {
						flats <- 1;
					}
				}
			}
	}
	
	//action for vectorizing an existing google image
	action load_google_image {
		image_file image <- image_file(googlemap_path);
		ask cell_google {		
			color <-rgb( (image) at {grid_x ,grid_y }) ;
		}
		
		list<cell_google> cells ;
		
		//define for each pical if it is building pixel
		ask cell_google {
			loop col over: color_bds {
				if ((abs(color.red - col.red)+abs(color.green - col.green) + abs(color.blue - col.blue)) < tolerance_color_bd) {
					cells << self;
					break;
				}
			}
		}
		if empty(cells) {
			write "No building found in the google map image"; 
		} else {
			//if this list is not empty, recompute the geometry of each building
			geometry geom <- union(cells collect (each.shape + tolerance_dist));
			list<geometry> gs <- geom.geometries collect clean(each);
			
			//keep only building inside the boundary
			gs <- gs where (not empty(Boundary overlapping each));
			
			//just keep buildings that are not overlapping existing buildings
			ask Building {
				list<geometry> ggs <- gs overlapping self;
				gs <- gs - ggs;
			}
			
			//apply a buffer to the building to take into account the imperfection of the vectorization
			if (buffer_coeff > 0) {
				float buffer_dist <- first(cell_google).shape.width * buffer_coeff;
				gs <- gs collect (each + buffer_dist);
			}
			
			//simplify the geometry of the building to remove some vectorization acrtifact
			if simplication_dist > 0 {
				gs <- gs collect (each simplification simplication_dist);
			}
			
			//use the convex hull for building that are nearly convex
			if (convex_hull_coeff > 0.0) {
				list<geometry> gs2;
				loop g over: gs {
					geometry ch <- convex_hull(g);
					if (g.area/ch.area > (1 - convex_hull_coeff)) {
						gs2 << ch;
					} else {
						gs2 << g;
					}
				}
				gs <- gs2;
			}
			
			//remove building that are too small
			gs <- gs where (each.area >= min_area_buildings);
			
			//create the buildings
			create Building from: gs with: [type::""];
		}
		
		//for each type of marker, create the marker agents from the google image and use to it to give a type to the closest building (of the bottom of the marker)
		loop type over: google_map_type.keys {
			rgb col <- google_map_type[type];
			
			//select the pixel of the given color
			list<cell_google> cells <- cell_google where ((abs(each.color.red - col.red)+abs(each.color.green - col.green) + abs(each.color.blue - col.blue)) <= tolerance_color_type);
			
			//and build geometries from them
			list<geometry> gs <- union(cells collect (each.shape + tolerance_dist)).geometries;
			if (buffer_coeff > 0) {
				float buffer_dist <- first(cell_google).shape.width * buffer_coeff;
				gs <- gs collect (each + buffer_dist);
			}
			
			//create the marker agents
			create marker from: gs with: [type::type];
			
			//keep only the marker that are not too small (to take into account only "complete" markers)
			float min_area <- marker mean_of each.shape.area;
			ask marker {	
				if (shape.area < (min_area * 0.5)) {do die;}
				else {
					//use the marker to define the type of the building that is the closest to the bottom of the marker
					point loc <- shape.points with_max_of (each.y);
					Building bd <- Building closest_to loc;
					bd.type <- type;
				}
			}
		}
		
		write "google image vectorized";
	}
	
	action load_satellite_image
	{ 
		//define the url of the satellite image
		point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
		point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
		int size_x <- 1500;
		int size_y <- 1500;
		
		string rest_link<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mapSize="+size_x+","+size_y+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		image_file static_map_request <- image_file(rest_link);
	
		write "Satellite image retrieved";
		ask cell {		
			color <-rgb( (static_map_request) at {grid_x,1500 - (grid_y + 1) }) ;
		}
		//save the image retrieved
		save cell to: dataset_path +"/satellite.png" type: image;
		
		//add meta-data to georeferenced the image
		string rest_link2<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mmd=1&mapSize="+size_x+","+size_y+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		file f <- json_file(rest_link2);
		list<string> v <- string(f.contents) split_with ",";
		int index <- 0;
		loop i from: 0 to: length(v) - 1 {
			if ("bbox" in v[i]) {
				index <- i;
				break;
			}
		} 
		float long_min <- float(v[index] replace ("'bbox'::[",""));
		float long_max <- float(v[index+2] replace (" ",""));
		float lat_min <- float(v[index + 1] replace (" ",""));
		float lat_max <- float(v[index +3] replace ("]",""));
		point pt1 <- CRS_transform({lat_min,long_max},"EPSG:4326", "EPSG:3857").location ;
		point pt2 <- CRS_transform({lat_max,long_min},"EPSG:4326","EPSG:3857").location;
		float width <- abs(pt1.x - pt2.x)/1500;
		float height <- (pt2.y - pt1.y)/1500;
			
		string info <- ""  + width +"\n0.0\n0.0\n"+height+"\n"+min(pt1.x,pt2.x)+"\n"+(height < 0 ? max(pt1.y,pt2.y) : min(pt1.y,pt2.y));
	
		//save the metadat
		save info to: dataset_path +"/satellite.pgw";
		
		write "Satellite image saved with the right meta-data";
		gama.pref_gis_auto_crs <- bool(experiment get "pref_gis" );
		gama.pref_gis_default_crs <- int(experiment get "crs");
		
	}
	
	
	
	//reflex used to download a google map tile and to vectorize it
	reflex vectorization {
		if (ind < length(data_google)) {
			bool continue <- true;
			//continue until downloading an image located in the boundary
			loop while: continue and (ind < length(data_google)) {
				//verify that the tile is really inside the boundary
				list<rgb> colors;
				map<string, int> infos <- data_google[data_google.keys[ind]];
				int tx <- infos["ind_tile_x"];
				int ty <- infos["ind_tile_y"];
				point sw <- toMeter(tx*TILE_SIZE, ty*TILE_SIZE);
				point ne <- toMeter((tx+1)*TILE_SIZE, (ty+1)*TILE_SIZE);
				sw <- to_GAMA_CRS(sw, "EPSG:3857").location;
				ne <- to_GAMA_CRS(ne, "EPSG:3857").location;
				
				//build the bounds of the tile
				bounds_tile <- polygon({sw.x,sw.y}, {sw.x,ne.y}, {ne.x,ne.y}, {ne.x,sw.y});
				
				
				//if the tile really overlaps the boundary
				if not empty(Boundary overlapping bounds_tile) {
					continue <- false;
					// download the google map tile
					image_file img<- image_file(data_google.keys[ind]);
				
					//transform each pixel into a rectangle geometry
					list<geometry> rectangles <- bounds_tile to_rectangles(TILE_SIZE,TILE_SIZE);
					loop i from: 0 to: length(rectangles) - 1 {
						colors << rgb(img.contents at {int(i/TILE_SIZE),i mod TILE_SIZE});
					}
					list<geometry> cells ;
					
					//select the building pixel
					loop i from: 0 to: length(rectangles) - 1 {
						geometry r <- rectangles[i];
						rgb col_r <- colors[i];
						loop col over: color_bds {
							if ((abs(col_r.red - col.red)+abs(col_r.green - col.green) + abs(col_r.blue - col.blue)) < tolerance_color_bd) {
								cells << r;
								break;
							}
						}
					}
					if (not empty(cells)) {
						//if this list is not empty, recompute the geometry of each building
						geometry geom <- union(cells collect (each + tolerance_dist));
						list<geometry> gs <- geom.geometries collect clean(each);
			
						//keep only building inside the boundary
						gs <- gs where (not empty(Boundary overlapping each));
						
						//just keep buildings that are not overlapping existing buildings
						ask Building {
							list<geometry> ggs <- gs overlapping self;
							gs <- gs - ggs;
						}
						
						//apply a buffer to the building to take into account the imperfection of the vectorization
						if (buffer_coeff > 0) {
							float buffer_dist <- first(cells).width * buffer_coeff;
							gs <- gs collect (each + buffer_dist);
						}
						
						//simplify the geometry of the building to remove some vectorization acrtifact
						if simplication_dist > 0 {
							gs <- gs collect (each simplification simplication_dist);
						}
						
						//use the convex hull for building that are nearly convex
						if (convex_hull_coeff > 0.0) {
							list<geometry> gs2;
							loop g over: gs {
								geometry ch <- convex_hull(g);
								if (g.area/ch.area > (1 - convex_hull_coeff)) {
									gs2 << ch;
								} else {
									gs2 << g;
								}
							}
							gs <- gs2;
						}
						//remove building that are too small
						gs <- gs where (each.area >= min_area_buildings);
						
						//create the buildings
						create Building from: gs with: [type::""];
						
						//for each type of marker, create the marker agents from the google image and use to it to give a type to the closest building (of the bottom of the marker)
						loop type over: google_map_type.keys {
							list<geometry> cells;
							rgb col <- google_map_type[type];
							
							//select the pixel of the given color 
							loop i from: 0 to: length(rectangles) - 1 {
								geometry r <- rectangles[i];
								rgb col_r <- colors[i];
								if ((abs(col_r.red - col.red)+abs(col_r.green - col.green) + abs(col_r.blue - col.blue)) < tolerance_color_bd) {
									cells << r;
								}
							}
							
							if not empty(cells) {
								//and build geometries from them
								list<geometry> gs <- union(cells collect (each + tolerance_dist)).geometries;
								if (buffer_coeff > 0) {
									float buffer_dist <- first(cells).width * buffer_coeff;
									gs <- gs collect (each + buffer_dist);
								}
								
								//create the marker agents
								create marker from: gs with: [type::type];
								
								float min_area <- marker mean_of each.shape.area;
								
								ask marker {	
									//keep only the marker that are not too small (to take into account only "complete" markers)
									if (shape.area < (min_area * 0.5)) {do die;}
									else {
										//use the marker to define the type of the building that is the closest to the bottom of the marker
										point loc <- shape.points with_max_of (each.y);
										Building bd <- Building closest_to loc;
										bd.type <- type;
										color <- (type in google_map_type.keys) ? google_map_type[type] : rnd_color(255);
				
									}
								}
							}
						}
					}
				}
				ind <- ind + 1; 
			}
		} else {
			//at the end, save the building
			if (not empty(data_google)) {
				save Building crs:"EPSG:3857" to:dataset_path +"/buildings.shp" type: shp attributes: ["type"::type, "flats"::flats,"height"::height, "levels"::levels];
			}
			do pause;
		}
		
		
	}
	
	//a function used to compute the coordinate when retrieving google map images
	point toMeter(int px, int py) {
		float res <- (2 * #pi * 6378137 / TILE_SIZE) / (2^zoom);
		float originShift <- 2 * #pi * 6378137 / 2.0;
		return { px * res - originShift,  - py * res + originShift};
	}
	
	//a function to compute the google map tile from coordinate
	list<int> index_tile(point coord) {
		point worldCoordinate <- project_to_wp({coord.x,coord.y});
		float scale <- 2^zoom;
		
		int pix <- int(worldCoordinate.x * scale);
		int piy <- int(worldCoordinate.y * scale);
		int ind_x <- int(worldCoordinate.x * scale / TILE_SIZE);
		int ind_y <- int(worldCoordinate.y * scale / TILE_SIZE);
		return [ind_x,ind_y,pix,piy];
	}
	
	
	//a function to compute the google map coordinate from WGS84 coordinate
	point project_to_wp(point latLng) {
		float siny <- sin_rad(latLng.y * #pi / 180);
		siny <- min(max(siny, -0.9999), 0.9999);
        return {TILE_SIZE * (0.5 + latLng.x / 360),TILE_SIZE * (0.5 - ln((1 + siny) / (1 - siny)) / (4 * #pi))};
    }
    
    
	
}

species marker {
	string type;
	aspect default{
		draw shape color: google_map_type[type] depth: 1;
	}
}

grid cell_google width: nb_pixels_x height: nb_pixels_y use_individual_shapes: false use_regular_agents: false neighbors:8;

grid cell width: 1500 height:1500 use_individual_shapes: false use_regular_agents: false use_neighbors_cache: false;

species Building {
	string type;
	string building_att;
	string shop_att;
	string historic_att;
	string amenity_att;
	string office_att;
	string military_att;
	string sport_att;
	string leisure_att;
	float height;
	int flats;
	int levels;
	rgb color;
	aspect default {
		draw shape color: color border: #black depth: (1 + flats) * 3;
	}
}

species Boundary {
	aspect default {
		draw shape color: #violet empty: true;
	}
}

experiment generateGISdata type: gui autorun: true {
	float minimum_cycle_duration <- 5.0;
	bool pref_gis <- gama.pref_gis_auto_crs ;
	int crs <- gama.pref_gis_default_crs;
	action _init_ {
		gama.pref_gis_auto_crs <- false;
		gama.pref_gis_default_crs <- 3857;
		create simulation;
	}
	output {
		display map type: opengl draw_env: false background: #black{
			image (file_exists(googlemap_path) ? (googlemap_path): "white.png") transparency: 0.2;
			image (file_exists(dataset_path+"/satellite.png") ? (dataset_path+"/satellite.png"): "white.png")  transparency: 0.2;
			
			graphics "tile" {
				if bounds_tile != nil {
					draw bounds_tile color: #red empty: true;
				}
			}
			species Boundary;
			species Building;
			species marker;
		}
	}
}
