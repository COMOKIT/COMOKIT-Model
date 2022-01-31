/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* The main species of COMOKIT: a Biological Entity that can perform 
* Activities in a Building.
* 
* Author:Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19

import "BuildingActivity.gaml"
 
import "../Constants.gaml"
 
import "Building Spatial Entities.gaml" 

import "../../Entities/Individual.gaml"


species BuildingIndividual parent: AbstractIndividual schedules: shuffle(BuildingIndividual where (each.clinical_status != dead)) skills: [pedestrian] {
 	Room working_place;
	PlaceInRoom working_desk;
	map<date, BuildingActivity> current_agenda_week;
	BuildingActivity current_activity;

	int current_floor;
	point current_target;
	list<point> targets;
	point dst_point;
	Room dst_room;
	Room current_room;

	bool has_place <- false;
	PlaceInRoom target_place;
	float speed <- max(2,min(6,gauss(4,1))) #km/#h;
	bool is_slow <- false update: false;
	bool is_slow_real <- false;
	int counter <- 0;
	bool in_line <- false;
	RoomEntrance the_entrance;
	bool waiting_sanitation <- false;
	bool using_sanitation <- false;
	float sanitation_time <- 0.0;
	bool wandering <- false;
	bool goto_a_desk <- false;
	point target_desk;
	float wandering_time_ag;
	
	init {
		is_outside <- true;
		do initialise_epidemiological_behavior;
	
		pedestrian_species <- [BuildingIndividual];
		obstacle_species <- [BuildingIndividual, Wall];
		// Params for pedestrian skill
		obstacle_consideration_distance <-P_obstacle_consideration_distance;
		pedestrian_consideration_distance <-P_pedestrian_consideration_distance;
		shoulder_length <- P_shoulder_length;
		avoid_other <- P_avoid_other;
		proba_detour <- P_proba_detour;
		minimal_distance <- P_minimal_distance;
		A_pedestrians_SFM <- P_A_pedestrian_SFM;
		A_obstacles_SFM <- P_A_obstacles_SFM;
		B_pedestrians_SFM <- P_B_pedestrian_SFM;
		B_obstacles_SFM <- P_B_obstacles_SFM;
		relaxion_SFM <- P_relaxion_SFM;
		gama_SFM <- P_gama_SFM;
		lambda_SFM <- P_lambda_SFM;
		use_geometry_waypoint <- P_use_geometry_target;
		tolerance_waypoint <- P_tolerance_target;
	}
	
	// To be defined	
	map<date, BuildingActivity> get_daily_agenda {
		return nil;
	}

	//#############################################################
	//Reflexes
	//#############################################################		
	reflex renew_agenda when: empty(current_agenda_week) {
		map<date, BuildingActivity> new_daily_agenda <- get_daily_agenda();
		if new_daily_agenda = nil {
			return;
		}

		date cd <- current_date;
		loop t over: new_daily_agenda.keys {
			// Apply the correct date
			date correct_time <- date([cd.year, cd.month, cd.day, t.hour, t.minute, t.second]);
			if correct_time < current_date {
				correct_time <- correct_time add_days 1;
			}
			current_agenda_week[correct_time] <- new_daily_agenda[t]; 
		}
	}
	
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: not is_outside and is_infectious
	{
		float start <- BENCHMARK ? machine_time : 0.0;
		//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		float reduction_factor <- viral_factor;
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic;
		}
		if(is_wearing_mask)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_wearing_mask;
		}
		
		//Performing environmental contamination
		if(allow_air_transmission and current_room != nil)
		{
			ask current_room
			{
				do add_viral_load(reduction_factor*basic_viral_air_increase_per_day / nb_step_for_one_day);
			}
		}
		 
		if(allow_local_transmission)
		{
			ask unit_cell(location)
			{
				do add_viral_load(reduction_factor*basic_viral_local_increase_per_day / nb_step_for_one_day);
			}
		}
		
		//Perform human to human transmission
		if allow_direct_transmission {
			float proba <- contact_rate*reduction_factor;
			//If the Individual is at home, perform transmission on the household level with a higher factor
			loop succesful_contact over: (BuildingIndividual at_distance infectionDistance) where (each.state = susceptible) {
				geometry line <- line([self,succesful_contact]);
				if empty(Wall overlapping line) {
					if not empty(Separator overlapping line) {
						proba <- proba * (1 - diminution_infection_rate_separator);
					}
					if flip(proba) {
						do infect_someone(succesful_contact);
					}
				}
			}
		}
		if BENCHMARK {bench["Individual.infect_others"] <- bench["Individual.infect_others"] + machine_time - start;}
	}

	//Reflex to trigger infection when outside of the commune
	reflex become_infected_outside when: is_outside and (state = susceptible){
		float start <- BENCHMARK ? machine_time : 0.0;
		ask outside {do outside_epidemiological_dynamic(myself, step);}
		if BENCHMARK {bench["Individual.become_infected_outside"] <- bench["Individual.become_infected_outside"] + machine_time - start;}
	}

	//Reflex to update disease cycle
	reflex update_epidemiology when:(state!=removed) {
		float start <- BENCHMARK ? machine_time : 0.0;
		if(allow_air_transmission and (not is_infected)and(self.current_room!=nil))
		{
			// TODO: viral_load is now a map, but idk how to properly update these formula
			if(flip(current_room.viral_load[original_strain]*successful_contact_rate_building/ (current_room.shape.area * current_room.ceiling_height)))
			{
				infectious_contacts_with[current_place] <- define_new_case(original_strain);
			}
		}
		if(allow_local_transmission and (not is_infected))
		{
			unit_cell current_cell <- unit_cell(location);
			if(flip(current_cell.viral_load[original_strain]*successful_contact_rate_building))
			{
				infectious_contacts_with[current_place] <- define_new_case(original_strain);
			}
		}
		do update_wear_mask();
		if BENCHMARK {bench["Individual.update_epidemiology"] <- bench["Individual.update_epidemiology"] + machine_time - start;}
	}

	reflex common_area_behavior when: not is_outside and species(dst_room) = CommonArea and (location overlaps dst_room) {
		if wandering {
			if (wandering_time_ag > wandering_time) {
				if (target_place != nil) {
					if final_waypoint = nil and ((location distance_to target_place) > 2.0){
						do compute_virtual_path pedestrian_graph:pedestrian_network target: target_place ;
					}
					if (final_waypoint = nil) {
						do goto target: target_place;
					} else {
						do walk;
					}
					
					if not(location overlaps dst_room.inside_geom) {
						location <- (dst_room.inside_geom closest_points_with location) [0];
					}
					if final_waypoint =nil {
						wandering <- false;
					}
				} else {
					wandering <- false;
				}
				if not(location overlaps dst_room.inside_geom) {
					location <- (dst_room.inside_geom closest_points_with location) [0];
				}
			} else {
				do wander amplitude: 140.0 bounds: dst_room.inside_geom speed: speed / 5.0;
				wandering_time_ag <- wandering_time_ag + step;	
			}
		} else if goto_a_desk {
			if (final_waypoint = nil) {
				do goto target: current_target;
			} else {
				do walk;
			
			}
			if not(location overlaps dst_room.inside_geom) {
				location <- (dst_room.inside_geom closest_points_with location) [0];
			}
			if final_waypoint =nil {
				goto_a_desk <- false;
			}
		} else {
			if flip(proba_wander) {
				wandering <- true;
				wandering_time_ag <- 0.0;
				heading <- rnd(360.0);
			} else if flip(proba_change_desk) { 
				
				goto_a_desk <- true;
				PlaceInRoom pir <- one_of (dst_room.places);
				target_desk <- {pir.location.x + rnd(-0.5,0.5),pir.location.y + rnd(-0.5,0.5)};
				if not(target_desk overlaps dst_room.inside_geom) {
					target_desk <- (dst_room.inside_geom closest_points_with target_desk) [0];
				}
				if ((location distance_to target_desk) > 2.0) {
					do compute_virtual_path pedestrian_graph:pedestrian_network target: target_desk ;
				}
			}
		}
	}

	reflex sanitation_behavior when: using_sanitation {
		sanitation_time <- sanitation_time + step;
		if (sanitation_time > sanitation_usage_duration) {
			sanitation_time <- 0.0;
			using_sanitation <- false;
			waiting_sanitation <- false;
			dst_room.people_inside >> self;
		}
	}

	// Setup targets when it's time to move
	reflex define_activity when: not waiting_sanitation and 
								not empty(current_agenda_week) and 
								(after(current_agenda_week.keys[0])) {
		if(target_place != nil and (has_place) ) {dst_room.available_places << target_place;}
		Room prev_tr <- copy(dst_room);
		do release_path;

		// Pop the next activity out of the agenda and get the new destination
		current_activity <- current_agenda_week.values[0];
		current_agenda_week >> first(current_agenda_week);
		pair dst_pair <- current_activity.get_destination(self);
		dst_room <- dst_pair.key;
		dst_point <- dst_pair.value;
		
		// Go to an elevator/stairway if the destination room is on another floor 
		if (dst_room.floor != current_floor) {
			Room vertical_transport_src <- 
				(Room where (each.type in [ELEVATOR, STAIRWAY] and each.floor = current_floor))
			 	closest_to self;
			Room vertical_transport_dst <- one_of(
				Room where (each.type = vertical_transport_src.type and each.floor = dst_room.floor)
			);
			add any_location_in(vertical_transport_src) to: targets at: length(targets);
		 	add any_location_in(vertical_transport_dst) to: targets at: length(targets);
		}
		
		if (dst_room != current_room) {
			// NOTE: remember to create one agent for each of the Activity* species to avoid an error here
			list<RoomEntrance> possible_entrances <- dst_room.entrances where (not((each path_to dst_room).shape overlaps prev_tr));
			
			// Go to room entrance
			if (empty (possible_entrances)) {
				possible_entrances <- dst_room.entrances;
			}
			point target_entrance <- (possible_entrances closest_to self).location;
			add target_entrance to: targets at: length(targets);
		}
		
		// Go to final destination point in room
		add dst_point to: targets at: length(targets);
		
		// Needed to trigger path computation in the goto_activity reflex
		current_target <- location;

		is_outside <- false;
		if (species(current_activity) = BuildingSanitation) {
			waiting_sanitation <- true;
		}
	}

	// Move across all the targets specified in define_activity
	reflex goto_activity when: current_target != nil and not in_line {
		// TODO: reimplement queueing before going into rooms if necessary;
		if location = current_target and !empty(targets) {
			current_target <- targets[0];
			remove item: current_target from: targets;
			do compute_virtual_path pedestrian_graph: pedestrian_network target: current_target;
			
			// Teleport to another floor
			if final_waypoint = nil {
				location <- current_target;
				current_floor <- dst_room.floor;
			}
		} else if final_waypoint != nil {
			do walk;
		} else {
			// Pedestrian skill cannot reach the exact target point, 
			// so as a last step, we use moving skill to bring the person there
			do goto target: current_target;
		}

		// Check if person has left the old room
		if current_room != nil and !overlaps(self, current_room) {
			remove item: self from: current_room.people_inside;
			current_room <- nil;
		}

		// Check if person has entered the destination room
		// NOTE: if targets is empty, the person must be moving to the final target, 
		// which is the target point in the destination room
		if empty(targets) and (current_room != dst_room) {
			current_room <- dst_room;
			add self to: current_room.people_inside;
		}

		if location = dst_point {
			current_target <- nil;
			if species(current_activity) = ActivityLeaveBuilding {
				is_outside <- true;
			}
		}
 	}

 	rgb get_color {
 		if state = latent {
 			return #pink;
 		} else if state in [symptomatic, asymptomatic, presymptomatic] {
 			return #red;
 		} else {
 			return #green;
 		}
 	}

 	aspect default {
		if not is_outside  {
			draw circle(P_shoulder_length) color: get_color() border: #black;
		}
	}
}
