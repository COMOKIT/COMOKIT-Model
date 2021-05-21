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

import "Parameters.gaml"
 
import "Entities/Building Spatial Entities.gaml"

 
global {
	species<BuildingIndividual> building_individual_species <- BuildingIndividual; // by default
	container<BuildingIndividual> all_building_individuals -> {container<BuildingIndividual>(building_individual_species.population+(building_individual_species.subspecies accumulate each.population))};
	
	shape_file rooms_shape_file <- shape_file(building_dataset_path + "Rooms.shp");
	shape_file entrances_shape_file <- shape_file(building_dataset_path + "Entrances.shp");
	shape_file walls_shape_file <- shape_file(building_dataset_path +"Walls.shp");
	shape_file pedestrian_path_shape_file <- shape_file(building_dataset_path+"pedestrian paths.shp");
	shape_file free_spaces_shape_file <- shape_file(building_dataset_path+ "free spaces.shp");
	shape_file open_area_shape_file <- shape_file(building_dataset_path+"open area.shp");
	
	geometry shape <- envelope(envelope( pedestrian_path_shape_file) + envelope(walls_shape_file) + envelope(rooms_shape_file));
	graph pedestrian_network;
	list<Room> available_offices;
	
	list<Room> sanitation_rooms;
	
	date time_first_lunch <- nil;

	int nb_susceptible  <- 0 update: (BiologicalEntity count not(each.state in [latent, asymptomatic, presymptomatic, symptomatic]));
	int nb_latent <- 0 update: (BiologicalEntity count (each.state = latent));
	int nb_infected <- 0 update: (BiologicalEntity count (each.state in [asymptomatic, presymptomatic, symptomatic]));
	
	container<Room> rooms_list -> {container<Room>(Room.population+(Room.subspecies accumulate each.population))};
			
			
	geometry open_area ;
	
	
	init {
		create outside;
		the_outside <- first(outside);
		do init_epidemiological_parameters;
		open_area <- first(open_area_shape_file.contents);
		do create_elements_from_shapefile;
		create PedestrianPath from: pedestrian_path_shape_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			 fs <- fs where (each covers shape); 
			 free_space <- fs with_min_of (each.location distance_to location);
		}
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
			float dist <-0.5;
			int cpt <- 0;
			loop while: contour = nil {
				cpt <- cpt + 1;
				contour <- copy(shape.contour);
				ask Wall at_distance 2.0 {
					contour <- contour - (shape +dist);
			
				}
				if cpt < limit_cpt_for_entrance_room_creation {
					ask (Room  + CommonArea) at_distance 1.0 {
						contour <- contour - (shape + dist);
					}
				}
				if cpt = 20 {
					break;
				}
				dist <- dist * 0.5;	
			} 
			if contour != nil {
				list<point> ents <- points_on (contour, 2.0);
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
		do create_people(nbDesk);
		
		
		ask initial_nb_infected among BuildingIndividual{
			state <- init_state;
		}
	}
	
	
	action create_elements_from_shapefile {
		create Wall from: walls_shape_file;
		create Room from: rooms_shape_file ;
		ask Room {
			if type = multi_act {
				create CommonArea  with: [shape::shape, type::type];
				do die;
			}
		}
		create BuildingEntrance from: entrances_shape_file with: (type:entrance) {
			if shape.area = 0.0 {
				shape <- shape + P_shoulder_length;
			}
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
			ask rooms_list  {
				do decrease_viral_load(viral_decrease/nb_step_for_one_day * duration_period / step);
			}
		
			starting_date <- next_date;
		}
	}
	reflex end_simulation when: current_date >= final_date {
		do pause;	
	}
				
}