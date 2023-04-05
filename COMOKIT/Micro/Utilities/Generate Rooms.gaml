/**
* Name: GenerateRooms
* Based on the internal skeleton template. 
* Author: Patrick Taillandier
* Tags: 
*/

model GenerateRooms

import "Generate pedestrian paths.gaml" 

global {
	
	
	string dataset_path <- "../Datasets/Simple Building/";
	string buildings_path <- dataset_path + "Buildings.shp";
	string rooms_path <- dataset_path + "Rooms.shp" ;
	string walls_path <- dataset_path + "Walls.shp" ;
	string beds_path <-  dataset_path + "Beds.shp" ;
	
	string elevators_path <- dataset_path + "Elevators.shp" ;
	
	string building_entry_path <- dataset_path + "Building_entries.shp" ;
	string room_entry_path <- dataset_path + "Room_entries.shp" ;
	shape_file buildings_shapefile <- shape_file(buildings_path);
	
	string pedestrian_paths_path <- dataset_path+"pedestrian paths.shp";
	string open_area_path <- dataset_path+"open area.shp";
	
	float distance_close <- 20.0;
	
	float door_building_size <- 4.0;
	
	//geometry shape <- envelope(buildings_shapefile);
	float angle_ref ;
	float door_size <- 2.0;
	float wall_width <- 0.2;
	float room_scale <- 0.9;
	float floor_high <- 5.0 #m;
	float area_per_bed <- 6 #m;
	
	
	
	init {
		//list<float> angles <- [];
		create Building from: buildings_shapefile  {
			id <- int(self);
			string rt <- string(get("room_type"));
			list<string> rts <- rt split_with ",";
			loop t over: rts {
				list<string> ts <- t split_with ":";
				types_room[ts[0]] <- float(ts[1]);
			}
		}
		
		
		do create_building_entries;
		
		angle_ref <- (Building with_max_of (each.shape.area)).angle_buildings();
		ask Building {
			loop i from: 0 to: nb_floors - 1 {
				do create_rooms(i);	
			}
			if nb_unders > 0 {
				loop i from: 1 to: nb_unders  {
					do create_rooms(-1 * i);	
				}
			}
		}
		ask Room {
			do create_walls;
		}
		
		ask Bed {
			location <- location + {0,0, floor * floor_high};
		}
		
		
		ask Room {
			location <- location + {0,0, floor * floor_high};
		}
		
		ask Wall {
			location <- location + {0,0, floor * floor_high};
		}
		
		ask Building where ((not empty(each.rooms)) and (each.nb_floors > 1)){
			loop i over: rooms.keys {
				list<Room> rs <- rooms[i];
				if not empty(rs) {
					Room sr <- rs with_min_of each.shape.area;
					create Elevator with: (shape:copy(sr.shape), floor:sr.floor, bd:self) {
						rs << self;
						building <- int(bd);
					}
					rs >> sr;
					ask sr {
						ask beds {do die;}
						do die;
					}
				}
			}
		}
		int cpt <- 0;
		ask Room {
			id <- cpt; cpt <- cpt + 1;
		}
		save BuildingEntry format:shp to: building_entry_path attributes: ["building"];
		save Room format:shp to: rooms_path attributes: ["id", "floor", "building", "type"];
		save RoomEntry format:shp to: room_entry_path attributes: ["floor", "room_id"];
		save Elevator format:shp to: elevators_path attributes: ["floor", "building"];
		save Wall format:shp to: walls_path attributes: ["floor", "building"];
		save Bed format:shp to: beds_path attributes: ["room_id", "floor", "building"];
		
		loop bd over: Building {
			list<list<agent>> created_agents;
			loop fl over: bd.rooms.keys {
				if empty(created_agents) {
					list<geometry> obstacles <- bd.rooms[fl];
					created_agents <- generate_path(bd,  obstacles, bd.id, fl);
				} else {
					loop ag over: created_agents[0] {
						create OpenArea with: (shape: copy(ag.shape), building:copy(OpenArea(ag).building), floor:fl);
					}
					loop ag over: created_agents[1] {
						create PedestrianPath with: (shape: copy(ag.shape), building:copy(PedestrianPath(ag).building), floor:fl);
					}
				}
			}
		
		}
		do generate_path(shape, Building as list, -1, 0);
		
		ask OpenArea {
			location <- location + {0,0, floor * floor_high};
		}
		
		ask PedestrianPath {
			location <- location + {0,0, floor * floor_high};
		}
		
		save OpenArea format: shp to: open_area_path attributes: ["building", "floor"];
		save PedestrianPath format: shp to: pedestrian_paths_path attributes: ["building", "floor", "area"];
		
	}
	
	action process_data;
	
	action create_building_entries {
		ask Building {
			geometry buff <- shape + distance_close;
			list<Building> bds <- Building at_distance distance_close;
			list<BuildingEntry> bd_entries <- [];
			loop bd over: bds {
				geometry b1 <- (buff inter bd) ;
				point pt <-(b1.location closest_points_with shape) [1];
				geometry g <- ((circle( door_building_size/2.0) at_location pt) inter shape.contour) + wall_width;
				if convex_hull(g).area <= (g.area * 1.2)  {
					create BuildingEntry with: (shape:g, building:id) {
						bd_entries << self;
					}
						
				}
			}
			geometry env <- envelope(self);
			loop i from: 0 to: 3 {
				geometry l <- line([env.points[i],env.points[i+1]]);
				point pt <-(l.location closest_points_with shape) [1];
				if empty(bd_entries where ((each distance_to pt) < distance_close)) {
					geometry g <- ((circle( door_building_size/2.0) at_location pt) inter shape.contour) + wall_width;
					if convex_hull(g).area <= (g.area * 1.2)  {
						create BuildingEntry with: (shape:g, building:id) {
							bd_entries << self;
						}
							
					}
				}
				
			}			
		}
		
	}
	
	
}

species Bed {
	int room_id;
	int floor;
	int building;
	
	aspect default {
		draw shape color: #cyan ;
	}
}
species RoomEntry {
	int room_id;
	int floor;
	aspect default {
		draw shape color: #cyan ;
	}
}

species BuildingEntry {
	int building;
	aspect default {
		draw shape color: #magenta ;
	}
}

species Room {
	int id;
	string type;
	Building bd;
	int building;
	int floor;
	list<Bed> beds;
	
	
	aspect default {
		draw shape color: #gray ;
	}
	
	action create_walls {
		
		list<geometry> lines;
		loop i from: 0 to: length(shape.points) - 2 {
			lines << line([shape.points[i],shape.points[i+1]]);
		}
		
		geometry l_ref;
		float dist_max <- 0.0;
		list<Room> rms <- bd.rooms[floor] - self;
		loop l over: lines {
			if l.perimeter > door_size {
				agent r_ <- empty(rms) ? nil : (rms closest_to l);
				float dist <- min(r_ = nil ? #max_float : (l distance_to r_), l distance_to bd.shape.contour );
				if dist > dist_max {
					dist_max <- dist;
					l_ref <- l;
				}
			}
		}
		lines >> l_ref;
		geometry door_g <-  (l_ref inter (circle(door_size/2.0) at_location l_ref.location)) + wall_width ;
		create RoomEntry with: (room_id:id, shape:door_g, floor:floor );
		l_ref <- l_ref - (circle(door_size/2.0) at_location l_ref.location);
		lines <- lines + l_ref.geometries;
		loop l over: lines {
			create Wall with: (shape: l + wall_width, floor:floor, building: building);
		}
	}
}

species Elevator parent: Room {
	aspect default {
		draw shape color: #red ;
	}
}





species Building {
	int id;
	int nb_floors <- 3;
	int nb_unders <- 0;
	float room_size <- 10.0;
	map<string,float> types_room;
	
	
	map<int,list<Room>> rooms;
	
	
	init {
		loop i from: 0 to: nb_floors -1 {
			rooms[i] <- [];
		}
		if nb_unders > 0 {
			loop i from: 1 to: nb_unders  {
				rooms[-i] <- [];
			}
		}
		
	}
	float angle_buildings {
		float max_length <- 0.0;
		list<point> points;
		loop i from: 0 to: length(shape.points) - 2 {
			float dist <- shape.points[i] distance_to shape.points[i+1];
			if dist > max_length {
				max_length <- dist;
				points <- [shape.points[i],shape.points[i+1]];
			}
		}
		return points[0] towards points[1];
	}
	
	
	action create_rooms(int i) {
		
		geometry ref_geom <-  shape rotated_by - angle_ref;
		
		room_size <- min(room_size, shape.width * room_scale,shape.height * room_scale); 
		
		list<geometry> room_geom <- ref_geom to_squares(room_size);
		list<geometry> gg;
		loop r over: room_geom {
			geometry r_s <- r scaled_by room_scale;
			if r_s.area > 0.3 * (room_size*room_size) {
				gg << r_s;
			}
		}
		ref_geom <- geometry_collection([ref_geom.contour] + gg);
		
		ref_geom <- ref_geom rotated_by angle_ref;
		ref_geom <- ref_geom translated_by (envelope(shape).location - envelope(ref_geom).location);
		
		loop g over: ref_geom.geometries{
			if (g.perimeter < ((0.99) * shape.perimeter)) {
				create Room with: (shape:g scaled_by room_scale, bd:self, floor:i) {
					myself.rooms[i] << self;
					building <- int(bd);
					type <- empty(myself.types_room) ? "" : myself.types_room.keys[rnd_choice(myself.types_room.values)];
					if (type = "room") {
						float size <- shape.area / area_per_bed;
						list<geometry> squares <- shape to_squares (size, true);
						loop sq over: squares {
							create Bed with: (shape:(rectangle(2.2,1.5) at_location sq.location) rotated_by angle_ref, room_id:id, building:building, floor:floor) {
								if !(myself covers self) {
									do die;
								} else {
									myself.beds << self;
									
								}
									
							}
						}
					}
				}
			}
		}
		
		
	}
	aspect default {
		draw shape color: #pink ;
	}
}

experiment generating_rooms_path type: gui {
	
	action _init_ {
		create simulation with:(obstacles_path:buildings_path);
	}
	output {
		display map type: opengl axes: false{
			species Building ;
			species Room;
			species Elevator;
			species Wall;
			species BuildingEntry;
			species Bed;
			
			species PedestrianPath refresh: false;
			
		}
	}
}
