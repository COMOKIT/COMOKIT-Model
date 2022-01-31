/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* This file contains global declarations of actions and attributes, used
* mainly for the purpose of initialising the model in experiments
* 
* Author: Benoit Gaudou, Damien Philippon, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19
 
import "Building Synthetic Population.gaml"
import "Entities/Building Spatial Entities.gaml"
import "Parameters.gaml"
 
global {
	species<BuildingIndividual> building_individual_species <- BuildingIndividual; // by default
	container<BuildingIndividual> all_building_individuals -> {container<BuildingIndividual>(building_individual_species.population+(building_individual_species.subspecies accumulate each.population))};
	
	list<string> floor_dirs <- [
		"Danang Hospital/nephrology_department", "Danang Hospital/nephrology_department"
	];
	int num_layout_rows <- 1;
	int num_layout_columns <- 2;
	// TODO: make padding works properly
	float padding <- 0#m;

	// TODO: flexible world shape does not work because of CRS mismatch?	
//	float max_floor_w <- max(floor_dirs accumulate envelope(shape_file("../../Datasets/" + each + "/rooms.shp")).width);
//	float max_floor_h <- max(floor_dirs accumulate envelope(shape_file("../../Datasets/" + each + "/rooms.shp")).height);
//	geometry shape <- rectangle(max_floor_w * num_layout_columns, max_floor_h * num_layout_rows);

	// so this is hardcoded for now
	shape_file biggest_floor <- shape_file("../../Datasets/" + floor_dirs[0] + "/walls.shp");
	geometry shape <- envelope(biggest_floor) scaled_by (max(num_layout_rows, num_layout_columns) + 0.5);

	graph pedestrian_network;
	list<Room> available_offices;
	
	list<Room> sanitation_rooms;
	
	date time_first_lunch <- nil;

	int nb_susceptible  <- 0 update: (BiologicalEntity count not(each.state in [latent, asymptomatic, presymptomatic, symptomatic]));
	int nb_latent <- 0 update: (BiologicalEntity count (each.state = latent));
	int nb_infected <- 0 update: (BiologicalEntity count (each.state in [asymptomatic, presymptomatic, symptomatic]));
	
	container<Room> rooms_list -> {container<Room>(Room.population+(Room.subspecies accumulate each.population))};
			
	geometry open_area;
	
	init {
		// These will be overridden if they are put in ./Parameters.gaml
		starting_date <- date([2020,4,6,5,29,0]);
		final_date <- date([2020,4,20,18,0,0]);
		step <- 1#s;
		nb_step_for_one_day <- #day / step;
		seed <- 25.0;
		
		if num_layout_columns * num_layout_rows < length(floor_dirs) {
			error string(num_layout_columns) + " cols and " + string(num_layout_rows) + " rows is not enough for " + 
				length(floor_dirs) + " floors";
		}
		do create_elements_from_shapefile;
		create outside;
		the_outside <- first(outside);
		do init_epidemiological_parameters;
	
		pedestrian_network <- as_edge_graph(PedestrianPath);
		
		ask PedestrianPath {
			do build_intersection_areas pedestrian_graph: pedestrian_network;
		}
		
		ask Room sort_by (-1 * each.shape.area){
			ask(Room overlapping self) {
				if (type = myself.type and shape.area>0) {
					if ((self inter myself).area / shape.area) > 0.8 {
						do die;	
					} else {
						shape <- shape - myself.shape;
					}
				}
			}
		} 
		pedestrian_network <- pedestrian_network with_weights (PedestrianPath as_map (each::each.shape.perimeter * (empty(Room overlapping each) ? 1.0 : 10.0)));
	
		ask rooms_list{
			isVentilated <- flip(ventilation_proba);
			list<Wall> ws <- Wall overlapping self;
			loop w over: ws {
				if (w covers self) {
					w.shape <- w.shape - (self + 0.5);
				}
			}
		} 
		
		
		if (density_scenario = "num_people_building") {
			list<Room> offices_list <- Room where (each.type in workplace_layer);
			float tot_area <- offices_list sum_of each.shape.area;
			ask offices_list {
				num_places <- max(1,round(num_people_per_building * shape.area / tot_area));
			}
			int nb <- offices_list sum_of each.num_places;
			if (nb > num_people_per_building) and (length(offices_list) > num_people_per_building) {
				loop times: nb - num_people_per_building {
					Room r <- one_of(offices_list where (each.num_places > 1));
					r.num_places <- r.num_places - 1;	
				}
			} else if (nb < num_people_per_building) {
				loop times: num_people_per_building - nb{
					Room r <- one_of(offices_list);
					r.num_places <- r.num_places + 1;	
				}
			}
			
		} 
		ask rooms_list{
			do intialization;
		}
		
		ask Wall {
			if not empty((rooms_list) inside self ) {
				shape <- shape.contour;
			}
		}
		ask Room {
			list<Wall> ws <- Wall overlapping self;
			loop w over: ws {
				if w covers self {
					do die;
				}
			}
		}
		ask rooms_list{
			geometry contour <- nil;
			// NOTE: change this value if room entrances look weird!
			float dist <- 10.0;
			int cpt <- 0;
			loop while: contour = nil {
				cpt <- cpt + 1;
				contour <- copy(shape.contour);
				ask Wall at_distance 2.0 {
					contour <- contour - (shape +dist);
				}
				if cpt < limit_cpt_for_entrance_room_creation {
					ask (Room + CommonArea) at_distance 1.0 {
						contour <- contour - (shape + dist);
					}
				}
				if cpt = 20 {
					break;
				}
				dist <- dist * 0.5;
			} 
			if contour != nil {
				// NOTE: the value in points_on seems to be the spacing between room entrances
				list<point> ents <- points_on (contour, 1.7);
				loop pt over:ents {
					create RoomEntrance with: [location::pt,my_room::self] {
						myself.entrances << self;
					}
				
				}
			}
			ask places {
				point pte <- (myself.entrances closest_to self).location;
				dists <- self distance_to pte;
			}
		}
		do create_activities;
		
		map<string, list<Room>> rooms_type <- Room group_by each.type;
		available_offices <- (workplace_layer accumulate rooms_type[each]) where (each != nil and each.is_available());
		
		ask BuildingEntrance {
			if (not empty(PedestrianPath)) {
				list<PedestrianPath> paths <- PedestrianPath at_distance 10.0;
				closest_path <-  paths with_min_of (each.free_space distance_to location);
				
				if (closest_path != nil) {
					init_place <- shape inter closest_path ;
					if (init_place = nil) {
						init_place <- (shape closest_points_with closest_path)[0]; 
					}
				}else {
					init_place <- shape; 
				}
			} else {
				init_place <- shape;
			}
		}
	
		int nbDesk<-length(Room accumulate each.available_places);
		do create_recurring_people;
		
		
		ask initial_nb_infected among BuildingIndividual{
			state <- init_state;
		}
	}

	action create_elements_from_shapefile {
		int i <- 0;
		int j <- 0;
		int floor_cnt <- 0;
		
		float world_w <- world.shape.width;
		float world_h <- world.shape.height;
		point world_center <- {world_w / 2, world_h / 2};
		loop floor_name over: floor_dirs {
			shape_file rooms_shape_file <- shape_file("../../Datasets/" + floor_name + "/rooms.shp");
			shape_file entrances_shape_file <- shape_file("../../Datasets/" + floor_name + "/entrances.shp");
			shape_file walls_shape_file <- shape_file("../../Datasets/" + floor_name + "/walls.shp");
			shape_file pedestrian_path_shape_file <- shape_file("../../generated/" + floor_name + "/pedestrian_paths.shp");
			shape_file free_spaces_shape_file <- shape_file("../../generated/" + floor_name + "/free_spaces.shp");
			shape_file open_area_shape_file <- shape_file("../../generated/" + floor_name + "/open_area.shp");

			geometry floor_shape <- envelope(envelope(pedestrian_path_shape_file) + envelope(walls_shape_file) + envelope(rooms_shape_file));
			float floor_w <- floor_shape.width;
			float floor_h <- floor_shape.height;
			point floor_center <- {
				i * world_w / num_layout_columns + floor_w / 2 + padding / 2,
				j * world_h / num_layout_rows + floor_h / 2 + padding / 2
			};
			point translation <- world_center - floor_center;
					
			create Wall from: walls_shape_file {
				location <- location - translation;
			}
			create Room from: rooms_shape_file {
				location <- location - translation;
				if floor = 0 {
					floor <- floor_cnt;
				}
			}
			
			geometry new_open_area <- first(open_area_shape_file.contents);
			new_open_area <- new_open_area at_location (new_open_area.location - translation);
			if open_area = nil {
				open_area <- new_open_area;
			} else {
				open_area <- open_area + new_open_area;
			}

			create PedestrianPath from: pedestrian_path_shape_file {
				list<geometry> fs <- free_spaces_shape_file overlapping self;
				fs <- fs where (each covers shape); 
				free_space <- fs with_min_of (each.location distance_to location);
				// Workaround for a NPE in build_intersection_areas
				if free_space = nil {
					free_space <- shape + P_shoulder_length;
				}
				
				location <- location - translation;
				free_space <- free_space at_location (free_space.location - translation);
			}

			i <- i + 1;
			if i >= num_layout_columns {
				i <- 0;
				j <- j + 1;
			}
			floor_cnt <- floor_cnt + 1;
		}
	}

	reflex fast_forward when: (BuildingIndividual first_with !(each.is_outside)) = nil {
		date next_date <- BuildingIndividual min_of (first(each.current_agenda_week.keys));
		if (next_date != nil) and (next_date >  current_date){
			float duration_period <- next_date - current_date;
			ask BuildingIndividual where (each.state = susceptible) {
				ask outside {do outside_epidemiological_dynamic(myself, duration_period);}
				tick <- tick + round(duration_period / step);
			}
			ask rooms_list {
				do decrease_viral_load(viral_decrease/nb_step_for_one_day * duration_period / step);
			}
		
			starting_date <- next_date;
		}
	}

	reflex end_simulation when: current_date >= final_date {
		do pause;	
	}
}
