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
 	int current_floor <- 0;
 	Room working_place;
	PlaceInRoom working_desk;
	BenchWait benchw;
	rgb color <- #violet;
	map<date, BuildingActivity> agenda_week;
	map<date, BuildingActivity> current_agenda_week;
	BuildingActivity current_activity;
	point target;
	point dst_point;
	Room dst_room;
	Room current_room;
	bool has_place <- false;
	PlaceInRoom target_place;
	bool goto_entrance <- false;
	bool go_oustide_room <- false;
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
	float wander_proba <- 1/10#minute;
	point target_desk;
	float wandering_time_ag;
	bool finished_goto <- false;
	bool to_another_floor <- false;
	
	init {
		is_outside <- true;
		do initialise_epidemio;
	
		pedestrian_species <- [BuildingIndividual];
		obstacle_species <- [ Wall];
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
			loop succesful_contact over: (BuildingIndividual at_distance infectionDistance) where 
											((each.state = susceptible) and (each.current_floor = self.current_floor)) {
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
			if(flip(current_room.viral_load*successful_contact_rate_building/ (current_room.shape.area * current_room.ceiling_height)))
			{
				infected_by <- current_place;
				do define_new_case();
			}
		}
		if(allow_local_transmission and (not is_infected))
		{
			unit_cell current_cell <- unit_cell(location);
			if(flip(current_cell.viral_load*successful_contact_rate_building))
			{
				infected_by <- current_place;
				do define_new_case();
			}
		}
		do update_wear_mask();
		if BENCHMARK {bench["Individual.update_epidemiology"] <- bench["Individual.update_epidemiology"] + machine_time - start;}
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

	reflex define_activity when: not waiting_sanitation and 
								not empty(current_agenda_week) and 
								(after(current_agenda_week.keys[0])) {
		if(target_place != nil and (has_place) ) {dst_room.available_places << target_place;}
		string n <- current_activity = nil ? "" : copy(current_activity.name);
		Room prev_tr <- copy(dst_room);
		do release_path;
		if(species(current_activity) = ActivityWait){
			benchw.is_occupied <- false;
			benchw <- nil;
		}
		
		// Pop the next activity out of the agenda and get the new destination
		current_activity <- current_agenda_week.values[0];
		current_agenda_week >> first(current_agenda_week);
		pair dst_pair <- current_activity.get_destination(self);
		dst_room <- dst_pair.key;
		dst_point <- dst_pair.value;

		// NOTE: remember to create one agent for each of the Activity* species to avoid an error here
		list<RoomEntrance> possible_entrances <- dst_room.entrances where (not((each path_to dst_room).shape overlaps prev_tr));
		if (empty (possible_entrances)) {
			possible_entrances <- dst_room.entrances;
		}
//		if(current_room != dst_room){
//			target <- first(possible_entrances).location;
//		}
		
		if(current_floor != dst_room.floor){
			to_another_floor <- true;
			target <- ((BuildingEntrance where (each.floor = current_floor)) closest_to self).location
													+ point([0, 0, current_floor*default_ceiling_height]);
		}
		else{	
			target <- dst_point.location + point([0, 0, dst_room.floor*default_ceiling_height - dst_point.location.z]);
		}
		
		
//		go_oustide_room <- true;
		is_outside <- false;
//		goto_entrance <- false;
//		target_place <- nil;
//		finished_goto <- false;
		if (species(current_activity) = BuildingSanitation) {
			waiting_sanitation <- true;
		}
	}

	reflex goto_activity when: target != nil and not in_line {
//		bool arrived <- false;
//		point prev_loc <- copy(location);
//		check floor, if current_floor = target floor, go straight to target, if not, go through the entrance
		if(to_another_floor){
			if (location distance_to target > P_tolerance_target){
				if(current_room = dst_room and final_waypoint = nil){
					do goto target: target;
				}
				else{
					if (current_room != dst_room and final_waypoint = nil){
						do compute_virtual_path pedestrian_graph: pedestrian_network target: target;
					}
					if(final_waypoint != nil){
						do walk;
					}
				}
			}
			else{
				to_another_floor<- false;
				target <- dst_point.location + point([0, 0, dst_room.floor*default_ceiling_height]);
				location <- location + point([0, 0, dst_room.floor*default_ceiling_height - location.z]);
				is_outside <- false;
				current_floor <- dst_room.floor;
				if(species(dst_room) = BuildingEntrance){
					is_outside <- true;
				}
				do release_path;
			}
		}
		else{
			if (location distance_to target > P_tolerance_target){
				if(current_room = dst_room and final_waypoint = nil){
					do goto target: target;
				}
				else{
					if (current_room != dst_room and final_waypoint = nil){
						do compute_virtual_path pedestrian_graph: pedestrian_network target: target;
					}
					if(final_waypoint != nil){
						do walk;
					}
				}
			}
			else{
				target <- nil;
				if(species(dst_room) = BuildingEntrance){
					is_outside <- true;
				}
				do release_path;
			}
		}
		
		if(dst_room != nil and not(location overlaps current_room) and current_room != dst_room){
			if(current_room!= nil){
				current_room.people_inside >> self;
			}
			current_room <- empty(Room where (each overlaps location and each.floor = current_floor))
							?nil:first(Room where (each overlaps location and each.floor = current_floor));
		}
		if(location overlaps dst_room and current_floor = dst_room.floor){
			current_room <- dst_room;
			if(!(dst_room.people_inside contains self)){
				dst_room.people_inside << self;
			}
			do release_path;
		}
		
		
		
// goto with queue behavior
//		if goto_entrance {
//			if (queueing) and (species(dst_room) != BuildingEntrance) and ((self distance_to target) < (2 * distance_queue))  and ((self distance_to target) > (1 * distance_queue))  {
//				point pt <- the_entrance.get_position();
//				if (pt != target) {
//					final_waypoint <- nil;
//					target <- pt;
//				}
//			}
//			if (final_waypoint = nil) and ((location distance_to target) > 2.0)  {
//				do compute_virtual_path pedestrian_graph:pedestrian_network target: target;
//			}
//			if (final_waypoint != nil) {
//				do walk;
//			}
//			arrived <- final_waypoint = nil;
//			if (arrived) {
//				is_slow_real <- false;
//				counter <- 0;
//			}
//		} else {
//			if (finished_goto) {
//				do goto target: target;
//			} else {
//				if (final_waypoint = nil) {
//					do compute_virtual_path pedestrian_graph:pedestrian_network target: target;
//				}
//				do walk;
//				finished_goto <- (final_waypoint = nil) and (location != target);
//			}
//			arrived <- location = target;
//			if (arrived) {
//				finished_goto <- false;
//			}
//		}
//		if(arrived) {
//			if (go_oustide_room) {
//				current_room <- nil;
//				the_entrance <- (dst_room.entrances closest_to self);
//					
//				if (!queueing) {
//					target <- the_entrance.location;
//				} else {
//					if (species(dst_room) = BuildingEntrance) {
//						target <- the_entrance.location;
//					} else {
//						target <- the_entrance.get_position();
//					}
//				}
//				
//				go_oustide_room <- false;
//				goto_entrance <- true;
//			}
//			else if (goto_entrance) {
//				current_room <- dst_room;
//				if (species(current_activity) = BuildingSanitation) {
//					target <- dst_room.location;
//					goto_entrance <- false;
//					if (queueing) or (dst_room.type = sanitation) {
//						ask RoomEntrance closest_to self {
//							do add_people(myself);
//						}
//						in_line <- true;
//					} else {
//							
//					}
//				} else {
//					if dst_point != nil {
//						target <- dst_point.location;
//						if (queueing and (species(dst_room) != BuildingEntrance)) {
//							ask RoomEntrance closest_to self {
//								do add_people(myself);
//							}
//							in_line <- true;
//						}
//					} else {
//						Room tr <- current_activity.get_destination(self).key;
//						if(tr = dst_room) {
//							target <- any_location_in(tr);
//						} else if (tr != nil ) {
//							dst_room <- tr;
//							target <- (dst_room.entrances closest_to self).location;
//						}
//					}
//					goto_entrance <- false;
//				}
//			} else {
//				has_place <- true;
//				target <- nil;
//				if (species(current_activity) = BuildingSanitation) {
//					using_sanitation <- true;
//					dst_room.people_inside << self;
//				}
//				if (species(dst_room) = BuildingEntrance) {
//					is_outside <- true;
//					do release_path;
//				}
//			}
//		}
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
		if(!is_outside and show_floor[current_floor]){

			draw pple_walk size: people_size  at: location + {0, 0, 0.7} rotate: heading - 90 color: color;
			if(is_infected){draw circle(0.7)  at: location + {0, 0, 0.7} color: get_color();}
		}
	}
}
