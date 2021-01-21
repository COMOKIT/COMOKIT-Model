/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Declares the species and its sub-species representing the activities
* undertaken by Individuals. Associated actions are also declared in this file.
* 
* Author: Benoit Gaudou, Huynh Quang Nghi, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19

import "Building.gaml"

global {
	// A map of all possible activities
	map<string, Activity> Activities;
	
	action create_activities {
		
		// Create one Activity agent for each species inheriting from Activity
		loop s over: Activity.subspecies { 
			create s returns: new_activity;
			Activities[first(new_activity).name] <- Activity(first(new_activity)) ;
		}
		
		// Local variable sorting all the Building agents given their type
		map<string,list<Building>> buildings_per_activity <- Building group_by (each.type);
		
		// Create in addition one Activity species for each meta-type of Activity as defined in the activities map
		loop tb over: activities.keys { 
			create Activity with:[name::tb, types_of_building::activities[tb]] {
				Activities[tb] <-self ;
				loop type over: types_of_building {
					if (type in buildings_per_activity.keys) {
						buildings[type] <-  buildings_per_activity[type];
					} 
				}
				
			}
		}
		
		if (csv_building_type_weights != nil) {
			weight_bd_type_per_age_sex_class <- [];
			matrix data <- matrix(csv_building_type_weights);
			list<string> types;
			loop i from: 3 to: data.columns - 1 {
				types <<string(data[i,0]);
			}
			loop i from: 1 to: data.rows - 1 {
				list<int> cat <- [ int(data[0,i]),int(data[1,i])];
				map<int,map<string, float>> weights <- (cat in weight_bd_type_per_age_sex_class.keys) ? weight_bd_type_per_age_sex_class[cat] : map([]);
				int sex <- int(data[2,i]);
				map<string, float> weights_sex;
				loop j from: 0 to: length(types) - 1 {
					weights_sex[types[j]] <- float(data[j+3,i]); 
				}
				
				weights[sex] <- weights_sex;
				weight_bd_type_per_age_sex_class[cat] <- weights;
			}
		}
		list<string> existing_bd_type;
		loop type over: weight_bd_type_per_age_sex_class.values {
			loop type_s over: type.values {
				existing_bd_type <- existing_bd_type + type_s.keys;
			}
		}
		existing_bd_type <- remove_duplicates(existing_bd_type);
		ask Activity {
			types_of_building <- types_of_building where ((each in existing_bd_type) or (each in buildings.keys));
		}
				
	}
	
	string building_type_choice(Individual ind, list<string> possible_building_types) {
		if (weight_bd_type_per_age_sex_class = nil ) or empty(weight_bd_type_per_age_sex_class) {
			return any(possible_building_types);
		}
		loop a over: weight_bd_type_per_age_sex_class.keys {
			if (ind.age >= a[0]) and (ind.age <= a[1]) {
				map<string, float> weight_bds <-  weight_bd_type_per_age_sex_class[a][ind.sex];
				list<float> proba_bds <- possible_building_types collect ((each in weight_bds.keys) ? weight_bds[each]:1.0 );
				if (sum(proba_bds) = 0) {return any(possible_building_types);}
				return possible_building_types[rnd_choice(proba_bds)];
			}
		}
		return any(possible_building_types);
		
	}
	
	/*
	 * Makes it possible to add an activity to an agenda: </br>
	 * <ul>
	 *  <li> the_activity : the activity to add to the agenda
	 *  <li> individual : the individual agent that will have the new activity in her agenda
	 *  <li> days : keys represents days of the week, values represent the weights to choose among available days
	 *  <li> days_a_week : number of days in a week to carry out this new activity
	 *  <li> hours : keys represents hours of the day, values represent the weights to choose among available starting hours
	 *  <li> only_one_a_day : boolean value to decide if activity can be done several time a day
	 *  <li> lenght : the lenght (in hours - #h) of the activity 
	 * </ul>
	 */
	action add_activity_to_agenda(
		Activity the_activity, Individual individual, 
		map<int,float> days, int days_a_week, 
		map<int,float> hours, bool only_one_a_day <- true,
		pair<int,int> length <- 1::1
	) {
		// List of the day to add the activity to
		list<int> days_of_activity;
		loop times:days_a_week { 
			if not(empty(days)) {
				days_of_activity <+ rnd_choice(days); 
				days[] >- last(days_of_activity);
			} 
		} 
		
		// Over each day
		loop d over: days_of_activity collect (each-1) {
			
			// Elicits the hours to start this activity (possibly several times the day)
			list<int> starting_hours;
			if only_one_a_day { starting_hours <+ rnd_choice(hours); }
			else { starting_hours <- hours.keys where (flip(hours[each])); }
			
			ask individual {
				// Last return home activity
				int end_day <- max(agenda_week[d].keys);
				
				// Iterate over each starting hour of the new activity during the day
				loop h over:starting_hours {
					
					// Current activity during starting_hour
					pair<Activity,list<Individual>> current_act <- agenda_week[d] contains_key h ? agenda_week[d][h] :
						agenda_week[d][max(agenda_week[d].keys where (each < h))]; 
					
					// Replace it with the new activity
					agenda_week[d][h] <- the_activity::[];
					
					// Length of the activity
					int l <- rnd(length.key,length.value);
					int current_hour <- h+l;
					if h+l>23 {
						l <- l - (h + l - 23);
						current_hour <- 23;
					}
					
					// Skipped activities
					map<int,pair<Activity,list<Individual>>> removed_activities;
					loop nh from:1 to:l { 
						if agenda_week[d] contains_key (h+nh) {
							removed_activities[h+nh] <- agenda_week[d][h+nh];
							agenda_week[d][] >- h+nh; 
						}
					}
					
					// If there is no skipped activity, then return to previous activity
					if empty(removed_activities) {
						agenda_week[d][current_hour] <- current_act;
					} else if length(removed_activities) = 1 { 
						// If one activity have been skipped, just move to it and carry on with normal agenda
						agenda_week[d][current_hour] <- first(removed_activities.values);
					} else { // There is more than one activity skipped
						// That contains last return home activity
						if removed_activities contains_key end_day {
							agenda_week[d][current_hour] <- staying_home[0]::[];
						} else {
							// Fill available time with removed activities
							int available_time <- agenda_week[d].keys[(agenda_week[d].keys index_of h + 1)]-current_hour;
							if available_time > 0 {
								int total_time_removed <- last(removed_activities.keys) - first(removed_activities.keys);
								map<Activity,pair<int,list<Individual>>> r_act <- removed_activities.keys 
									as_map (removed_activities[each].key::(each::removed_activities[each].value));
								if total_time_removed <= available_time {
									loop a over:r_act.keys {
										agenda_week[d][current_hour] <- a::r_act[a].value;
										if last(r_act.keys) != a {
											current_hour <- current_hour + r_act[a].key - r_act[r_act.keys[r_act.keys index_of a + 1]].key;
										} 
									}
								} else {
									loop while:available_time > 0 {
										Activity a <- any(r_act.keys where (r_act[each].key <= available_time));
										if a = nil { a <- any(r_act.keys); }
										agenda_week[d][current_hour] <- a::r_act[a].value;
										available_time <- available_time + r_act[a].key - r_act[r_act.keys[r_act.keys index_of a + 1]].key;
										r_act[] >- a; 
									}
								}
							}
						}
					}
				}	
			}	
		}
	}
	
}

species Activity {
	list<string> types_of_building <- [];
	map<string,list<Building>> buildings;
	
	map<Building,list<Individual>> find_target (Individual i) {
		float start <- BENCHMARK ? machine_time : 0.0; 
		if not empty(i.activity_fellows ) {
			Individual fellow <- i.activity_fellows first_with (each.last_activity = self);
			if (fellow!= nil) {
				return [fellow.current_place::[]];
			} 
		}
		if flip(proba_go_outside) {
			return [the_outside::[]];
		}
		
		string type <- world.building_type_choice(i,types_of_building);
		list<Building> bds <- buildings[type];
		
		if (empty(bds)) { return [the_outside::[]]; }	
		if BENCHMARK { 
			bench["Activity.find_target"] <- (bench contains_key "Activity.find_target" ? 
				bench["Activity.find_target"] : 0.0) + machine_time - start;
		}
		switch choice_of_target_mode {
			match closest {
				return [bds closest_to i::[]];
			}
			match gravity {
				return i.building_targets[self][type] as_map (each::[]);
			}
			match random {
				return (nb_candidates among bds) as_map(each::[]);
			}
		}
	}

	aspect default {
		draw shape + 10 color: #black;
	}

} 

species visiting_neighbor parent: Activity {
	string name <- act_neighbor;
	map<Building,list<Individual>> find_target (Individual i) {
		float start <- BENCHMARK ? machine_time : 0.0;
		map<Building,list<Individual>> targets <- i.current_place.get_neighbors() where not empty(each.individuals)
			as_map (each::each.individuals);
		if BENCHMARK { 
			bench["Activity.visiting_neighbor.find_target"] <- (bench contains_key "Activity.visiting_neighbor.find_target" ? 
				bench["Activity.visiting_neighbor.find_target"] : 0.0) + machine_time - start;
		}
		return targets;
	}
}

species visiting_friend parent: Activity {
	string name <- act_friend;
	map<Building,list<Individual>> find_target (Individual i) {
		float start <- BENCHMARK ? machine_time : 0.0;
		map<Building,list<Individual>> targets;
		loop friend over: (i.friends where each.is_at_home) {
			targets[i.home] <- i.relatives + i;
		}
		if BENCHMARK { 
			bench["Activity.visiting_friend.find_target"] <- (bench contains_key "Activity.visiting_friend.find_target" ? 
				bench["Activity.visiting_friend.find_target"] : 0.0) + machine_time - start;
		}
		return targets;
	}
}

species working parent: Activity {
	string name <- act_working;
	map<Building,list<Individual>> find_target (Individual i) {
		return [i.working_place::i.colleagues];
	}

}

species studying parent: Activity {
	string name <- act_studying;
	map<Building,list<Individual>> find_target (Individual i) {
		return [i.school::i.colleagues];
	}

}

species staying_home parent: Activity {
	string name <- act_home;
	map<Building,list<Individual>> find_target (Individual i) {
		return [i.home::i.relatives];
	}
}
