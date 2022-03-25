/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Rooms represent in COMOKIT spatial entities where Individuals gather 
* to undertake their Activities. They are provided with a viral load to
* enable environmental transmission. 
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/

@no_experiment

model CoVid19


import "BuildingIndividual.gaml"

import "../Parameters.gaml"


import "../Constants.gaml"
 
species Outside parent: AbstractPlace;
	
species Room parent: AbstractPlace {
	int nb_affected;
	PedestrianPath closest_path; 
	geometry init_place;
	list<RoomEntrance> entrances;
	list<PlaceInRoom> places;
	list<PlaceInRoom> available_places;
	int num_places;
	bool isVentilated <- false;
	list<BuildingIndividual> people_inside;
	geometry inside_geom;
	bool allow_transmission -> {allow_air_transmission};
	float viral_decrease -> {(isVentilated ? ventilated_viral_air_decrease_per_day : basic_viral_air_decrease_per_day)} ;
	float ceiling_height <- default_ceiling_height;
	int floor;
	
	action intialization {
		inside_geom <- (copy(shape) - P_shoulder_length);
		ask Wall where (each.floor = floor) overlapping self {
			geometry g <- myself.inside_geom - (self + P_shoulder_length);
			if g != nil {
				myself.inside_geom <- g.geometries with_max_of each.area;
			}
		}
		if (inside_geom = nil) {
			inside_geom <- shape;
		}
		list<geometry> squares;
		map<geometry, PlaceInRoom> pr;
		if (density_scenario = "distance") or not(type in workplace_layer) {
			squares <-  to_squares(inside_geom, distance_people, true) where (each.location overlaps inside_geom);
		}
		else if (density_scenario= "num_people_room"){
			num_places <-num_people_per_room;
			int nb <- num_places;
			loop while: length(squares) < num_places {
				squares <-  num_places = 0 ? []: to_squares(inside_geom, nb, true) where (each.location overlaps inside_geom);
				nb <- nb +1;
			}
			if (length(squares) > num_places) {
				squares <- num_places among squares;
			}
		}
		else if density_scenario in ["num_people_building"] {
			int nb <- num_places;
			loop while: length(squares) < num_places {
				squares <-  num_places = 0 ? []: to_squares(inside_geom, nb, true) where (each.location overlaps inside_geom);
				nb <- nb +1;
			}
			if (length(squares) > num_places) {
				squares <- num_places among squares;
			}
		} 
		if not empty(squares) and  density_scenario != "data"{
			loop g over: squares{
				create PlaceInRoom {
					location <- g.location;
					pr[g] <- self;
					myself.places << self;
				}
			} 
			
			if empty(places) {
				create PlaceInRoom {
					location <- myself.location;
					myself.places << self;
				}
			} 
				
			if (length(places) > 1 and separator_proba > 0.0) {
				graph g <- as_intersection_graph(squares, 0.01);
				list<list<PlaceInRoom>> ex;
				loop e over: g.edges {
					geometry s1 <- (g source_of e);
					geometry s2 <- (g target_of e);
					PlaceInRoom pr1 <- pr[s1];
					PlaceInRoom pr2 <- pr[s2];
					if not([pr1,pr2] in ex) and not([pr2,pr1] in ex) {
						ex << [pr1,pr2];
						if flip(separator_proba) {
							geometry sep <- ((s1 + 0.1)  inter (s2 + 0.1)) inter self;
							create Separator with: [shape::sep,places_concerned::[pr1,pr2]];
						}
					}
				} 
			}
			
		}
		available_places <- copy(places);
		
	}
	bool is_available {
		return nb_affected < length(places);
	}
	PlaceInRoom get_target(BuildingIndividual p, bool random_place){
		if empty(available_places){
			return nil;
		}
		PlaceInRoom place <- random_place ? one_of(available_places) : (available_places with_max_of each.dists);
		available_places >> place;
		return place;
	}
	
	
	aspect default {
		if (display_room_status and show_floor[floor]) {
			draw shape at: location color: blend(#red, #green, min(1,(empty(viral_load) ? 0.0 :sum(viral_load.values))*coeff_visu_virus_load_room/(shape.area)));
		}
		if (display_room_entrance and show_floor[floor]) {
			loop e over: entrances {draw circle(0.2)-circle(0.1) at: {e.location.x,e.location.y, e.location.z + 0.001} color: #yellow border: #black;}
		}
		if (display_desk and show_floor[floor]) {
			loop p over: places {draw square(0.2) at: {p.location.x,p.location.y, p.location.z + 0.001} color: #gray border: #black;}
		}
		if(isVentilated and show_floor[floor]){
			draw shape color: blend(#red, #green, min(1,(empty(viral_load) ? 0.0 :sum(viral_load.values))*coeff_visu_virus_load_room/(shape.area)));
//		 	draw image_file("../../../Images/fan.png") size: 3;	

		}
	}
	
}

species CommonArea parent: Room ;
 
species Wall frequency: 0{
	int floor;
	aspect default {
		if(show_floor[floor]){
			draw shape + P_shoulder_length at: location color: #white depth: default_ceiling_height;
		}
	}
}

species BenchWait frequency: 0{
	int floor;
	bool is_occupied <- false;
	aspect default{
		if show_floor[floor]{
			draw rectangle(0.4,0.5) at: location color: #orange depth: 0.6;
		}
 	}
}

species Bed frequency: 0{
	int floor;
	Room room;
	bool is_occupied <- false;
	aspect default{
		if show_floor[floor]{
			draw rectangle(1.2, 2.0) at: location color: #white depth: 0.6;
		}
	}
}

species PedestrianPath skills: [pedestrian_road]{
	int floor;
	reflex clean_ {
		agents_on <-  agents_on where (not dead(each) and not BuildingIndividual(each).is_outside);
	}
	aspect default {
		if (display_pedestrian_path and show_floor[floor]) {
			draw shape at: location color: #red width:2;
		}
	}
	
	aspect free_space_aspect {
		if (display_free_space) {
			draw free_space at: location color: #pink border: #black;
		}
	}
}

species PlaceInRoom frequency: 0{
	float dists;
}

species Separator frequency: 0{
	list<PlaceInRoom> places_concerned; 
	aspect default {
		draw shape color: #lightblue;
	}
}


species BuildingEntrance parent: Room {
	PlaceInRoom get_target(BuildingIndividual p, bool random_place){
		return random_place ? one_of(places) : places closest_to p;
	}

	aspect default {
		if (display_building_entrance and show_floor[floor]) {
			draw shape at: location color: #yellow;
		}
	}
}


species RoomEntrance {
	geometry queue;
	Room my_room;
	list<BuildingIndividual> people_waiting;
	list<point> positions;
	
	geometry waiting_area;
	
	init {
		if (queueing) {
			do default_queue;
		}
		
	}
	
	geometry create_queue(geometry line_g, int nb_places) {
		
		//line_g <- line_g at_location (line_g.location );
		bool consider_rooms <-  (Room first_with ((each - 0.1) overlaps location)) = nil;
		point vector <-  (line_g.points[1] - line_g.points[0]) / line_g.perimeter;
		float nb <- max(1, nb_places) * distance_queue ;
		geometry queue_tmp <- line([location,location + vector * nb ]);
		geometry q_s <- copy(queue_tmp);
		if (queue_tmp intersects my_room ) {
			geometry line_g2 <- line(reverse(queue_tmp.points));
			if (line_g2 inter my_room).perimeter < (queue_tmp inter my_room).perimeter {
				queue_tmp <- line_g2;
			}
		}
		list<geometry> ws <- (Wall overlapping (queue_tmp+ 0.2)) collect each.shape;
		ws <- ws +(((RoomEntrance - self) where (each.queue != nil)) collect each.queue) overlapping (queue_tmp + 0.2);
		if not empty(ws) {
			loop w over: ws {
				geometry qq <- queue_tmp - (w + 0.2);
				if (qq = nil) {
					queue_tmp <- queue_tmp - (w + 0.01);
				} else {
					queue_tmp <- qq;
				}
				if (queue_tmp != nil) {
					queue_tmp <- queue_tmp.geometries with_min_of (each distance_to self);
				}
			}
		}
		if (queue_tmp != nil) {
			vector <- (queue_tmp.points[1] - queue_tmp.points[0]);// / queue.perimeter;
			queue_tmp <- line([location,location + vector * rnd(0.2,1.0)]);
		} else {
			vector <- (q_s.points[1] - q_s.points[0]);// / queue.perimeter;
			queue_tmp <- line([location,location + vector * (0.1 / q_s.perimeter)]);
		}
		
		int cpt <- 0;
		loop while: (queue_tmp.perimeter / distance_queue) < nb_places {
			if (cpt = 10) {break;}
			cpt <- cpt + 1;
			point pt <- last(queue_tmp.points);
			
			line_g <- line([queue_tmp.points[length(queue_tmp.points) - 2],queue_tmp.points[length(queue_tmp.points) - 1]]) rotated_by 90;
			if (line_g.perimeter = 0) {
				break;
			}
			line_g <- line_g at_location last(queue_tmp.points );
			point vector_ <-  (line_g.points[1] - line_g.points[0]) / line_g.perimeter;
			float nb_ <- max(0.5,(max(1, nb_places) * distance_queue) - queue_tmp.perimeter);
			queue_tmp <-  line(queue_tmp.points + [pt + vector_ * nb_ ]);
			list<geometry> ws_ <-Wall overlapping (queue_tmp+ 0.2);
			ws_ <- ws_ +(((RoomEntrance - self) where (each.queue != nil)) collect each.queue) overlapping (queue_tmp + 0.2);
			if (consider_rooms) {ws_ <- ws_ +  Room overlapping (queue_tmp+ 0.2);}
			
			if not empty(ws_) {
				loop w over: ws_ {
					geometry g <- queue_tmp - w ;
					if (g != nil) {
							queue_tmp <- g.geometries with_min_of (each distance_to pt);
					}
				
				}
			}
			
		}
		return queue_tmp;
		
	}
	action default_queue {
		int nb_places <- my_room.type = "sanitation" ? 20 : length(my_room.places);
		geometry line_g;
		float d <- #max_float;
		if length(my_room.shape.points) > 1 {
				loop i from: 0 to: length(my_room.shape.points) - 2 {
				point pt1 <- my_room.shape.points[i];
				point pt2 <- my_room.shape.points[i+1];
				geometry l <- line([pt1, pt2]);
				if (self distance_to l) < d {
					line_g <- l;
					d <- self distance_to l;
				}
			}
			
			geometry g1 <- create_queue(line_g rotated_by 90, nb_places);
			geometry g2 <- create_queue(line_g rotated_by -90,nb_places);
			
			
			if g1 != nil {
				loop r over: rooms_list overlapping g1 {
					g1 <- g1 - r;
					if g1 = nil {break;}
				}
			}
			
			if g2 != nil {
				loop r over: rooms_list overlapping g2 {
					g2 <- g2 - r;
					if g2 = nil {break;}
				}
			}
			
			geometry l1 <- (g1 = nil) ? nil : line([last(g1.points), ((PedestrianPath with_min_of (each distance_to last(g1.points))) closest_points_with last(g1.points))[0]]);
			geometry l2 <- (g2 = nil) ? nil :line([last(g2.points), ((PedestrianPath with_min_of (each distance_to last(g2.points))) closest_points_with last(g2.points))[0]]);
			
			if (g1 = nil) {
				queue <- g2;
			} else if (g2 = nil) {
				queue <- g1;
			} else {
				if not empty (Wall overlapping l1) {
					if empty (Wall overlapping l2) {
						queue <- g2;
					} else {
						queue <- [g1,g2] with_max_of each.perimeter;
					}
				} else {
					if not empty (Wall overlapping l2) {
						queue <- g1;
					} else {
						queue <- [g1,g2] with_max_of each.perimeter;
					}
				}
			}
			do manage_queue();
			
		}
	}
	
	action manage_queue {
		positions <- queue.perimeter > 0 ?  queue points_on (distance_queue) : []; 
		waiting_area <- queue;
	}
	
	action add_people(BuildingIndividual someone) {
		if not empty(positions) {
			if (length(people_waiting) < length(positions)) {
				someone.location <- positions[length(people_waiting)];
			} else {
				someone.location  <- any_location_in(waiting_area);
			}
		}
		people_waiting << someone;
	}
	
	point get_position {
		if empty(positions) {return location;}
		
		else {
			if (length(people_waiting) < length(positions)) {
				return positions[length(people_waiting)];
			} else {
				return any_location_in(waiting_area);
			}
			
		}
	}
	
	
	reflex manage_visitor when: not empty(people_waiting) {
		int nb <- 0;
		if (my_room.type != "sanitation") {
			if every(waiting_time_entrance) {
				nb <-1;
			}
		} else {
			nb <- nb_people_per_sanitation - (my_room.people_inside count (each.using_sanitation));
		}
		if nb > 0 {
			loop times: nb {
				BuildingIndividual the_first_one <- first(people_waiting);
				people_waiting >> the_first_one;
				the_first_one.in_line<-false;
				if (not empty(people_waiting) and not empty(positions)) {
					loop i from: 0 to: length(people_waiting) - 1 {
						if (i < length(positions)) {
							people_waiting[i].location <- positions[i];
						}
					}
				}
			}
		} 
	}
	 
	aspect queuing {
//		if(queueing){
//		    draw queue at: location color: #blue;	
//	  }	 
		draw circle(1) at: location color: #yellow;
	}
}

// TODO: viral_load is now a map
grid unit_cell parent: AbstractPlace cell_width: unit_cell_size cell_height: unit_cell_size neighbors: 8 schedules: unit_cell where (each.viral_load[original_strain] > 0) {
	bool allow_transmission -> {allow_local_transmission};
	float viral_decrease -> {basic_viral_local_decrease_per_day };
	aspect default{
		if (display_infection_grid){
			//TODO: viral_load is now a map
			draw shape color:blend(#green, #red, 1 - (coeff_visu_virus_load_cell * viral_load[original_strain]))  ;	
		}
	}
}