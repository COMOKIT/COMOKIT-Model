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
	map<date, BuildingActivity> agenda_week;
	map<date, BuildingActivity> current_agenda_week;
	BuildingActivity current_activity; 
	point target;
	Room target_room;
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
	point target_desk;
	float wandering_time_ag;
	bool finished_goto <- false;
	
	aspect default {
		if not is_outside  {
			draw circle(P_shoulder_length) color: state = latent ? #pink : ((state = symptomatic)or(state=asymptomatic)or(state=presymptomatic)? #red : #green) border: #black;
		}
	}
	
	//#############################################################
	//Reflexes
	//#############################################################
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
	
	reflex new_agenda when: empty(current_agenda_week) {
		loop d over: agenda_week.keys {
			current_agenda_week[d add_days 7] <- agenda_week[d];
		}
	}
	
	
	
	reflex common_area_behavior when: not is_outside and species(target_room) = CommonArea and (location overlaps target_room) {
		if wandering {
			if (wandering_time_ag > wandering_time) {
				if (target_place != nil) {
					if final_target = nil and ((location distance_to target_place) > 2.0){
						do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target_place ;
					}
					if (final_target = nil) {
						do goto target: target_place;
					} else {
						do walk;
					}
					
					if not(location overlaps target_room.inside_geom) {
						location <- (target_room.inside_geom closest_points_with location) [0];
					}
					if final_target =nil {
						wandering <- false;
					}
				} else {
					wandering <- false;
				}
				if not(location overlaps target_room.inside_geom) {
					location <- (target_room.inside_geom closest_points_with location) [0];
				}
			} else {
				do wander amplitude: 140.0 bounds: target_room.inside_geom speed: speed / 5.0;
				wandering_time_ag <- wandering_time_ag + step;	
			}
		} else if goto_a_desk {
			if (final_target = nil) {
				do goto target: target;
			} else {
				do walk;
			
			}
			if not(location overlaps target_room.inside_geom) {
				location <- (target_room.inside_geom closest_points_with location) [0];
			}
			if final_target =nil {
				goto_a_desk <- false;
			}
		} else {
			if flip(proba_wander) {
				wandering <- true;
				wandering_time_ag <- 0.0;
				heading <- rnd(360.0);
			} else if flip(proba_change_desk) { 
				
				goto_a_desk <- true;
				PlaceInRoom pir <- one_of (target_room.places);
				target_desk <- {pir.location.x + rnd(-0.5,0.5),pir.location.y + rnd(-0.5,0.5)};
				if not(target_desk overlaps target_room.inside_geom) {
					target_desk <- (target_room.inside_geom closest_points_with target_desk) [0];
				}
				if ((location distance_to target_desk) > 2.0) {
					do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target_desk ;
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
			target_room.people_inside >> self;
		}
	}
	
	reflex define_activity when: not waiting_sanitation and not empty(current_agenda_week) and 
		(after(current_agenda_week.keys[0])){
		if(target_place != nil and (has_place) ) {target_room.available_places << target_place;}
		string n <- current_activity = nil ? "" : copy(current_activity.name);
		Room prev_tr <- copy(target_room);
		current_activity <- current_agenda_week.values[0];
		current_agenda_week >> first(current_agenda_week);
		target_room <- current_activity.get_place(self);
		list<RoomEntrance> possible_entrances <- target_room.entrances where (not((each path_to target_room).shape overlaps prev_tr));
		if (empty (possible_entrances)) {
			possible_entrances <-  target_room.entrances;
		}
		target <- (target_room.entrances closest_to self).location;
		go_oustide_room <- true;
		is_outside <- false;
		goto_entrance <- false;
		target_place <- nil;
		if (species(current_activity) = BuildingSanitation) {
			waiting_sanitation <- true;
		}
	}
	
	reflex goto_activity when: target != nil and not in_line{
		bool arrived <- false;
		point prev_loc <- copy(location);
		if goto_entrance {
			if (queueing) and (species(target_room) != BuildingEntrance) and ((self distance_to target) < (2 * distance_queue))  and ((self distance_to target) > (1 * distance_queue))  {
				point pt <- the_entrance.get_position();
				if (pt != target) {
					final_target <- nil;
					target <- pt;
				}
			}
			if (final_target = nil) and ((location distance_to target) > 2.0)  {
					do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target ;
				}
				if (final_target != nil) {
					do walk;
				}
				
				arrived <- final_target = nil;
				if (arrived) {
					is_slow_real <- false;
					counter <- 0;
				}
			
		} else {
			if (finished_goto) {
				do goto target: target;
			} else {
				if (final_target = nil) {
					do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target ;
				}
				do walk;
				finished_goto <- (final_target = nil) and (location != target);
			}
			arrived <- location = target;
			if (arrived) {
				finished_goto <- false;
			}
		}
		if(arrived) {
			if (go_oustide_room) {
				current_room <- nil;
				the_entrance <- (target_room.entrances closest_to self);
					
				if (!queueing) {
					target <- the_entrance.location;
				} else {
					if (species(target_room) = BuildingEntrance) {
						target <- the_entrance.location;
					} else {
						target <- the_entrance.get_position();
					}
				}
				
				go_oustide_room <- false;
				goto_entrance <- true;
			}
			else if (goto_entrance) {
				current_room <- target_room;
				if (species(current_activity) = BuildingSanitation) {
					target <- target_room.location;
					goto_entrance <- false;
					if (queueing) or (target_room.type = sanitation) {
						ask RoomEntrance closest_to self {
							do add_people(myself);
						}
						in_line <- true;
					} else {
							
					}
				} else {
					target_place <- (target_room = working_place) ? working_desk : target_room.get_target(self, species(target_room) = CommonArea);
					if target_place != nil {
						target <- target_place.location;
						
						if (queueing and (species(target_room) != BuildingEntrance)) {
							ask RoomEntrance closest_to self {
								do add_people(myself);
							}
							in_line <- true;
						}
					} else {
						Room tr <- current_activity.get_place(self);
						if(tr = target_room) {
							target <- any_location_in(tr);
						} else if (tr != nil ) {
							target_room <- tr;
							target <- (target_room.entrances closest_to self).location;
						}
					}
					goto_entrance <- false;
				}
			} else {
				has_place <- true;
				target <- nil;
				if (species(current_activity) = BuildingSanitation) {
					using_sanitation <- true;
					target_room.people_inside << self;
				}
				if (species(target_room) = BuildingEntrance) {
					is_outside <- true;
				}
				
			}	
		}
 	}
}
