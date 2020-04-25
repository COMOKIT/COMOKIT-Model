/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19 </br>
* Author: Benoit Gaudou, Kevin Chapuis </br>
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Entities/Building.gaml"
import "Parameters.gaml"

/*
 * All functions to initialize demographic attribute of the agent. It feature two type of initialization:
 * - use a file with #create_population_from_file to create a synthetic population from given attributes
 * - use the default algorithm provided in the toolkit: see #create_population for more info
 */
global {
	
	/*
	 * Uses the provided population.csv (in Datasets folder) to initialize the population of agent with. The required
	 * arguments are: </br>
	 * - age COMOKIT variable : age_var in Parameters.gaml </br>
	 * - sex COMOKIT variable : gender_var in Parameters.gaml </br>
	 * - household_id COMOKIT variable : householdIF in Parameters.gaml </p>
	 * 
	 * It might also require to define a way to convert values; e.g. gender can be coded using integers, so you will have to
	 * translate encoding into the proper variable, i.e. 0 for male and 1 for female in for COMOKIT. You can do so using,
	 * age_map and gender_map in Parameters.gaml </p>
	 * 
	 * The algorithm also bound agent with working places, schools and homes using related methods in Global.gaml #assign_school_working_place </p>
	 */
	action create_population_from_file(map<Building,float> working_places,map<list<int>,list<Building>> schools, list<Building> homes
	) {
		
		map<string,list<Individual>> households <- [];
		
		create Individual from:csv_population number: (number_of_individual <= 0 ? length(csv_population) : number_of_individual)
		with:[
			age::convert_age(get(age_var)),
			sex::convert_gender(get(gender_var)),
			household_id::string(get(householdID)) replace("\"","")
		]{
			if households contains_key household_id { households[household_id] <+ self; }
			else { households[household_id] <- [self]; }
		}
		
		list<Building> avlb_homes <- copy(homes);
		
		loop hhid over:households.keys { 
			Building homeplace <- any(avlb_homes); // Uniform distribution | should we take HH size vs size of the building ?
			ask households[hhid] { 
				relatives <- households[hhid] - self;
				home <- homeplace;
			}
			avlb_homes >- homeplace;
			if empty(avlb_homes) { avlb_homes <- copy(homes); } // Again, uniform even if some homeplace already have more people than others
		}
		
	}
	
	/*
	 * The default algorithm to create a population of agent from simple rules. </p>
	 * 
	 * The <b> arguments </b> includes: </br> 
	 * - min_student_age :: minimum age for lone individual </br>
	 * - max_student_age :: age that makes the separation between adults and children </p>
	 * 
	 * The <b> parameter </b> to adjust the process: </br>
	 * - nb_households :: the number of household per building (can be set using feature 'flat' from the shapefile of buildings) </br>
	 * - proba_active_family :: the probability to build a father+mother classical household rather than a lonely individual </br>
	 * - retirement_age :: the age that makes the separation between active and retired adults (will have a great impact on the agenda) </br>
	 * - number_children_max, number_children_mean, number_children_std :: assign a given number of children between 0 and max using gaussian mean and std </br>
	 * - proba_grandfather, proba_grandmother :: assign grand mother/father to the household
	 * </p>
	 */
	action create_population(map<Building,float> working_places,map<list<int>,list<Building>> schools, list<Building> homes, 
		int min_student_age, int max_student_age
	) {
		
		if (csv_parameter_population != nil) {
			loop i from: 0 to: csv_parameter_population.contents.rows - 1 {
				string parameter_name <- csv_parameter_population.contents[0,i];
				float value <- float(csv_parameter_population.contents[1,i]);
				world.shape.attributes[parameter_name] <- value;
				
			}
		}
		list<list<Individual>> households;
		
		ask homes {
			loop times: nb_households {
				list<Individual> household;
				if flip(proba_active_family) {
				//father
					create Individual {
						age <- rnd(max_student_age + 1,retirement_age);
						sex <- 0;
						home <- myself;
						household << self;
					} 
					//mother
					create Individual {
						age <- rnd(max_student_age + 1,retirement_age);
						sex <- 1;
						home <- myself;
						household << self;
					
					}
					//children
					int number <- min(number_children_max, round(gauss(number_children_mean,number_children_std)));
					if (number > 0) {
						create Individual number: number {
							//last_activity <-first(staying_home);
							age <- rnd(0,max_student_age);
							sex <- rnd(1);
							home <- myself;
							household << self;
						}
					}
					if (flip(proba_grandfather)) {
						create Individual {
							age <- rnd(retirement_age + 1, max_age);
							sex <- 0;
							home <- myself;
							household << self;
						}
					}	
					if (flip(proba_grandmother)) {
						create Individual {
							age <- rnd(retirement_age + 1, max_age);
							sex <- 1;
							home <- myself;
							household << self;
						}
					}
				} else {
					create Individual {
						age <- rnd(min_student_age + 1,max_age);
						sex <- rnd(1);
						home <- myself;
						household << self;
					} 
				}
				
				ask household {
					relatives <- household - self;
				}  
				households << household;
			}
		}	
	}
	
	// Convert SP encoded age into gama model specification (float)
	float convert_age(string input){ 
		input <- input replace("\"","");
		return (age_map=nil or empty(age_map)) ? int(input) : age_map[input];
	}
	
	// Convert SP encoded gender into gama model specification (0=men, 1=women)
	int convert_gender(string input){ 
		input <- input replace("\"","");
		return (gender_map=nil or empty(gender_map)) ? int(input) : gender_map[input]; 
	}
	
	
	/*
	 * The default algorithm to create a the social network (friends and colleagues) of agent from simple rules :</p>
	 *  - choose friends from the same age category  </br> 
	 *  - choose colleagues from agents working at the same place  </br> 
	 * 
	 * The <b> arguments </b> includes: </br> 
	 * - min_student_age :: minimum age for lone individual </br>
	 * - max_student_age :: age that makes the separation between adults and children </p>
	 * 
	 * The <b> parameter </b> to adjust the process: </br>
	 * - min_age_for_evening_act :: the minimum age to have a autonomous activity during evening </br>
	 * - retirement_age :: age of retirement </br>
	 * - nb_friends_mean :: mean number of friends per individual </br>
	 * - nb_friends_std :: standard deviation of the number of friends per individual  </br>
	 * - nb_work_colleagues_mean :: mean number of work colleagues per individual (with who the individual will have strong interactions) </br>
	 * - nb_work_colleagues_std :: standard deviation of the number of work colleagues per individual  </br>
	 * - nb_classmates_mean :: mean number of classmates per individual (with who the individual will have strong interactions)  </br>
	 * - nb_classmates_std :: standard deviation of the number of classmates per individual  </br>
	 * 
	 */
	action create_social_networks(int min_student_age, int max_student_age) {
		map<Building, list<Individual>> WP<- (Individual where (each.working_place != nil)) group_by each.working_place;
		map<Building, list<Individual>> Sc<- (Individual where (each.school != nil)) group_by each.school;
		map<int,list<Individual>> ind_per_age_cat;
		ind_per_age_cat[min_age_for_evening_act] <- [];
		ind_per_age_cat[min_student_age] <- [];
		ind_per_age_cat[max_student_age] <- [];
		ind_per_age_cat[retirement_age] <- [];
		ind_per_age_cat[max_age] <- [];
		
		loop p over: Individual {
			loop cat over: ind_per_age_cat.keys {
				if p.age < cat {
					ind_per_age_cat[cat]<<p;
					break;
				}  
			}
		}
		
		ask Individual {
			do initialise_social_network(WP, Sc,ind_per_age_cat);
		}
	}
	
	// Inputs
	//   working_places : map associating to each Building a weight (= surface * coefficient for this type of building to be a working_place)
	//   schools :  map associating with each school Building its area (as a weight of the number of students that can be in the school)
	//   min_student_age : minimum age to be in a school
	//   max_student_age : maximum age to go to a school
	action assign_school_working_place(map<Building,float> working_places,map<list<int>,list<Building>> schools, int min_student_age, int max_student_age) {
		
		// Assign to each individual a school and working_place depending of its age.
		// in addition, school and working_place can be outside.
		// Individuals too young or too old, do not have any working_place or school 
		ask Individual {
			last_activity <-first(staying_home);
			do enter_building(home);
			if (age >= min_student_age) {
				if (age < max_student_age) {
					loop l over: schools.keys {
						if (age >= min(l) and age <= max(l)) {
							if (flip(proba_go_outside) or empty(schools[l])) {
								school <- the_outside;	
							} else {
								switch choice_of_target_mode {
									match random {
										school <- one_of(schools[l]);
									}
									match closest {
										school <- schools[l] closest_to self;
									}
									match gravity {
										list<float> proba_per_building;
										loop b over: schools[l] {
											float dist <- max(20,b.location distance_to home.location);
											proba_per_building << (b.shape.area / dist ^ gravity_power);
										}
										school <- schools[l][rnd_choice(proba_per_building)];	
									}
								}
								
							}
						}
					}
				} else if (age < retirement_age) { 
					if flip(work_at_home_unemployed) {
						working_place <- home;
					}
					else if (flip(proba_go_outside) or empty(working_places)) {
						working_place <- the_outside;	
					} else {
						switch choice_of_target_mode {
							match random {
								working_place <- working_places.keys[rnd_choice(working_places.values)];
								
							}
							match closest {
								working_place <- working_places.keys closest_to self;
							}
							match gravity {
								list<float> proba_per_building;
								loop b over: working_places.keys {
									float dist <-  max(20,b.location distance_to home.location);
									proba_per_building << (working_places[b]  / (dist ^ gravity_power));
								}
								working_place <- working_places.keys[rnd_choice(proba_per_building)];	
							}
						}
					}
					
				}
			}
		}		
	}
	
	
	// Inputs
	//   min_student_age : minimum age to be in a school
	//   max_student_age : maximum age to go to a school
	// 
	// Principles: each individual has a week agenda composed by 7 daily agendas (maps of hour::Activity).
	//             The agenda depends on the age (students/workers, retired and young children).
	//             Students and workers have an agenda with 6 working days and one leisure days.
	//             Retired have an agenda full of leisure days.
	action define_agenda(int min_student_age, int max_student_age) {
		if (csv_parameter_agenda != nil) {
			loop i from: 0 to: csv_parameter_agenda.contents.rows - 1 {
				string parameter_name <- csv_parameter_agenda.contents[0,i];
				if (parameter_name in world.shape.attributes.keys) {
					if (parameter_name = "non_working_days" ) {
						non_working_days <- [];
						loop j from: 1 to: csv_parameter_agenda.contents.columns - 1 {
							int value <- int(csv_parameter_agenda.contents[j,i]);
							if (value >= 1 and value <= 7 and not(value in non_working_days)) {
								non_working_days << value;
							}
						}
					}
					else {
						float value <- float(csv_parameter_agenda.contents[1,i]);
						world.shape.attributes[parameter_name] <- value;
					}
				} 
			}
		}	
		list<Activity> possible_activities_tot <- Activities.values - studying - working - staying_home;
		list<Activity> possible_activities_without_rel <- possible_activities_tot - visiting_friend;
		Activity eating_act <- Activity first_with (each.name = act_eating);
		ask Individual {
			loop times: 7 {agenda_week<<[];}
		}
		// Initialization for students or workers
		ask Individual where ((each.age < retirement_age) and (each.age >= min_student_age))  {
			// Students and workers have an agenda similar for 6 days of the week ...
			loop i over: ([1,2,3,4,5,6,7] - non_working_days) {
				map<int,pair<Activity,list<Individual>>> agenda_day <- agenda_week[i - 1];
				list<Activity> possible_activities <- empty(friends) ? possible_activities_without_rel : possible_activities_tot;
				int current_hour;
				if (age < max_student_age) {
					current_hour <- rnd(school_hours_begin_min,school_hours_begin_max);
					agenda_day[current_hour] <- studying[0]::[];
				} else {
					current_hour <-rnd(work_hours_begin_min,work_hours_begin_max);
					agenda_day[current_hour] <- working[0]::[];
				}
				bool already <- false;
				loop h from: lunch_hours_min to: lunch_hours_max {
					if (h in agenda_day.keys) {
						already <- true;
						break;
					}
				}
				if not already {
					if (flip(proba_lunch_outside_workplace)) {
						current_hour <- rnd(lunch_hours_min,lunch_hours_max);
						int dur <- rnd(1,2);
						if (not flip(proba_lunch_at_home) and (eating_act != nil) and not empty(eating_act.buildings)) {
							list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among colleagues;
							loop ind over: inds {
								map<int,pair<Activity,list<Individual>>> agenda_day_ind <- ind.agenda_week[i - 1];
								agenda_day_ind[current_hour] <- eating_act::(inds - ind + self);
								if (ind.age < max_student_age) {
									agenda_day_ind[current_hour + dur] <- studying[0]::[];
								} else {
									agenda_day_ind[current_hour + dur] <- working[0]::[];
								}
							}
							agenda_day[current_hour] <- eating_act::inds ;
						} else {
							agenda_day[current_hour] <- staying_home[0]::[];
						}
						current_hour <- current_hour + dur;
						if (age < max_student_age) {
							agenda_day[current_hour] <- studying[0]::[];
						} else {
							agenda_day[current_hour] <- working[0]::[];
						}
					}
				}
				if (age < max_student_age) {
					current_hour <- rnd(school_hours_end_min,school_hours_end_max);
				} else {
					current_hour <-rnd(work_hours_end_min,work_hours_end_max);
				}
				agenda_day[current_hour] <- staying_home[0]::[];
				
				already <- false;
				loop h2 from: current_hour to: 23 {
					if (h2 in agenda_day.keys) {
						already <- true;
						break;
					}
				}
				if not already and (age >= min_age_for_evening_act) and flip(proba_activity_evening) {
					current_hour <- current_hour + rnd(1,max_duration_lunch);
					Activity act <- any(possible_activities);
					int current_hour <- min(23,current_hour + rnd(1,max_duration_default));
					int end_hour <- min(23,current_hour + rnd(1,max_duration_default));
					if (species(act) = Activity) {
						list<Individual> cands <- friends where ((each.agenda_week[i - 1][current_hour]) = nil);
						list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among cands;
						loop ind over: inds {
							map<int,pair<Activity,list<Individual>>> agenda_day_ind <- ind.agenda_week[i - 1];
							agenda_day_ind[current_hour] <- act::(inds - ind + self);
							bool return_home <- true;
							loop h from: current_hour + 1 to: end_hour {
								return_home <- agenda_day_ind[h] = nil;
								if (not return_home) {break;}
							}
							if (return_home) {agenda_day_ind[end_hour] <- staying_home[0]::[];}
							
						}
						agenda_day[current_hour] <- act::inds;
					} else {
						agenda_day[current_hour] <- act::[];
					}
					agenda_day[end_hour] <- staying_home[0]::[];
				}
				agenda_week[i-1] <- agenda_day;
			}
			
			// ... but it is diferent for non working days : they will pick activities among the ones that are not working, studying or staying home.
			loop i over: non_working_days {
				ask myself {do manag_day_off(myself,i,possible_activities_without_rel,possible_activities_tot);}
			}
			
		}
		
		// Initialization for retired individuals
		loop ind over: Individual where (each.age >= retirement_age) {
			loop i from:1 to: 7 {
				do manag_day_off(ind,i,possible_activities_without_rel,possible_activities_tot);
			}
		}
		
	
		
		if (choice_of_target_mode = gravity) {
			ask Individual {
				list<Activity> acts <- remove_duplicates((agenda_week accumulate each.values) collect each.key) inter list(Activity) ;
				loop act over: acts {
					if length(act.buildings) <= nb_candidates {
						building_targets[act] <- act.buildings;
					} else {
						list<Building> bds;
						list<float> proba_per_building;
						loop b over: act.buildings {
							float dist <- max(20,b.location distance_to home.location);
							proba_per_building << (b.shape.area / dist ^ gravity_power);
						}
						loop while: length(bds) < nb_candidates {
							bds << act.buildings[rnd_choice(proba_per_building)];
							bds <- remove_duplicates(bds);
						}
						building_targets[act] <- bds;
					}
				}
			}
		}
		
		
	}
	
	//specific construction of a "day off" (without work or school)
	action manag_day_off(Individual current_ind, int day, list<Activity> possible_activities_without_rel, list<Activity> possible_activities_tot) {
		map<int,pair<Activity,list<Individual>>> agenda_day <- current_ind.agenda_week[day - 1];
		list<Activity> possible_activities <- empty(current_ind.friends) ? possible_activities_without_rel : possible_activities_tot;
		int num_activity <- rnd(0,max_num_activity_for_non_working_day) - length(agenda_day);
		if (num_activity > 0) {
			list<int> forbiden_hours;
			bool act_beg <- false;
			int beg_act <- 0;
			loop h over: agenda_day.keys sort_by each {
				if not (act_beg) {
					act_beg <- true;
					beg_act <- h;
				} else {
					act_beg <- false;
					loop i from: beg_act to:h {
						forbiden_hours <<i;
					}
				}
			}
			int current_hour <- rnd(first_act_hour_non_working_min,first_act_hour_non_working_max);
			loop times: num_activity {
				if (current_hour in forbiden_hours) {
					current_hour <- current_hour + 1;
					if (current_hour > 22) {
						break;
					} 
				}
				
				int end_hour <- min(23,current_hour + rnd(1,max_duration_default));
				if (end_hour in forbiden_hours) {
					end_hour <- forbiden_hours first_with (each > current_hour) - 1;
				}
				if (current_hour >= end_hour) {
					break;
				}
				Activity act <- any(possible_activities);
				if (species(act) = Activity) {
					
					list<Individual> cands <- current_ind.friends where ((each.agenda_week[day - 1][current_hour]) = nil);
					list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among cands;
					//write  current_ind.name + " : " + current_ind.age + " nb friends: " + length(current_ind.friends) + " inds: "+ length(inds) + " friend age: "+ (current_ind.friends collect each.age);
					loop ind over: inds {
						map<int,pair<Activity,list<Individual>>> agenda_day_ind <- ind.agenda_week[day - 1];
						agenda_day_ind[current_hour] <- act::(inds - ind + current_ind);
						bool return_home <- true;
						loop h from: current_hour + 1 to: end_hour {
							return_home <- agenda_day_ind[h] = nil;
							if not (return_home) {break;}
						}
						if (return_home) {agenda_day_ind[end_hour] <- staying_home[0]::[];}
						//write "ind.agenda_week: " + day + " -> "+ ind.agenda_week[day - 1];
					}
					agenda_day[current_hour] <- act::inds;
				} else {
					agenda_day[current_hour] <- act::[];
				}
				agenda_day[end_hour] <- staying_home[0]::[];
				current_hour <- end_hour + 1;
			}
		}
		current_ind.agenda_week[day-1] <- agenda_day;
	}
	
	
}

