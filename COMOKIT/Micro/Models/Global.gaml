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
 
import "../../Core/Models/Entities/Abstract Place.gaml"

import "Entities/Building Spatial Entities.gaml"
 
import "Building Synthetic Population.gaml"

import "Parameters.gaml"
 
global {
	species<BuildingIndividual> building_individual_species <- BuildingIndividual; // by default
	container<BuildingIndividual> all_building_individuals -> {container<BuildingIndividual>(building_individual_species.population+(building_individual_species.subspecies accumulate each.population))};
	Outside the_outside;

	
	list<shape_file> rooms_shape_file;
	list<shape_file> entrances_shape_file;
	list<shape_file> walls_shape_file;
	list<shape_file> pedestrian_path_shape_file;
	list<shape_file> free_spaces_shape_file;
	list<shape_file> open_area_shape_file;
	list<shape_file> beds_shape_file;
	list<shape_file> benches_shape_file;
	shape_file pedestrian_paths0_shape_file <- shape_file("../Datasets/Danang Hospital/pedestrian_paths.shp");

	shape_file rooms_shapefile <- shape_file("../Datasets/Danang Hospital/rooms.shp");
//	shape_file entrances_shape_file <- shape_file("../includes/entrances.shp");
	shape_file walls_shapefile <- shape_file("../Datasets/Danang Hospital/walls.shp");
	shape_file pedestrian_path_shapefile <- shape_file("../Datasets/Danang Hospital/pedestrian_paths.shp");
//	shape_file free_spaces_shape_file <- shape_file("../generated/free_spaces.shp");
//	shape_file open_area_shape_file <- shape_file("../generated/open_area.shp");
//	// beds and benches
//	shape_file beds_shape_file <- shape_file("../includes/beds.shp");
//	shape_file benches_shape_file <- shape_file("../includes/benches.shp");

	
	geometry shape <- envelope(envelope(pedestrian_path_shapefile) + envelope(walls_shapefile) + envelope(rooms_shapefile));

	graph pedestrian_network;
	list<Room> available_offices;
	
	list<Room> sanitation_rooms;
	
	date time_first_lunch <- nil;

	int nb_susceptible  <- 0 update: (BiologicalEntity count not(each.state in [latent, asymptomatic, presymptomatic, symptomatic]));
	int nb_latent <- 0 update: (BiologicalEntity count (each.state = latent));
	int nb_infected <- 0 update: (BiologicalEntity count (each.state in [asymptomatic, presymptomatic, symptomatic]));
	
	container<Room> rooms_list -> {container<Room>(Room.population+(Room.subspecies accumulate each.population))};
			
	list<geometry> open_area;
	bool morefloorfile <- false;

	init {
		// These will be overridden if they are put in ./Parameters.gaml
		starting_date <- date([2020,4,6,5,29,0]);
		final_date <- date([2020,4,20,18,0,0]);
		step <- 1#s;
		nb_step_for_one_day <- #day / step;
		seed <- 25.0;
		
		if(!morefloorfile){
			loop i from: 0 to: nb_floor - 1{
				rooms_shape_file << shape_file("../Datasets/Danang Hospital/rooms.shp");
				entrances_shape_file << shape_file("../Datasets/Danang Hospital/entrances.shp");
				walls_shape_file << shape_file("../Datasets/Danang Hospital/walls.shp");
				pedestrian_path_shape_file << shape_file("../Datasets/Danang Hospital/pedestrian_paths.shp");
				free_spaces_shape_file << shape_file("../Datasets/Danang Hospital/free_spaces.shp");
				open_area_shape_file << shape_file("../Datasets/Danang Hospital/open_area.shp");
				beds_shape_file << shape_file("../Datasets/Danang Hospital/beds.shp");
				benches_shape_file << shape_file("../Datasets/Danang Hospital/benches.shp");
			}
		}
		else{
			//add each shape_file to the list
		}
		
		create Outside ;
		the_outside <- first(Outside);
		do init_epidemiological_parameters;
		loop i from: 0 to: nb_floor - 1{
			open_area << first(open_area_shape_file[i].contents);
		}
		
		loop i from: 0 to: nb_floor - 1{
			do create_elements_from_shapefile(i);
		}
		
		pedestrian_network <- as_edge_graph(PedestrianPath);
		
		ask PedestrianPath {
			do build_intersection_areas pedestrian_graph: pedestrian_network;
		}
		
		ask Room sort_by (-1 * each.shape.area){
			ask(Room overlapping self) {
				if (type = myself.type and shape.area>0 and floor = myself.floor) {
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
			list<Wall> ws <- Wall where (each.floor = floor) overlapping self;
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
			if not empty((rooms_list where (each.floor = floor)) inside self ) {
				shape <- shape.contour;
			}
		}
		ask Room {
			list<Wall> ws <- Wall overlapping self where (each.floor = floor);
			loop w over: ws {
				if w covers self {
					do die;
				}
			}
		}
		ask rooms_list{
			geometry contour <- nil;

			float dist <- 10.0;
			int cpt <- 0;
			loop while: contour = nil {
				cpt <- cpt + 1;
				contour <- copy(shape.contour);
				ask Wall where (each.floor = floor) at_distance 2.0 {
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

				list<point> ents <- points_on (contour, 1.7);
				loop pt over:ents {
					create RoomEntrance with: [location::pt,my_room::self] {
						location <- location + point([0, 0, myself.floor*default_ceiling_height - location.z]);
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
		
		ask 1 among Doctor{
			headdoc <- true;
		}
		ask Doctor{
			do initalization;
		}
		ask 2 among (Doctor where (each.headdoc = false)){
			nightshift <- true;
		}
		ask 4 among Nurse{
			nightshift <- true;
		}
		ask Caregivers{
			do initalization;
		}
		
		do init_epidemiological_parameters;
		do init_sars_cov_2;
		
		
		ask initial_nb_infected among Caregivers{
			do define_new_case(original_strain);
			state <- init_state;
		}
	}
	
	action create_elements_from_shapefile (int fl){
		create Wall from: walls_shape_file[fl]{
			floor <- fl;
			location <- location + point([0, 0, floor*default_ceiling_height]);
		}
		create Room from: rooms_shape_file[fl]{
			floor <- fl;
			location <- location + point([0, 0, floor*default_ceiling_height]);
		}		
		ask Room {
			if type = multi_act {
				create CommonArea with: [shape::shape, type::type];
				do die;
			}
		}
		create BuildingEntrance from: entrances_shape_file[fl] with: (type:entrance) {
			floor <- fl;
			location <- location + point([0, 0, floor*default_ceiling_height]);
			if shape.area = 0.0 {
				shape <- shape + P_shoulder_length;

			}
		}
			/*geometry new_open_area <- first(open_area_shape_file[fl].contents);
			new_open_area <- new_open_area at_location (new_open_area[fl].location - translation);
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
			floor_cnt <- floor_cnt + 1;*/
		
		//create bed and bench
		create Bed from: beds_shape_file[fl]{
			floor <- fl;
			location <- location + point([0, 0, floor*default_ceiling_height]);
		}
		create BenchWait from: benches_shape_file[fl]{
			floor <- fl;
			location <- location + point([0, 0, floor*default_ceiling_height]);
		}
		ask Bed{
			room <- first(Room where (each.shape overlaps self.location and each.floor = self.floor));
		}
		create PedestrianPath from: pedestrian_path_shape_file[fl] {
			floor <- fl;
			location <- location + point([0, 0, floor*default_ceiling_height]);
			list<geometry> fs <- free_spaces_shape_file[fl] overlapping self;
			fs <- fs where (each covers shape); 
			free_space <- fs with_min_of (each.location distance_to location);
			// Workaround for a NPE in build_intersection_areas
			if free_space = nil {
				free_space <- shape + P_shoulder_length;
			}
		}
	}

	reflex fast_forward when: (BuildingIndividual first_with !(each.is_outside)) = nil {
		date next_date <- BuildingIndividual min_of (first(each.current_agenda_week.keys));
		if (next_date != nil) and (next_date >  current_date){
			float duration_period <- next_date - current_date;
			ask BuildingIndividual where (each.state = susceptible) {
				ask Outside {do outside_epidemiological_dynamic(myself, duration_period);}
				tick <- tick + round(duration_period / step);
			}
			ask rooms_list {
				do decrease_viral_load(viral_decrease/nb_step_for_one_day * duration_period / step);
			}
		
			starting_date <- next_date;
		}
	}

	reflex end when: current_date >= final_date {
		do pause;	
	}

}
