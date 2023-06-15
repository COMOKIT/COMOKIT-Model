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

import "../../Core/Models/Entities/Virus.gaml"

 
import "../../Core/Models/Entities/Abstract Place.gaml"

import "Entities/Building Spatial Entities.gaml"
  

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


	string buildings_path <- dataset_path + "Buildings.shp";
	string rooms_path <- dataset_path + "Rooms.shp" ;
	string elevators_path <- dataset_path + "Elevators.shp" ;
	
	string walls_path <- dataset_path + "Walls.shp" ;
	string area_entry_path <- dataset_path + "Area_entries.shp" ;
	string building_entry_path <- dataset_path + "Building_entries.shp" ;
	string room_entry_path <- dataset_path + "Room_entries.shp" ;
	
	
	string pedestrian_paths_path <- dataset_path+"pedestrian paths.shp";
	string open_area_path <- dataset_path+"open area.shp";
	
	geometry shape <- envelope(file(pedestrian_paths_path));

	
	map<list<int>,map<PedestrianPath,float>> move_weights;
	
	map<list<int>,graph> pedestrian_network;
	list<Room> available_offices;
	
	list<Room> sanitation_rooms;
	
	date time_first_lunch <- nil;

	int nb_susceptible  <- 0 update: (BiologicalEntity count not(each.state in [latent, asymptomatic, presymptomatic, symptomatic]));
	int nb_latent <- 0 update: (BiologicalEntity count (each.state = latent));
	int nb_infected <- 0 update: (BiologicalEntity count (each.state in [asymptomatic, presymptomatic, symptomatic]));
	
	int tot_localisation_failure;
	int tot_localisation;
	
	float floor_high <- 5.0 #m;
	float tolerance_dist <- 0.1;
	
	
	container<Room> rooms_list -> {container<Room>(Room.population+(Room.subspecies accumulate each.population))};
			
	list<geometry> open_area;
	
	map<list<int>,list<unit_cell>> unit_cells; 
	virus viral_agent;
	
	int floor_map <- 0 ;
	int building_map <- -1 ;
	Building selected_bd;
	
	init {
		create IndividualScheduler;
		step <- step_duration;
	 	nb_step_for_one_day <- #day / step;
		create Outside ;
		the_outside <- first(Outside);
		do init_epidemiological_parameters;
		create AreaEntry from: file(area_entry_path);
		create Room from: file(rooms_path);
		create Building from: file(buildings_path);
		create Wall from: file(walls_path);
		create BuildingEntry from: file(building_entry_path);
		create RoomEntry from: file(room_entry_path);
		create Elevator from: file(elevators_path);
		
		create OpenArea from: file(open_area_path);
		create PedestrianPath from: file(pedestrian_paths_path);
		
		map<int, list<RoomEntry>> re <- RoomEntry group_by each.room_id;
		map<int, list<Room>> r_bd <- Room group_by each.building;
		map<int, list<Elevator>> el_bd <- Elevator group_by each.building;
		map<int, list<BuildingEntry>> en_bd <- BuildingEntry group_by each.building;
		map<int, Building> bds <- Building as_map (int(each)::each);
		
		ask Building {
			entrances <- en_bd[int(self)];
			rooms <- r_bd[int(self)] group_by each.floor;
			elevators <- map<int, list<Elevator>>(el_bd[int(self)] != nil ? (el_bd[int(self)] group_by each.floor) : []);
			
			loop i over:rooms.keys {
				list<geometry> gg <- shape to_squares(unit_cell_size, true); 
				create unit_cell from: gg with: (building:int(self), floor:i) returns: cells;
				unit_cells[int(self),i] <- cells; 
				people[i] <- [];
			}
		}
		ask Room {
			location <- location + {0,0, floor * floor_high};
			entrances <- re[int(self)];
			my_building <- bds[building];
			
		}
		
		ask Elevator {
			location <- location + {0,0, floor * floor_high};
			my_building <- bds[building];
		}
		
		ask Wall {
			shape <- shape + 0.01 ;
			location <- location + {0,0, floor * floor_high};
		}
		
		ask OpenArea {
			location <- location + {0,0, floor * floor_high};
		}
		
		ask PedestrianPath {
			location <- location + {0,0, floor * floor_high};
			surface <- shape.perimeter * lane_width;
		}
		
		map<list<int>,list<PedestrianPath>> pedestrian_paths <-  PedestrianPath group_by ([each.building, each.floor]);
		
		loop k over: pedestrian_paths.keys {
			pedestrian_network[k] <- graph(as_edge_graph(pedestrian_paths[k]));
			move_weights[k] <- pedestrian_paths[k] as_map (each::each.shape.perimeter);
		}
		//pedestrian_network <- as_edge_graph(PedestrianPath);
		
		do create_activities;
		
		//map<string, list<Room>> rooms_type <- Room group_by each.type;
		
		do create_individuals;
		ventilation_viral_decrease <- ventilated_viral_air_decrease_per_day;
	
		do init_epidemiological_parameters;
		do init_sars_cov_2;
		viral_agent <- viruses first_with (each.name = variant);
		ask num_infected_init among (agents of_generic_species BuildingIndividual) { 
			do define_new_case(myself.viral_agent);
		}
		all_individuals <- agents of_generic_species BuildingIndividual;
		ask all_individuals  { do initialise_epidemiological_behavior();}
            
		//selected_bd <- Building with_max_of (each.shape.area);
		//building_map <- int(selected_bd);
	}

	
	action create_individuals;
	
	
	
	reflex update_moving_weight when: every(udpate_path_weights_every) {
		ask PedestrianPath where each.update_coeff {
			density <- nb_people / surface;
			coeff <- density = 0.0 ? 1.0 : (1 - exp(- lambda  * (1 / density - 1/density_max_admi)));
			map<PedestrianPath,float> vals <- move_weights[[building, floor]];
			vals[self] <- shape.perimeter / coeff;
		}
		
	}
	
	
	reflex end when: current_date >= final_date {
		do pause;	
	}

}
