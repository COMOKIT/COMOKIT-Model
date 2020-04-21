/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Patrick Taillandier
* Tags: covid19,epidemiology, gis
***/

model CoVid19

global {
	
	//define the path to the dataset folder
	//string dataset_path <- "../Datasets/Castanet Tolosan";
	string dataset_path <- "../Datasets/Ha Loi - Me Linh";
	
	
	//define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "/boundary.shp");
	
	
	//optional
	string osm_file_path <- dataset_path + "/map.osm";
	string googlemap_path <- dataset_path + "/googlemap.png";
	
	float simplication_dist <- 1.0;
	float tolerance_dist <- 0.2;
	int tolerance_color_bd <- 1;
	int tolerance_color_type <- 7;
	float convex_hull_coeff <- 0.05;
	float buffer_coeff <- 0.5;
	
	int nb_pixels_x <- file_exists(googlemap_path) ? matrix(image_file(googlemap_path)).columns :1;
	int nb_pixels_y <- file_exists(googlemap_path) ? matrix(image_file(googlemap_path)).rows :1;
	
	float mean_area_flats <- 200.0;
	float min_area_buildings <- 20.0;
	
	bool display_google_map <- true parameter:"Display google map image";
	
	//-----------------------------------------------------------------------------------------------------------------------------
	
	list<rgb> color_bds <- [rgb(241,243,244), rgb(255,250,241)];
	
	map<string,rgb> google_map_type <- ["restaurant"::rgb(255,159,104), "shop"::rgb(73,149,244)];
	
	geometry shape <- envelope(data_file);
	map filtering <- ["building"::[], "shop"::[], "historic"::[], "amenity"::[], "sport"::[], "military"::[], "leisure"::[], "office"::[]];
	image_file static_map_request ;
	init {
		write "Start the pre-processing process";
		create Boundary from: data_file;
		
		osm_file osmfile;
		if (file_exists(osm_file_path)) {
			osmfile  <- osm_file(osm_file_path, filtering);
		} else {
			point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
			point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
			string adress <-"http://overpass.openstreetmap.ru/cgi/xapi_meta?*[bbox="+top_left.x+"," + bottom_right.y + ","+ bottom_right.x + "," + top_left.y+"]";
			osmfile <- osm_file<geometry> (adress, filtering);
		}
		

		write "OSM data retrieved";
		list<geometry> geom <- osmfile  where (each != nil and not empty(Boundary overlapping each));
		
		create Building from: geom with:[building_att:: get("building"),shop_att::get("shop"), historic_att::get("historic"), 
			office_att::get("office"), military_att::get("military"),sport_att::get("sport"),leisure_att::get("lesure"),
			height::float(get("height")), flats::int(get("building:flats")), levels::int(get("building:levels"))
		];
		ask Building {
			if (shape = nil) {do die;} 
		}
		list<Building> bds <- Building where (each.shape.area > 0);
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
		ask Building where (each.shape.area < min_area_buildings) {
			do die;
		}
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
		
		ask Building where (each.type = nil or each.type = "") {
			do die;
		}
		ask Building {
			if (flats = 0) {
				if type in ["apartments","hotel"] {
					if (levels = 0) {levels <- 1;}
					flats <- int(shape.area / mean_area_flats) * levels;
				} else {
					flats <- 1;
				}
			}
		}
	
		if (file_exists(googlemap_path)) {
			do load_google_image;
		}
	
		save Building to:dataset_path +"/buildings.shp" type: shp attributes: ["type"::type, "flats"::flats,"height"::height, "levels"::levels];
		
		map<string, list<Building>> buildings <- Building group_by (each.type);
		loop ll over: buildings {
			rgb col <- rnd_color(255);
			ask ll {
				color <- col;
			}
		}
		write "OSM data clean: type of buildings: " +  buildings.keys;
		
		do load_satellite_image;
	}
	
	
	action load_google_image {
		image_file image <- image_file(googlemap_path);
		ask cell_google {		
			color <-rgb( (image) at {grid_x ,grid_y }) ;
		}
		
		list<cell_google> cells ;
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
			geometry geom <- union(cells collect (each.shape + tolerance_dist));
			
			list<geometry> gs <- geom.geometries collect clean(each);
			gs <- gs where (not empty(Boundary overlapping each));
			ask Building {
				list<geometry> ggs <- gs overlapping self;
				gs <- gs - ggs;
			}
			if (buffer_coeff > 0) {
				float buffer_dist <- first(cell_google).shape.width * buffer_coeff;
				gs <- gs collect (each + buffer_dist);
			}
			if simplication_dist > 0 {
				gs <- gs collect (each simplification simplication_dist);
			}
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
			gs <- gs where (each.area >= min_area_buildings);
			
			create Building from: gs with: [type::""];
		}
		
		loop type over: google_map_type.keys {
			rgb col <- google_map_type[type];
			list<cell_google> cells <- cell_google where ((abs(each.color.red - col.red)+abs(each.color.green - col.green) + abs(each.color.blue - col.blue)) <= tolerance_color_type);
			list<geometry> gs <- union(cells collect (each.shape + tolerance_dist)).geometries;
			if (buffer_coeff > 0) {
				float buffer_dist <- first(cell_google).shape.width * buffer_coeff;
				gs <- gs collect (each + buffer_dist);
			}
			create marker from: gs with: [type::type];
			float min_area <- marker mean_of each.shape.area;
			
			ask marker {	
				if (shape.area < (min_area * 0.5)) {do die;}
				else {
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
		point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
		point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
		int size_x <- 1500;
		int size_y <- 1500;
		
		string rest_link<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mapSize="+int(size_x)+","+int(size_y)+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		static_map_request <- image_file(rest_link);
	
		write "Satellite image retrieved";
		ask cell {		
			color <-rgb( (static_map_request) at {grid_x,1500 - (grid_y + 1) }) ;
		}
		save cell to: dataset_path +"/satellite.png" type: image;
		
		string rest_link2<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mmd=1&mapSize="+int(size_x)+","+int(size_y)+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		file f <- json_file(rest_link2);
		list<string> v <- string(f.contents) split_with ",";
		int ind <- 0;
		loop i from: 0 to: length(v) - 1 {
			if ("bbox" in v[i]) {
				ind <- i;
				break;
			}
		} 
		float long_min <- float(v[ind] replace ("'bbox'::[",""));
		float long_max <- float(v[ind+2] replace (" ",""));
		float lat_min <- float(v[ind + 1] replace (" ",""));
		float lat_max <- float(v[ind +3] replace ("]",""));
		point pt1 <- to_GAMA_CRS({lat_min,long_max}, "EPSG:4326").location ;
		point pt2 <- to_GAMA_CRS({lat_max,long_min},"EPSG:4326").location;
		pt1 <- CRS_transform(pt1, "EPSG:3857").location ;
		pt2 <- CRS_transform(pt2,"EPSG:3857").location;
		float width <- abs(pt1.x - pt2.x)/1500;
		float height <- abs(pt1.y - pt2.y)/1500;
		
		string info <- ""  + width +"\n0.0\n0.0\n"+height+"\n"+min(pt1.x,pt2.x)+"\n"+min(pt1.y,pt2.y);
		save info to: dataset_path +"/satellite.pgw";
		
		write "Satellite image saved with the right meta-data";
		gama.pref_gis_auto_crs <- bool(experiment get "pref_gis" );
		gama.pref_gis_default_crs <- int(experiment get "crs");
		
	}
	
	
}

species marker {
	string type;
	aspect default{
		draw shape color: google_map_type[type];
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
		draw shape color: #gray border: #black;
	}
}

experiment generateGISdata type: gui {
	bool pref_gis <- gama.pref_gis_auto_crs ;
	int crs <- gama.pref_gis_default_crs;
	action _init_ {
		gama.pref_gis_auto_crs <- false;
		gama.pref_gis_default_crs <- 3857;
		create simulation;
	}
	output {
		display map type: opengl draw_env: false{
			image dataset_path +"/satellite.png"  refresh: false;
			graphics "google image"  refresh: false{
				if display_google_map and file_exists(googlemap_path) {
					draw image_file(googlemap_path) ;
				}
			}
			species Building;
			species marker;
		}
	}
}
