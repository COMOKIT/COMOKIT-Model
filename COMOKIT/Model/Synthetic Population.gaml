/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Declares the functions used to initialize the population of agents, 
* either from a file or using heuristics
* 
* Author: Benoit Gaudou, Kevin Chapuis
* Tags: covid19,epidemiology
******************************************************************/

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
	
	// ------------------------------ //
	// SYNTHETIC POPULATION FROM FILE //
	// ------------------------------ //
	
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
	action create_population_from_file(list<Building> homes, int min_student_age, int max_student_age
	) {
		
		map<string,list<Individual>> households <- [];
		
		if not(csv_population_attribute_mappers=nil) { do read_mapping(); }
		
		create individual_species from:csv_population number: (number_of_individual <= 0 ? length(csv_population) :
			(number_of_individual < length(csv_population) ? number_of_individual : length(csv_population)) 
		)
		with:[
			age::convert_age(get(age_var)),
			sex::convert_gender(get(gender_var)),
			is_unemployed::convert_unemployed(get(unemployed_var)),
			household_id::convert_hhid(get(householdID)),
			individual_id::get(individualID) 
		]{ 
			if households contains_key household_id { households[household_id] <+ self; }
			else { households[household_id] <- [self]; }
			if individual_id=nil or empty(individual_id) {individual_id <- name;}
		}
		
		list<Individual> hh_empty <- all_individuals where (each.household_id = nil);
		
		// Do something to build household to mimic built-in generator
		int hh_n <- sum(homes collect (each.nb_households));
		int hh_id <- 0;
		string hhID <- "HH";
		loop times:hh_n {
			list<Individual> hh <- [];
			string id <- hhID+string(hh_id);
			
			// Head of household 
			if (flip(proba_active_family)) {
				Individual father <- hh_empty first_with (each.sex = 0 and each.age > max_student_age and each.age < retirement_age);
				if not(father = nil) {hh <+ father; father.household_id <- id; hh_empty >- father;}
				Individual mother <- hh_empty first_with (each.sex = 1 and each.age > max_student_age and each.age < retirement_age);
				if not(mother = nil) {hh <+ mother; mother.household_id <- id; hh_empty >- mother;}
			} else {
				Individual lone <- hh_empty first_with (each.age > max_student_age);
				if not(lone = nil) {hh <+ lone; lone.household_id <- id; hh_empty >- lone;}
			}
			
			// Children of the household
			int number <- min(number_children_max, round(gauss(number_children_mean,number_children_std)));
			if number > 0 {
				Individual c <- hh_empty first_with (each.age <= max_student_age);
				loop while: not(c=nil) and number > 0 { 
					hh <+ c; c.household_id <- id; number <- number - 1; hh_empty >- c;
					c <- hh_empty first_with (each.age <= max_student_age);
				}
			}
			
			// Grandfather / Grandmother
			if flip(proba_grandfather) { 
				Individual grandfather <- hh_empty first_with (each.sex = 0 and each.age > retirement_age);
				if not(grandfather = nil) {hh <+ grandfather; grandfather.household_id <- id; hh_empty >- grandfather;}
			}
			if flip(proba_grandmother) {
				Individual grandmother <- hh_empty first_with (each.sex = 1 and each.age > retirement_age);
				if not(grandmother = nil) {hh <+ grandmother; grandmother.household_id <- id; hh_empty >- grandmother;}
			}
			
			if empty(hh) {break;}
			
			// Set relatives
			ask hh { relatives <- hh - self; } 
			
			// Add household to collection for further process (localisation)
			households[id] <- hh;
			
			// Increment hh identifier
			hh_id <- hh_id + 1; 
			
		}
		
		do assign_homeplace(households.values, homes);
		
	}
		
	//#############################################################
	// Attribute convertion rules for csv based synthetic population
	//#############################################################
	
	// Convert SP encoded age into gama model specification (float)
	float convert_age(string input){ 
		if not(input=nil) {
			input <- input contains qualifier ? input replace(qualifier,"") : input;
			if not(age_map=nil) and not(empty(age_map)) {
				if age_map contains_key input { return rnd(first(age_map[input]),last(age_map[input])); }
			} else {
				if int(input) is int { return int(input); }
			}
		} 
		return _get_age();
	}
	
	// Convert SP encoded gender into gama model specification (0=men, 1=women)
	int convert_gender(string input){ 
		if not(input=nil) {
			input <- input contains qualifier ? input replace(qualifier,"") : input;
			if not(gender_map=nil) and not(empty(gender_map)) {
				if (gender_map contains_key EMPTY and empty(input)) { return gender_map[EMPTY]; }
				else if (gender_map contains_key input) { return gender_map[input]; }
				else if (gender_map contains_key OTHER) { return gender_map[OTHER]; }
			} else if int(input) = 0 or int(input) = 1 {return int(input);}
		}
		return _get_sex();
	}
	
	// Convert SP encoded employment status into gama model specification (true=unemployed,false=employed)
	bool convert_unemployed(string input){
		if not(input=nil) {
			input <- input contains qualifier ? input replace(qualifier,"") : input;
			if not(unemployed_map=nil) and not(empty(unemployed_map)) {
				if(unemployed_map contains_key EMPTY and empty(input)) { return unemployed_map[EMPTY]; }
				else if(unemployed_map contains_key input) { return unemployed_map[input]; }
				else if(unemployed_map contains_key OTHER) { return unemployed_map[OTHER]; }
			}
		}
		return _get_employment_status(rnd(1));	// because we don't know yet the sex then do unifrom
	}
	
	// Convert household ID from file to string 
	string convert_hhid(string input){
		return not(input=nil) and input contains "\"" ? input replace("\"","") : input;
	}
	
	/*
	 * Read the synthetic entity variable mapping from parameter file
	 */
	action read_mapping {
		matrix data <- matrix(csv_population_attribute_mappers);
		list<list> data_rows <- rows_list(data);
		//Loading the different rows number for the parameters in the file
		loop row over:data_rows{
			string var <- first(row);
			switch var {
				match AGE { age_var <- row[1]; age_map <- map<string, list<float>>(read_var_map(row)); }
				match SEX { gender_var <- row[1]; gender_map <- map<string, int>(read_var_map(row)); }
				match EMP { unemployed_var <- row[1]; unemployed_map <- map<string, bool>(read_var_map(row)); }
				match HID { householdID <- row[1]; }
				match IID { individualID <- row[1]; }
				default {error "Failed to map variable "+var+" from Population Records.csv
						\n Should be in "+[AGE,SEX,EMP,HID,IID];}
			}
		}
		//write sample(age_map);
		//write sample(gender_map);
		//write sample(unemployed_map);
	}
	
	/*
	 * Transpose value and map pairs into a map to convert from file to COMOKIT variable convention
	 */
	map read_var_map(list var_row) {
		int idx <- 2;
		switch first(var_row) {
			match "age" {
				map<string,list<float>> res <- [];
				loop while:idx < length(var_row) { res[string(var_row[idx])] <- list<float>(var_row[idx+1]); idx <- idx+2; }
				if length(res)=1 and res contains_key "" {return nil;}
				return res;
			}
			match "sex" {
				map<string,int> res <- [];
				loop while:idx < length(var_row) { res[string(var_row[idx])] <- int(var_row[idx+1]); idx <- idx+2; }
				if length(res)=1 and res contains_key "" {return nil;}
				return res;
			}
			match "is_unemployed" {
				map<string,bool> res <- [];
				loop while:idx < length(var_row) { res[string(var_row[idx])] <- bool(var_row[idx+1]); idx <- idx+2; }
				if length(res)=1 and res contains_key "" {return nil;}
				return res;
			} 
			default {error "unknown variable "+first(var_row)+" to map synthetic entity attribute with";} 
		}
	}
	
	//#######################
	// Localisation algorithm
	//#######################
	
	/*
	 * Found a homeplace for a given household ID. Returns the choosen buildings.
	 */
	action assign_homeplace(list<list<Individual>> hhs, list<Building> homeplaces) {
		list<Building> avlb_homes <- copy(homeplaces);
		
		loop hh over:hhs {
			Building homeplace <- any(avlb_homes); // Uniform distribution | should we take HH size vs size of the building ?
			
			ask hh { home <- homeplace; relatives <- hh - self; }
			avlb_homes >- homeplace;
			
			if empty(avlb_homes) {avlb_homes <- copy(homeplaces);} // Reset available homeplace to be every home
			
		}
		
	}
	
	
	// ------------------------------------------- //
	// SYNTHETIC POPULATION FROM COMOKIT ALGORITHM //
	// ------------------------------------------- //
	
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
					create individual_species {
						age <- world._get_age(max_student_age + 1,retirement_age);
						sex <- 0;
						home <- myself;
						household << self;
					} 
					//mother
					create individual_species {
						age <- world._get_age(max_student_age + 1,retirement_age);
						sex <- 1;
						home <- myself;
						household << self;
					
					}
					//children
					int number <- min(number_children_max, round(gauss(number_children_mean,number_children_std)));
					if (number > 0) {
						create individual_species number: number {
							//last_activity <-first(staying_home);
							age <- world._get_age(maximum::max_student_age);
							sex <- world._get_sex();
							home <- myself;
							household << self;
						}
					}
					if (flip(proba_grandfather)) {
						create individual_species {
							age <- world._get_age(retirement_age + 1);
							sex <- 0;
							home <- myself;
							household << self;
						}
					}	
					if (flip(proba_grandmother)) {
						create individual_species {
							age <- world._get_age(retirement_age + 1);
							sex <- 1;
							home <- myself;
							household << self;
						}
					}
				} else {
					create individual_species {
						age <- world._get_age(min_student_age + 1);
						sex <- world._get_sex();
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
		ask all_individuals where ((each.age >= max_student_age) and (each.age < retirement_age)) {
			is_unemployed <- world._get_employment_status(sex);
		}	
	}
	
	// *************************************
	// Default demographic attribute methods
	// *************************************
	// To be consistant between file and generator 
	// base synthetic population
	
	/*
	 * Default way to define age
	 */
	 int _get_age(int minimum <- 0, int maximum <- max_age, map<int,float> dist <- nil) {
	 	if dist=nil or empty(dist) { return rnd(minimum,maximum);}
	 	else {return rnd_choice(dist);}
	 }
	 
	 /*
	  * Default way to define sex
	  */
	 int _get_sex(float male_proba <- male_ratio){ return flip(male_proba) ? 0 : 1; }
	  
	 /*
	  * 
	  */
	 bool _get_employment_status(int gender) {
	 	return flip((gender = 0) ? proba_unemployed_M : proba_unemployed_F);
	 }
	
	// ----------------------------------- //
	// SYNTHETIC POPULATION SOCIAL NETWORK //
	// ----------------------------------- //
	
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
		map<Building, list<Individual>> WP<- (all_individuals where (each.working_place != nil)) group_by each.working_place;
		map<Building, list<Individual>> Sc<- (all_individuals where (each.school != nil)) group_by each.school;
		list<int> age_cat <- [min_age_for_evening_act,min_student_age,max_student_age,
			retirement_age, max_age] sort (each);
		map<int,list<Individual>> ind_per_age_cat <- age_cat as_map (each::[]);
		
		loop p over: all_individuals {
			loop cat over: ind_per_age_cat.keys {
				if p.age < cat {
					ind_per_age_cat[cat]<<p;
					break;
				}  
			}
		}
		ask all_individuals { do initialise_social_network(WP, Sc,ind_per_age_cat); }
	}
	
	// ------------------------------------------------------- //
	// SYNTHETIC POPULATION SCHOOL / WORK LOCATION ASSIGNEMENT //
	// ------------------------------------------------------- //
	
	// Inputs
	//   working_places : map associating to each Building a weight (= surface * coefficient for this type of building to be a working_place)
	//   schools :  map associating with each school Building its area (as a weight of the number of students that can be in the school)
	//   min_student_age : minimum age to be in a school
	//   max_student_age : maximum age to go to a school
	action assign_school_working_place(map<Building,float> working_places, map<list<int>,list<Building>> schools, int min_student_age, int max_student_age) {
		// Assign to each individual a school and working_place depending of its age.
		// in addition, school and working_place can be outside.
		// Individuals too young or too old, do not have any working_place or school
		
		if empty(working_places) or empty(schools) {
			error "There is no "+(empty(working_places)?"working place ":"school ")+" to bind agent with";
		}
		 
		ask all_individuals {
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
					if flip(proba_work_at_home) {
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
	
	// ----------------- //
	// SYNTHETIC AGENDAS //
	// ----------------- //
	
	
	// Inputs
	//   min_student_age : minimum age to be in a school
	//   max_student_age : maximum age to go to a school
	// 
	// Principles: each individual has a week agenda composed by 7 daily agendas (maps of hour::Activity).
	//             The agenda depends on the age (students/workers, retired and young children).
	//             Students and workers have an agenda with working and leisure days (see parameter non_working_days).
	//             Retired have an agenda full of leisure days.
	action define_agenda(int min_student_age, int max_student_age) {
		
		float t <- machine_time;
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
		if (csv_activity_weights != nil) {
			matrix data <- matrix(csv_activity_weights);
			weight_activity_per_age_sex_class <- [];
			list<string> act_type;
			loop i from: 3 to: data.columns - 1 {
				act_type <<string(data[i,0]);
			}
			loop i from: 1 to: data.rows - 1 {
				list<int> cat <- [ int(data[0,i]),int(data[1,i])];
				map<int,map<string, float>> weights <- (cat in weight_activity_per_age_sex_class.keys) ? weight_activity_per_age_sex_class[cat] : map([]);
				int sex <- int(data[2,i]);
				map<string, float> weights_sex;
				loop j from: 0 to: length(act_type) - 1 {
					weights_sex[act_type[j]] <- float(data[j+3,i]); 
				}
				
				weights[sex] <- weights_sex;
				weight_activity_per_age_sex_class[cat] <- weights;
			}
		}	
		list<Activity> possible_activities_tot <- Activities.values - studying - working - staying_home;
		list<Activity> possible_activities_without_rel <- possible_activities_tot - visiting_friend;
		Activity eating_act <- Activity first_with (each.name = act_eating);
		ask all_individuals {
			loop times: 7 {agenda_week<<[];}
		}
		
		do console_output("-- input parameters processed in "+(machine_time-t)/1000+"s","synthetic population.gaml");
		t <- machine_time;
		
		list<Individual> active_people <- all_individuals where ((each.age < retirement_age) and (each.age >= min_student_age));
		int nb_active_people <- length(active_people);
		int loop_nb; 
				
		// Initialization for students or workers
		ask active_people {
			
			loop_nb <- loop_nb+1;
			if loop_nb mod (nb_active_people/10) = 0 {
				ask world {do console_output(" || "+(loop_nb*1.0/nb_active_people)+" processed in "
					+(machine_time-t)/1000+"s","synthetic population.gaml",first(levelList)
				);}
			}
			
			// Students and workers have an agenda similar for 6 days of the week ...
			if ((is_unemployed and age >= max_student_age) or 
				(age < max_student_age and flip(1.0-schoolarship_rate))
			) {
				loop i from:1 to: 7 {
					ask myself {do manag_day_off(myself,i,possible_activities_without_rel,possible_activities_tot);}
				} 
			} else {
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
						Activity act <- myself.activity_choice(self, possible_activities);
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
		}
		
		do console_output("-- active people agenda built in "+(machine_time-t)/1000+"s","synthetic population.gaml");
		t <- machine_time;
		
		// Initialization for retired individuals
		loop ind over: all_individuals where (each.age >= retirement_age) {
			loop i from:1 to: 7 {
				do manag_day_off(ind,i,possible_activities_without_rel,possible_activities_tot);
			}
		}
		
		do console_output("-- retired people agenda built in "+(machine_time-t)/1000+"s", "synthetic population.gaml");
		t <- machine_time;
		
		ask all_individuals {
			loop i from: 0 to: 6 {
				if (not empty(agenda_week[i])) {
					int last_act <- max(agenda_week[i].keys);
					if (species(agenda_week[i][last_act].key) != staying_home) {
						int h <- last_act = 23 ? 23 : min(23, last_act + rnd(1,max_duration_default));
						agenda_week[i][h] <- first(staying_home)::[];
					}
				}
			}
		}
		
		do console_output("-- add return home action "+(machine_time-t)/1000+"s", "synthetic population.gaml");
		t <- machine_time;
		
		if (choice_of_target_mode = gravity) {
			ask all_individuals {
				list<Activity> acts <- remove_duplicates((agenda_week accumulate each.values) collect each.key) inter list(Activity) ;
				loop act over: acts {
					map<string, list<Building>> bds;
					loop type over: act.types_of_building {
						list<Building> buildings <- act.buildings[type];
						if length(buildings) <= nb_candidates {
							bds[type] <- buildings;
						} else {
							list<Building> bds_;
							list<float> proba_per_building;
							loop b over: buildings {
								float dist <- max(20,b.location distance_to home.location);
								proba_per_building << (b.shape.area / dist ^ gravity_power);
							}
							loop while: length(bds_) < nb_candidates {
								bds_<< buildings[rnd_choice(proba_per_building)];
								bds_ <- remove_duplicates(bds_);
							}
							bds[type] <- bds_;
						}
						building_targets[act] <- bds;
					}
				}
			}
			
			do console_output("-- gravity setup "+(machine_time-t)/1000+"s", "synthetic population.gaml");
		
		}
				
	}
	
	Activity activity_choice(Individual ind, list<Activity> possible_activities) {
		if (weight_activity_per_age_sex_class = nil ) or empty(weight_activity_per_age_sex_class) {
			return any(possible_activities);
		}
		loop a over: weight_activity_per_age_sex_class.keys {
			if (ind.age >= a[0]) and (ind.age <= a[1]) {
				map<string, float> weight_act <-  weight_activity_per_age_sex_class[a][ind.sex];
				list<float> proba_activity <- possible_activities collect ((each.name in weight_act.keys) ? weight_act[each.name]:1.0 );
				if (sum(proba_activity) = 0) {return any(possible_activities);}
				return possible_activities[rnd_choice(proba_activity)];
			}
		}
		return any(possible_activities);
		
	}
	
	
	
	//specific construction of a "day off" (without work or school)
	action manag_day_off(Individual current_ind, int day, list<Activity> possible_activities_without_rel, list<Activity> possible_activities_tot) {
		map<int,pair<Activity,list<Individual>>> agenda_day <- current_ind.agenda_week[day - 1];
		list<Activity> possible_activities <- empty(current_ind.friends) ? possible_activities_without_rel : possible_activities_tot;
		int max_act <- (current_ind.age >= retirement_age) ? max_num_activity_for_old_people :(current_ind.is_unemployed ? max_num_activity_for_unemployed : max_num_activity_for_non_working_day);
		int num_activity <- rnd(1,max_act) - length(agenda_day);
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
			Activity act <-activity_choice(current_ind, possible_activities);
			if (species(act) = Activity) {
				
				list<Individual> cands <- current_ind.friends where ((each.agenda_week[day - 1][current_hour]) = nil);
				list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among cands;
				ask world {do console_output(
					current_ind.name + " : " + current_ind.age + " nb friends: " + length(current_ind.friends) 
					+ " inds: "+ length(inds) + " friend age: "+ (current_ind.friends collect each.age),
					caller::"Synthetic Population.gaml",level::"trace"
				);}
				loop ind over: inds {
					map<int,pair<Activity,list<Individual>>> agenda_day_ind <- ind.agenda_week[day - 1];
					agenda_day_ind[current_hour] <- act::(inds - ind + current_ind);
					bool return_home <- true;
					loop h from: current_hour + 1 to: end_hour {
						return_home <- agenda_day_ind[h] = nil;
						if not (return_home) {break;}
					}
					if (return_home) {agenda_day_ind[end_hour] <- staying_home[0]::[];}
					ask world {do console_output( 
						"ind.agenda_week: " + day + " -> "+ ind.agenda_week[day - 1], 
						caller::"Synthetic Population.gaml",level::"trace"
					);}
				}
				agenda_day[current_hour] <- act::inds;
			} else {
				agenda_day[current_hour] <- act::[];
			}
			agenda_day[end_hour] <- staying_home[0]::[];
			current_hour <- end_hour + 1;
		}
		current_ind.agenda_week[day-1] <- agenda_day;
	}
	
	
}

