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

import "../../../Core/Models/Entities/Abstract Individual.gaml"

import "BuildingActivity.gaml"
 
import "../Constants.gaml"
 
import "Building Spatial Entities.gaml" 
 
import "../Global.gaml"
 
species BuildingIndividual parent: AbstractIndividual schedules: shuffle(BuildingIndividual where (each.clinical_status != dead)) skills: [moving] {
 	int current_floor <- 0;
 	rgb color <- #violet;
	map<date, BuildingActivity> agenda_week;
	map<date, BuildingActivity> current_agenda_week;
	BuildingActivity current_activity;
	Building current_building;
	point target;
	Room current_room;
	unit_cell current_cell;
	bool has_to_renew_agenda <- true;
	float time_wait;
	Room dst_room;
	bool waiting_to_remove <- false;

	float speed <- max(2,min(6,gauss(4,1))) #km/#h;

	init {
		is_outside <- true;
		
	}
	
	action remove_agent {do die;}
	

	//#############################################################
	//Reflexes
	//#############################################################		
	reflex renew_agenda when:has_to_renew_agenda and empty(current_agenda_week) {
		loop t over: agenda_week.keys {
			// Apply the correct date
			current_agenda_week[t + time] <- agenda_week[t] ; 
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
		 
		if(allow_local_transmission) and current_cell != nil
		{
			ask current_cell
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
		ask Outside {do outside_epidemiological_dynamic(myself, step);}
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
		if(allow_local_transmission and (not is_infected) and current_cell != nil)
		{
			
			if(current_cell != nil and flip(current_cell.viral_load[original_strain]*successful_contact_rate_building))
			{
				infectious_contacts_with[current_place] <- define_new_case(original_strain);
			}
		}
		do update_wear_mask();
		if BENCHMARK {bench["Individual.update_epidemiology"] <- bench["Individual.update_epidemiology"] + machine_time - start;}
	}


	
	reflex define_activity when: not empty(current_agenda_week) and 
								(after(current_agenda_week.keys[0])) {
		// Pop the next activity out of the agenda and get the new destination
		current_activity <- current_agenda_week.values[0];
		current_agenda_week >> first(current_agenda_week);
		map dest_act <- current_activity.get_destination(self);
		time_wait <- 0.0;
		Room r <- dest_act[key_room];
		if (r != nil) {
			dst_room <- r;
			if is_outside {
				is_outside <- false;
				location <- any_location_in(one_of(AreaEntry));
			}
			target <- define_target(dst_room);
			target <- {target.x,target.y,floor_high * dst_room.floor};
		} 
	}

	
	
	action arrived_at_target {
		bool continue_to_move <- true;
		if (current_building = dst_room.my_building) {
			if (current_floor = dst_room.floor) {
				if (current_room = dst_room) or (dst_room.entrances = nil){
					continue_to_move <- false;
					if (species(dst_room) = AreaEntry) {
						is_outside <- true;
						if not(has_to_renew_agenda) and empty(agenda_week) {
							do remove_agent;
						}
					}
					
				} else {
					current_room <- dst_room;
				}
			} else {
				current_building.people[current_floor] >> self;
					
				current_floor <- dst_room.floor;
				current_building.people[current_floor] << self;
				
				location <- {location.x,location.y,floor_high * current_floor};
			}
		} else {
			if(current_building = nil) {
				current_building <- dst_room.my_building;
				current_building.people[0] << self;
			} else {
				if (current_floor = 0) {
					current_building.people[0] >> self;
					current_building <- nil;
				} else {
					current_building.people[current_floor] >> self;
					current_floor <- 0;
					current_building.people[current_floor] << self;
					location <- {location.x,location.y,floor_high * current_floor};
				}
			}
		}
		if continue_to_move {
			target <- define_target(dst_room);
			target <- {target.x,target.y,floor_high * dst_room.floor};
		} else {
			target <- nil;
			waiting_to_remove <- current_activity.wandering_in_room >= 0;
		}
	}
	
	point define_target(Room r) {
		if (current_building = r.my_building) {
			if (current_floor = r.floor) {
				if (current_room = r) or (r.entrances = nil) or empty(r.entrances){
					return any_location_in(r);
				} else {
					return (r.entrances closest_to self).location;
				}
			} else {
				Elevator el <- current_building.elevators[current_floor] closest_to self;
				return any_location_in(el);
			}
		} else {
			if(current_building = nil) {
				BuildingEntry en <- (r.my_building.entrances closest_to self);
				if en = nil {
					en <- r.my_building.entrances with_min_of (each distance_to self);
				}
				return en.location;
				
			} else {
				if (current_floor = 0) {
					return (current_building.entrances closest_to self).location;
				} else {
					Elevator el <- current_building.elevators[current_floor] closest_to self;
					return any_location_in(el);
				}
			}
		}
	}
	
	reflex wait_to_move when: target = nil and waiting_to_remove and current_activity != nil{
		time_wait <- time_wait + step;
		if (time_wait >  current_activity.wandering_in_room) {
			target <- define_target(current_room);
			waiting_to_remove <- false;
			time_wait <- 0.0;
		}
	}
	
	reflex goto_activity when: target != nil {
		PedestrianPath prev_edge <- current_edge = nil ? nil :PedestrianPath(current_edge);
		list<int> k <- [current_building = nil ? -1 : int(current_building), current_floor];
		graph concerned_graph <- pedestrian_network[k];
		//write sample(length(connected_components_of(concerned_graph)));
		//write name + " goto_activity : " + location + "  " + target + " path: " + path_between(concerned_graph, location, target);
		if  path_between(concerned_graph, location, target) = nil {
			
			write sample((concerned_graph.edges mean_of first(agent(each).shape.points).z));
			write name + " goto_activity : " + location + "  " + target + " path: " + path_between(concerned_graph, location, target);
			write  path_between(concerned_graph, one_of(concerned_graph.vertices), one_of(concerned_graph.vertices));
		//	save (concerned_graph.edges) type: shp to:"network.shp";
			write sample(location);
			write sample(target);
			ask world {
				do pause;
			}
		}
		//write sample(concerned_graph.vertices);
		do goto target: target on: concerned_graph move_weights: move_weights[k];
		//write name + " after: " + location ;
		if (current_building = nil) {
			current_cell <- nil;
		} 
		else {
			current_cell <- (unit_cells[[int(current_building), current_floor]] first_with (each overlaps self));
		}
		if (location distance_to target < tolerance_dist) {
			do arrived_at_target;
			current_edge <- nil;
			
		}
		
		if prev_edge != current_edge {
			if prev_edge != nil {
				prev_edge.nb_people <- prev_edge.nb_people - 1;
				prev_edge.update_coeff <- true;
			} 
			if current_edge != nil {
				PedestrianPath new_edge <- PedestrianPath(current_edge);
				new_edge.nb_people <- new_edge.nb_people + 1;
				new_edge.update_coeff <- true;
			}
		
		}
		location <- {location.x,location.y,floor_high * current_floor};
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
		if (current_building != nil) and (int(current_building) = building_map) and (current_floor = floor_map) {
			draw pple_walk size: {0.5,people_size}  at: location + {0, 0, people_size/2.0} rotate: heading - 90 color: color;
			if(is_infected){draw circle(0.7)  at: location + {0, 0, 0.7} color: get_color();}

		}
	}
}


species DefaultWorker parent: BuildingIndividual {
	Room working_place;
	rgb color <- #white;
	bool nightshift <- flip(0.2);
	init {
		age <- int(skew_gauss(22.0, 65.0, 0.6, 0.3));
		
		working_place <- one_of(Room where (each.type = OFFICE));
		
		list<int> working_days <- 5 among [0,1,2,3,4,5,6];
		loop i from: 0 to: 6 {
			if (copy(current_date) add_days i).day_of_week in working_days {
				if(!nightshift){
					date arrive <- date("06:30", TFS) add_days i + rnd(15#mn);
					agenda_week[arrive] <- first(ActivityGoToOffice);
					
					date lunch <- date("11:30", TFS) add_days i + rnd(60#mn);
					agenda_week[lunch] <- first(ActivityGotoRestaurant);
						
					date end <- date("17:00", TFS) add_days i + rnd(60#mn);
					agenda_week[end] <- first(ActivityLeaveArea);
				}
				
				else{
					date arrive <- date("17:30", TFS) add_days i + rnd(15#mn);
					agenda_week[arrive] <- first(ActivityGoToOffice);
						
					date end <- date("06:00", TFS) add_days i + rnd(60#mn);
					agenda_week[end] <- first(ActivityLeaveArea);
				}
			}
		}
	}

}
