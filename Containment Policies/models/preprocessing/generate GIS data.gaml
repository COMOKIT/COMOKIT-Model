/***
* Name: generateGISdata
* Author: Patrick TAILLANDIER
* Description: Generate your data for the model
* Tags: environment generation, GIS data, buildings, satellite image
***/

model generateGISdata

global {
	//define the bounds of the studied area
	file data_file <-shape_file("../../data/commune.shp");
	
	//define the path to the output folder
	string output_path <- "../../data/Castanet Tolosan";
	
	
	
	//-----------------------------------------------------------------------------------------------------------------------------
	
	geometry shape <- envelope(data_file);
	map filtering <- ["building"::[], "shop"::[], "historic"::[], "amenity"::[], "sport"::[], "military"::[], "leisure"::[], "office"::[]];
	image_file static_map_request ;
	init {
		write "Start the pre-processing process";
		create Boundary from: data_file;
		point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
		point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
		string adress <-"http://overpass.openstreetmap.ru/cgi/xapi_meta?*[bbox="+top_left.x+"," + bottom_right.y + ","+ bottom_right.x + "," + top_left.y+"]";
	
		//file osmfile <- osm_file("../../data/Castanet Tolosan/xapi_meta.osm", filtering);
		file osmfile <- osm_file<geometry> (adress, filtering);
	
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
		save Building to:output_path +"/buildings.shp" type: shp attributes: ["type"::type, "flats"::flats,"height"::height, "levels"::levels];
		
		map<string, list<Building>> buildings <- Building group_by (each.type);
		loop ll over: buildings {
			rgb col <- rnd_color(255);
			ask ll {
				color <- col;
			}
		}
		write "OSM data clean: type of buildings: " +  buildings.keys;
		
		do load_image;
	}
	
	action load_image
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
		save cell to: output_path +"/satellite.png" type: image;
		
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
		save info to: output_path +"/satellite.pgw";
		
		write "Satellite image saved with the right meta-data";
		 
		
	}
	
	
}

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
		draw shape color: color border: #black;
	}
}

species Boundary {
	aspect default {
		draw shape color: #gray border: #black;
	}
}

experiment generateGISdata type: gui {
	output {
		display map type: opengl draw_env: false{
			image  output_path +"/satellite.png" transparency: 0.2;
			species Building;
		}
	}
}
