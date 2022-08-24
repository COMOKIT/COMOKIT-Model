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

import "Global.gaml"   


//import "Entities/Building.gaml"
//import "Parameters.gaml"
 
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
		do console_output(sample(csv_population_attribute_mappers_path) +" exist: " + sample(file_exists(csv_population_attribute_mappers_path)));
		if (file_exists(csv_population_attribute_mappers_path)) { do read_mapping(); }
		file csv_population <- csv_file(csv_population_path,separator,qualifier,header);
		int pop_length <- length(csv_population);
		do console_output("Number of inhabitants: " + pop_length);
		do console_output("Number of inhabitants: " + pop_length +" " + sample(householdID) + " " + sample(separator) +" " + sample(qualifier) +" " + sample(header));
		create individual_species from:csv_population number: (number_of_individual <= 0 ?  pop_length:
			(number_of_individual <pop_length ? number_of_individual : pop_length) 
		)
		with:[
			age::convert_age(get(age_var)),
			sex::convert_gender(get(gender_var)),
			is_unemployed::convert_unemployed(get(unemployed_var)),
			household_id::convert_hhid(get(householdID)),
			individual_id::get(individualID) 
		]{ 
			if households contains_key household_id { households[household_id] <+ Individual(self); }
			else { households[household_id] <- [Individual(self)]; }
			if individual_id=nil or empty(individual_id) {individual_id <- name;}
		}
		
		list<Individual> hh_empty <- list<Individual>(all_individuals where (each.household_id = nil));
		do console_output("Number of inhabitants without households: " + length(hh_empty));
		
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
				if int(input) is int { return float(input); }
			}
		} 
		return float(_get_age());
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
		matrix data <- matrix(csv_file(csv_population_attribute_mappers_path,",",true));
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
			ask hh { home <- homeplace; relatives <- hh - self; 
			}
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
		
		if (file_exists(csv_parameter_population_path)) {
			csv_file csv_parameter_population <- csv_file(csv_parameter_population_path,",",true);
			loop i from: 0 to: csv_parameter_population.contents.rows - 1 {
				string parameter_name <- csv_parameter_population.contents[0,i];
				float value <- float(csv_parameter_population.contents[1,i]);
				world.shape.attributes[parameter_name] <- value;
				
			}
		}
		list<list<Individual>> households;
		ask homes parallel: parallel_computation{
			loop times: nb_households {
				list<Individual> household;
				if flip(proba_active_family) {
				//father
					create individual_species {
						
						age <- world._get_age(max_student_age + 1,retirement_age);
						sex <- 0;
						Individual(self).home <- myself;
						household << Individual(self);
					} 
					//mother
					create individual_species {
						age <- world._get_age(max_student_age + 1,retirement_age);
						sex <- 1;
						Individual(self).home <- myself;
						household << Individual(self);
					
					}
					//children
					int number <- min(number_children_max, round(gauss(number_children_mean,number_children_std)));
					if (number > 0) {
						create individual_species number: number {
							//last_activity <-first(staying_home);
							age <- world._get_age(maximum::max_student_age);
							sex <- world._get_sex();
							Individual(self).home <- myself;
							household << Individual(self);
						}
					}
					if (flip(proba_grandfather)) {
						create individual_species {
							age <- world._get_age(retirement_age + 1);
							sex <- 0;
							Individual(self).home <- myself;
							household << Individual(self);
						}
					}	
					if (flip(proba_grandmother)) {
						create individual_species {
							age <- world._get_age(retirement_age + 1);
							sex <- 1;
							Individual(self).home <- myself;
							household << Individual(self);
						}
					}
				} else {
					create individual_species {
						age <- world._get_age(min_student_age + 1);
						sex <- world._get_sex();
						Individual(self).home <- myself;
						household << Individual(self);
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
		list<Individual> individuals <- list<Individual> (all_individuals);
		map<Building, list<Individual>> WP<- (individuals where (each.working_place != nil)) group_by each.working_place;
		map<Building, list<Individual>> Sc<- (individuals where (each.school != nil)) group_by each.school;
		
		map<Building, map<int,list<Individual>>> Scs;
		loop bd over: Sc.keys {
			list<Individual> inds <- Sc[bd];
			Scs[bd] <- inds group_by each.age;
		}
		list<int> age_cat <- [5, 10, min_age_for_evening_act,min_student_age,max_student_age, 35, 50,
			retirement_age, max_age] sort (each);
		map<int,list<Individual>> ind_per_age_cat <- age_cat as_map (each::[]);
		
		loop p over: individuals {
			loop cat over: ind_per_age_cat.keys {
				if p.age < cat {
					ind_per_age_cat[cat]<<p;
					break;
				}  
			}
		}
		int cpt;
		ask individuals  parallel:parallel_computation{ 
			cpt <- cpt + 1;
			if cpt mod (length(all_individuals)/100) = 0 {
				ask world {do console_output("" + (cpt*100.0/length(all_individuals))+ " processed" );}
			}
			 
			do initialise_social_network(WP, Scs,ind_per_age_cat);
			 
			
		}
		
		
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
		
		ask list<Individual> (all_individuals) parallel: parallel_computation {
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
		if (file_exists(csv_parameter_agenda_path)) {
			csv_file csv_parameter_agenda <- csv_file(csv_parameter_agenda_path,",",true);
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
		if file_exists(csv_activity_weights_path) {
			matrix data <- matrix(csv_file(csv_activity_weights_path,",",string, false));
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
		list<Activity> possible_activities_tot <- list<Activity>(Activities.values) - studying - working - staying_home;
		list<Activity> possible_activities_without_rel <- possible_activities_tot - visiting_friend;
		Activity eating_act <- Activity first_with (each.name = act_eating);
		list<Individual> individuals <- list<Individual> (all_individuals);
		ask individuals {
			loop times: 7 {agenda_week<<[];}
		}
		
		do console_output("-- input parameters processed in "+(machine_time-t)/1000+"s","synthetic population.gaml");
		t <- machine_time;
		
		list<Individual> active_people <- individuals where ((each.age < retirement_age) and (each.age >= min_student_age));
		int nb_active_people <- length(active_people);
		int loop_nb; 
				
		// Initialization for students or workers
		ask active_people {
			
			loop_nb <- loop_nb+1;
			if loop_nb mod (nb_active_people/100) = 0 {
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
					int current_hour_;
					if (age < max_student_age) {
						current_hour_ <- rnd(school_hours_begin_min,school_hours_begin_max);
						agenda_day[current_hour_] <- studying[0]::[];
					} else {
						current_hour_ <-rnd(work_hours_begin_min,work_hours_begin_max);
						agenda_day[current_hour_] <- working[0]::[];
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
							current_hour_ <- rnd(lunch_hours_min,lunch_hours_max);
							int dur <- rnd(1,2);
							if (not flip(proba_lunch_at_home) and (eating_act != nil) and not empty(eating_act.buildings)) {
								list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among colleagues;
								loop ind over: inds {
									map<int,pair<Activity,list<Individual>>> agenda_day_ind <- ind.agenda_week[i - 1];
									agenda_day_ind[current_hour_] <- eating_act::(inds - ind + self);
									if (ind.age < max_student_age) {
										agenda_day_ind[current_hour_ + dur] <- studying[0]::[];
									} else {
										agenda_day_ind[current_hour_ + dur] <- working[0]::[];
									}
								}
								agenda_day[current_hour_] <- eating_act::inds ;
							} else {
								agenda_day[current_hour_] <- staying_home[0]::[];
							}
							current_hour_ <- current_hour_ + dur;
							if (age < max_student_age) {
								agenda_day[current_hour_] <- studying[0]::[];
							} else {
								agenda_day[current_hour_] <- working[0]::[];
							}
						}
					}
					if (age < max_student_age) {
						current_hour_ <- rnd(school_hours_end_min,school_hours_end_max);
					} else {
						current_hour_ <-rnd(work_hours_end_min,work_hours_end_max);
					}
					agenda_day[current_hour_] <- staying_home[0]::[];
					
					already <- false;
					loop h2 from: current_hour_ to: 23 {
						if (h2 in agenda_day.keys) {
							already <- true;
							break;
						}
					}
					if not already and (age >= min_age_for_evening_act) and flip(proba_activity_evening) {
						current_hour_ <- current_hour_ + rnd(1,max_duration_lunch);
						Activity act <- myself.activity_choice_meso(self, possible_activities);
						current_hour_ <- min(23,current_hour_ + rnd(1,max_duration_default));
						int end_hour <- min(23,current_hour_ + rnd(1,max_duration_default));
						if (species(act) = Activity) {
							list<Individual> cands <- friends where ((each.agenda_week[i - 1][current_hour_]) = nil);
							list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among cands;
							loop ind over: inds {
								map<int,pair<Activity,list<Individual>>> agenda_day_ind <- ind.agenda_week[i - 1];
								agenda_day_ind[current_hour_] <- act::(inds - ind + self);
								bool return_home <- true;
								loop h from: current_hour_ + 1 to: end_hour {
									return_home <- agenda_day_ind[h] = nil;
									if (not return_home) {break;}
								}
								if (return_home) {agenda_day_ind[end_hour] <- staying_home[0]::[];}
								
							}
							agenda_day[current_hour_] <- act::inds;
						} else {
							agenda_day[current_hour_] <- act::[];
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
		loop ind over: individuals where (each.age >= retirement_age) {
			loop i from:1 to: 7 {
				do manag_day_off(ind,i,possible_activities_without_rel,possible_activities_tot);
			}
		}
		
		do console_output("-- retired people agenda built in "+(machine_time-t)/1000+"s", "synthetic population.gaml");
		t <- machine_time;
		
		ask individuals {
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
			do manage_gravity_model;
			do console_output("-- gravity setup "+(machine_time-t)/1000+"s", "synthetic population.gaml");
		
		}
				
	}
	
	action manage_gravity_model {
		list<Individual> individuals <- list<Individual> (all_individuals);
		ask individuals parallel: parallel_computation{
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
			
	}
	
	Activity activity_choice_meso(Individual ind, list<Activity> possible_activities) {
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
		int current_hour_ <- rnd(first_act_hour_non_working_min,first_act_hour_non_working_max);
		loop times: num_activity {
			if (current_hour_ in forbiden_hours) {
				current_hour_ <- current_hour_ + 1;
				if (current_hour_ > 22) {
					break;
				} 
			}
			
			int end_hour <- min(23,current_hour_ + rnd(1,max_duration_default));
			if (end_hour in forbiden_hours) {
				end_hour <- forbiden_hours first_with (each > current_hour_) - 1;
			}
			if (current_hour_ >= end_hour) {
				break;
			}
			Activity act3 <-activity_choice_meso(current_ind, possible_activities);
			if (species(act3) = Activity) {
				
				list<Individual> cands <- current_ind.friends where ((each.agenda_week[day - 1][current_hour_]) = nil);
				list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among cands;
				loop ind over: inds {
					map<int,pair<Activity,list<Individual>>> agenda_day_ind <- ind.agenda_week[day - 1];
					agenda_day_ind[current_hour_] <- act3::(inds - ind + current_ind);
					bool return_home <- true;
					loop h from: current_hour_ + 1 to: end_hour {
						return_home <- agenda_day_ind[h] = nil;
						if not (return_home) {break;}
					}
					if (return_home) {agenda_day_ind[end_hour] <- staying_home[0]::[];}
				}
				agenda_day[current_hour_] <- act3::inds;
			} else {
				agenda_day[current_hour_] <- act3::[];
			}
			agenda_day[end_hour] <- staying_home[0]::[];
			current_hour_ <- end_hour + 1;
		}
		current_ind.agenda_week[day-1] <- agenda_day;
	}
	
	
	
	
	action load_population_and_agenda_from_file {
		create individual_species from: file(file_population_precomputation_path) returns: created_ind;
		//individuals <- copy(created_ind);
		all_buildings_map <- all_buildings as_map (to_bd_id(each)::each);
		int  i_bd <- 0;
		ask all_buildings_map.values {
			entities_inside  <- [];
			index_bd <- i_bd;
			i_bd <- i_bd +1;
		}
	//	do init_user_activity_precomputation;
		ask created_ind as: Individual{
			individual_id <- (string(shape get("id")));
			//household_id <- (string(shape get("h_id")));
			is_unemployed <- bool(string(shape get("is_unempl")));
			home <- all_buildings_map[string(shape get("home_id"))];
			list<string> bds_str <- string(shape get("buildings")) split_with ",";
			loop bd_str over:  bds_str {
				Building bd <- all_buildings_map[bd_str];
				if bd != nil {
					buildings_concerned << bd;
				}
			}
			/*school <- all_buildings_map[string(shape get("school_id"))];
			working_place <- all_buildings_map[string(shape get("wp_id"))];
			relatives <- world.from_ids(string(shape get("rel_id")));
			friends <- world.from_ids(string(shape get("friends_id")));
			colleagues <- world.from_ids(string(shape get("col_id")));
			last_activity <-first(staying_home);
			activity_fellows <- relatives;*/
			
			do enter_building(home);
		}
		//do load_agenda(individuals,all_buildings_map);
		
	} 
	
	action init_user_activity_precomputation_individual(Individual ind) {
		ask ind {
			index_building_agenda <- [];
			index_group_in_building_agenda <- [];
			buildings_concerned <- [];
		}
		loop times: nb_weeks_ref {
			ask ind {
				list<list<Building>> week_act <- [];
				list<list<int>> week_act2 <- [];
				loop times: 7 {
					list<Building> day_act <- [];
					list<int> day_act2 <- [];
					
					loop times: 24 {
						day_act << nil;
						day_act2 << 0;
					}
					week_act<<day_act; 
					week_act2<<day_act2; 
				}
				index_building_agenda << week_act;
				index_group_in_building_agenda << week_act2;
			}
		}
	}
	action init_user_activity_precomputation_building(Building bd) {
		ask bd {
			entities_inside <- [];
		}
		loop times: nb_weeks_ref {
			ask bd {
				list<list<list<list<Individual>>>> week_act <- [];
				loop times: 7 {
					list<list<list<Individual>>> day_act <- [];
					loop times: 24 {
						day_act << [];
					}
					week_act<<day_act; 
				}
				entities_inside << week_act;
			}
			
		}
	}
		
	action init_user_activity_precomputation_building_str(Building bd) {
		loop times: nb_weeks_ref {
			ask bd {
				list<list<list<list<int>>>> week_act <- [];
				loop times: 7 {
					list<list<list<int>>> day_act <- [];
					loop times: 24 {
						day_act << [];
					}
					week_act<<day_act; 
				}
				entities_inside_int << week_act;
			}
			
		}
	}
	
	
	action update_individual_intern(Individual ind,list<string> data_gen,	list<string> data_bd,list<string> data_gp, string file_activity_precomputation_path  ) {
		float t <- machine_time;
		do init_user_activity_precomputation_individual(ind);
		ask ind {
			loop i from: 11 to: length(data_gen) - 1{
				string bd_str <- data_gen[i] replace ("]","");
				Building bd <- all_buildings_map[bd_str];
				if bd = nil {
					bd <- world.load_building(bd_str,dataset_path+ precomputation_folder + file_building_precomputation_path,file_activity_precomputation_path+"/" +  file_building_precomputation_path);
					if bd != nil {
						all_buildings_map[bd_str] <- bd;
					}
				} else if not bd.precomputation_loaded {
					ask world{do update_building(bd,file_activity_precomputation_path+"/" +  file_building_precomputation_path );}	
				}
				if (bd != nil) {
					buildings_concerned << bd;
					bd.individuals_concerned << self;
				} else {
					write bd_str + " " + bd;
				}
			}
			home <- all_buildings_map[data_gen[10]];
			
			if home = nil {
				write sample(data_gen) +" " + sample(data_gen[6]);
			}
			current_place <- home;
			location <- home.location;
			int d <- 0;
			int h <- 0;
			int w <- 0;
			loop i from: 0 to: length(data_bd) - 1 {
				if h = 24 {
					h <- 0;
					d <- d + 1;
					if d = 7 {
						d <- 0;
						w <- w + 1;
					}
				}
				index_group_in_building_agenda[w][d][h] <- int(data_gp[i]);
				index_building_agenda[w][d][h] <- all_buildings_map[data_bd[i]];
				h <- h +1;
			}
		} 
		p20 <- p20 + machine_time - t;
	}
	
	action update_individual(Individual ind) {
		float t <- machine_time;
		string file_activity_precomputation_path <-  not politic_is_active ? (dataset_path+ precomputation_folder + file_activity_without_policy_precomputation_path): (dataset_path+ precomputation_folder + file_activity_with_policy_precomputation_path) ;
		string file_activity_precomputation_path_pop <- file_activity_precomputation_path +"/" + file_population_precomputation_path;
		list<string> file_activity <- file(file_activity_precomputation_path_pop +"/" + ind.id_int + ".data").contents;
		list<string> data_gen <- file_activity[0] split_with ",";
		list<string> data_bd <-  file_activity[1] split_with ",";
		list<string> data_gp <- file_activity[2] split_with ",";
		do update_individual_intern(ind,data_gen,data_bd,data_gp,file_activity_precomputation_path);
		
		p19 <- p19 + machine_time - t;
	 }
	
	AbstractIndividual load_individual(int ind_id) {
		float t <- machine_time;
		string file_activity_precomputation_path <-  not politic_is_active ? (dataset_path+ precomputation_folder + file_activity_without_policy_precomputation_path): (dataset_path+ precomputation_folder + file_activity_with_policy_precomputation_path) ;
		string file_activity_precomputation_path_pop <- file_activity_precomputation_path +"/" + file_population_precomputation_path;
		list<string> file_activity <- file(file_activity_precomputation_path_pop +"/" + ind_id + ".data").contents;
		list<string> data_gen <- file_activity[0] split_with ",";
		list<string> data_bd <-  file_activity[1] split_with ",";
		list<string> data_gp <- file_activity[2] split_with ",";
		
		Individual ind ;
		point loc <- {float(data_gen[1]), float(data_gen[2])}; 
		create individual_species with:(id_int: int(data_gen[0]), location: loc, age:int(data_gen[3]), sex:int(data_gen[4]), is_unemployed:bool(data_gen[5]), 
			factor_contact_rate_wearing_mask:float(data_gen[6]),proba_wearing_mask:float(data_gen[7]),vax_willingness:float(data_gen[8]),free_rider:bool(data_gen[9])) 
		{
			ind <- Individual(self);
			map history <- agents_history[ind_id];
			if history != nil {
				immunity <- history["immunity"];
				vaccine_history<- history["vaccine_history"];
				
			}
		}
		do update_individual_intern(ind,data_gen,data_bd,data_gp,file_activity_precomputation_path);
		
		file f <- file(dataset_path+ precomputation_folder + file_agenda_precomputation_path +"/" + ind_id + ".data");
		loop line over:  f{
			if "%%" in line {
				list<string> l_pre <- line split_with "%%";
				list<string> l <- l_pre[0] split_with "!!";
				if (length(l) > 1) {
					list<map<int, pair<Activity,list<Individual>>>> week <- [];
					if (length(l_pre) > 1) and (l_pre[1] != nil){
						ind.building_targets <- world.from_targets_id(l_pre[1]);
					}
					loop d over: l[1] split_with "&&" {
						if d != nil and not empty(d) {
							map<int, pair<Activity,list<Individual>>> day <- [];
							loop a over: d split_with "$$" {
								if a != nil and not empty(a) {
									list<string> act <- a split_with "@@";
									Activity activity <- nil;
									list<Individual> others <- [];
										
									if ("," in act[1]) {
										list<string> aa <- act[1] split_with ",";
										activity <- Activity(Activities[aa[0]]);
										/*loop i from: 1 to: length(aa) - 1 {
											others << individuals[int(aa[i])];
										}*/
									} else {
										activity <- Activity(Activities[act[1]]);
										
									}
									if activity != nil {
										pair<Activity,list<Individual>> to_add <- activity::others;
										int h <- int(act[0]);
										day[h] <- to_add;
											
									} 
								}
							}
							week << day;
						} else {
							week << [];
						}
					}
					ind.agenda_week <- week;
					if(length(ind.agenda_week) < 7) {
						loop times: 7 - length(ind.agenda_week) {
							ind.agenda_week << [];
						}
					}
				}
			}			
		}
		p18 <- p18 + machine_time - t;
		return ind;	
	}
	
	// Creating the buildings from a file (should be overloaded to add more attributes to buildings)
	Building load_building(string bd_str ,string file_bd_precomputation_path, string file_activity_precomputation_path ) {
		float t <- machine_time;
		
		string path_f <-  file_bd_precomputation_path +"/"  +bd_str + ".data";
		
		if !file_exists(path_f) {
			return nil;
		}
		list<string> data <- string(first(file(path_f).contents)) split_with ",";
		
		Building bd;
		point loc <- {float(data[1]), float(data[2] replace("']", ""))};
		
		create Building with:(id_int: int(data[0] copy_between (2,length(data[0]))), location: loc) {
			bd <- self;
			if (length(data) > 3) {
				loop i from: 3 to: length(data) - 1{
					string fct <- data[i];
					functions << fct;
				}
			} 
		}
		
		p17 <- p17 + machine_time - t;
		do update_building(bd,file_activity_precomputation_path );
		return bd;
	}
	
	// Creating the buildings from a file (should be overloaded to add more attributes to buildings)
	action update_building(Building bd ,string file_activity_precomputation_path ) {
		float t <- machine_time;
		file_activity_precomputation_path <- file_activity_precomputation_path +"/"  +to_bd_id(bd) + ".data";
		if bd != nil {
			bd.precomputation_loaded <- true;
			if file_exists(file_activity_precomputation_path) {
				do init_user_activity_precomputation_building_str;
				file ff <- file(file_activity_precomputation_path);
				loop line over: ff {
					if line != nil and not empty(line) and ("&" in line) {
						list<string> l1 <- line split_with "|";
						loop ll1 over: l1[1] split_with "&" {
							list<string> l2 <- ll1 split_with ";";
							int w <- int(l2[0]);
							int d <- int(l2[1]);
							int h <- int(l2[2]);
									
							int bd_ind <- bd.index_bd;//all_buildings index_of bd;
							loop l3 over: l2[3] split_with "$" {
								if l3 != nil and not empty(l3) {
									list<string> l33 <-  l3 split_with ",";
									list<int> inds <- [];
									loop l4 over: l33{
										if l4 != nil and not empty(l4) {
											
											inds << int(l4);
										}
									}
									if not empty(inds) {
										bd.entities_inside_int[w][d][h] <<inds;
									}
								}
							}
						}
					}
				}
			} else {
				write "BUG ..... " + file_activity_precomputation_path;
				//do pause;
			}
			
		}
		
		p16 <- p16 + machine_time - t;
	}

	
	
	map<Activity, map<string,list<Building>>> from_targets_id(string ids ) {
		map<Activity, map<string,list<Building>>> targets <- map([]);
		if ids = nil or empty(ids) {return targets;}
		list<string> acts <- ids split_with "$$";
		loop a_id over: acts {
			if a_id != nil and not empty(a_id) {
				list<string> id_a <- (a_id split_with "!");
				Activity act <- Activity(Activities[id_a[0]]);
				if (length(id_a) = 1) {
					targets[act] <- [];
					break;
				}
				map<string,list<Building>> map_types <- [];
				list<string> id_a_s <- id_a[1] split_with "&&";
				loop types over: id_a_s {
					
					list<string> tbd <- types split_with "@@";
					string type <- tbd[0];
					list<Building> bds <- [];
					if ( length(tbd) > 1 and tbd[1] != nil and not empty( tbd[1])) {
						loop bd over: tbd[1] split_with ",,"{
							if (bd != nil and not empty(bd)) {
								bds << all_buildings_map[bd];
							}
						}	
					}
					map_types[type] <- bds;
				}
				targets[act] <- map_types;
			}
		}
		return targets;
	}
	

	
	list<Individual> from_ids(string ids) {
		list<Individual> list_ind <- [];
		if ids = nil or empty(ids) {return list_ind;}
		loop id over: ids split_with "," {
			list_ind << Individual(individual_species[int(id)]);
		}
		return list_ind;
	}
	
	string to_bds_id (list<Building> bds){
		string results <- "";
		loop bd over: bds {
			results <- results + "," + world.to_bd_id(bd);
		}
		return results;
	}
	string to_bd_id(Building bd) {
		if bd = nil {
			return "";
		}
		return string(species(bd)) +"_"+ bd.id_int;
	}
	float t1;float t2;float t3;float t4;float t5;float t6;float t7;float t8;float t9;
	map<Activity,float> time_act;
	
	action precompute_activities {
		float t <- machine_time;
		 do console_output( "precompute_activities start");
		 int id_i <- 0;
		 ask Building {
		 	id_int <- id_i;
		 	id_i <- id_i +1;
		 }
		if empty(all_buildings_map){
			all_buildings_map <- (list<Building>(Building.population+(Building.subspecies accumulate each.population))) as_map (to_bd_id(each)::each);
		}
		
		map<Building, int> to_index;
		loop i from: 0 to: length(all_buildings) - 1 {
			to_index[all_buildings[i]] <- i;
		}
		
		ask all_individuals as: Individual {
			last_activity <- first(staying_home);
			activity_fellows <- list<Individual>(relatives);
		}
		int i <- 0;
		ask all_individuals {
			id_int <- i;
			i <- i + 1;
			
		}
		loop ind over: all_individuals {
			do init_user_activity_precomputation_individual(Individual(ind));
		}

		//do init_user_activity_precomputation;
		loop bd over: all_buildings_map.values {
			do init_user_activity_precomputation_building(bd);
		} 
		date date_ref <- copy(starting_date);
		date date_end <- copy(date_ref) add_weeks nb_weeks_ref; 
		
		t1 <- t1 + machine_time - t;
		do console_output( "end of first step of precomputation: " + t1);
		loop act over: Activities.values {
			time_act[Activity(act)] <- 0.0;
		}
		ask experiment {do compact_memory;}
		loop while: date_ref <= date_end {
		 	float ttt <- machine_time;
		 	do console_output( "Generate agenda for date: " + date_ref);
			int w <- int((date_ref - starting_date) / #week);
			if w > nb_weeks_ref {
				
				break;
			}
			
			int d <- date_ref.day_of_week - 1;
			int h <- date_ref.hour;
			int cpt <- 0;
			list<int> ref_group;
			loop times: length(individual_species) {ref_group<<-1;}
			t2 <- t2 + machine_time - ttt;
			ttt <- machine_time;
			ask individual_species parallel: parallel_computation as: Individual{
				/*if (cpt mod int(length(individual_species)/100) = 0) {
					ask world{ do console_output( "processing precomputation: " + int(cpt * 100 / length(individual_species))  + "% " +
						sample(t1) +" " + sample(t2)+" " + sample(t3)+" " + sample(t4)+" " + sample(t5)+" " + sample(t6)+" " + sample(t7)+" " + sample(t8) +" " + sample(t9) +" " + sample(time_act)
						
					);}
				}*/
				float tttt <- machine_time;
				pair<Activity, list<Individual>> act <- agenda_week[d][h];
				if (act.key != nil) {
					if (Authority[0].allows(self, act.key)) {
						float tt <- machine_time;
				
						int nb_fellows <- Authority[0].limitGroupActivity(self, act.key) - 1;
						if (nb_fellows > 0) {
							activity_fellows <- nb_fellows among act.value;
						} else {
							activity_fellows <- [];
						}
					
					if BENCHMARK { 
										bench["Precompute_activity_fellows"] <- (bench contains_key "Precompute_activity_fellows" ? 
											bench["Precompute_activity_fellows"] : 0.0) + machine_time - tttt;
									}
					t5 <- t5 + machine_time - tttt;
					tttt <- machine_time;
				
						map<Building, list<Individual>> bds_ind <- act.key.find_target(self);
						float t6t <- machine_time - tttt;
						time_act[ act.key] <- time_act[ act.key] + t6t;
							t6<- t6 + t6t;
					tttt <- machine_time;
				
						if not empty(bds_ind) {
							current_place <- any(bds_ind.keys);
							activity_fellows <- bds_ind[current_place];
							buildings_concerned << current_place;
						}
							t7 <- t7 + machine_time - tttt;
				
							if BENCHMARK { 
										bench["Precompute_chose_place"] <- (bench contains_key "Precompute_chose_place" ? 
											bench["Precompute_chose_place"] : 0.0) + machine_time - tttt;
									}
					}
					if (current_place = nil) {
						write name + "->" + act + " "+ agenda_week[d];
					}else {
						if (current_place.entities_inside = nil) {
							write name + "->" + current_place;
						}
					}

				}
				if BENCHMARK { 
					bench["Precompute_ind"] <- (bench contains_key "Precompute_ind" ? 
						bench["Precompute_ind"] : 0.0) + machine_time - t;
				}
						
				cpt <- cpt + 1;
			}
			t3 <- t3 + machine_time - ttt;
			ttt <- machine_time;
			
			int ind <- 0;
			ask individual_species as: Individual{
				if (w < length(current_place.entities_inside)) {
					list<list<list<list<Individual>>>> ent_w <-current_place.entities_inside[w] ;
					if (d < length(ent_w)) {
						list<list<list<Individual>>> ent_d <- ent_w[d];
						if (h < length(ent_d)) {
							list<list<Individual>> ent <- ent_d[h];
							bool added <- false;
							int index <- ref_group[ind];
							
							buildings_concerned << current_place;
							if (index != -1) and index < length(ent) {
								ent[index] << self; 
								index_building_agenda[w][d][h] <- current_place;
								index_group_in_building_agenda[w][d][h] <- index;
								//to_remove_if_actif << [to_index[current_place], w, d, h, index];
							} else {
								current_place.entities_inside[w][d][h] << [self];
								index <- length(current_place.entities_inside[w][d][h]) - 1;
								index_group_in_building_agenda[w][d][h] <- index;
							//	to_remove_if_actif << [to_index[current_place], w, d, h, index];
								index_building_agenda[w][d][h] <- current_place;
								if (activity_fellows != nil) {
									loop f over: activity_fellows {
										ref_group[f.id_int] <- index;
									}
								}
								
							}
							ind <- ind + 1;
						}
					}
					
				}
				buildings_concerned <- remove_duplicates(buildings_concerned);
			}
			t4 <- t4+ machine_time - ttt;
			

			date_ref <- date_ref + step;
		}

		ask all_individuals as: Individual{
			last_activity <- first(staying_home);
			activity_fellows <- list<Individual>(relatives);
			current_place <- home;
		}

		 do console_output( "precompute_activities end");
	}
	
	bool inGroup(list<BiologicalEntity> g1, list<BiologicalEntity> g2) {
		loop g over: g1 {
			if g in g2 {
				return true;
			}
		}
		return false;
	}
}



