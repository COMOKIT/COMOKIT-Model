/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Global


import "species/Building.gaml"
import "species/Individual.gaml"
import "species/Hospital.gaml"
import "species/Activity.gaml"
import "species/Boundary.gaml"
import "species/Authority.gaml"
import "species/Activity.gaml"
import "species/Policy.gaml"
import "Constants.gaml"
import "Parameters.gaml"
import "Synthetic Population.gaml"

global {
	geometry shape <- envelope(shp_buildings);
	outside the_outside;
	map<int,map<string,list<string>>> map_epidemiological_parameters;
	action global_init {
		
		write "global init";
		if (shp_commune != nil) {
			create Boundary from: shp_commune;
		}
		if (shp_buildings != nil) {
			create Building from: shp_buildings with: [type::string(read("type"))];
		}
		
		create outside;
		the_outside <- first(outside);
		do create_activities;
		
		list<Building> homes <- Building where (each.type in possible_homes);
		map<string,list<Building>> buildings_per_activity <- Building group_by (each.type);
		
		map<Building,float> working_places;
		loop wp over: possible_workplaces.keys {
			if (wp in buildings_per_activity.keys) {
					working_places <- working_places +  (buildings_per_activity[wp] as_map (each:: (possible_workplaces[wp] * each.shape.area)));  
			}
		}
		
		int min_student_age <- retirement_age;
		int max_student_age <- 0;
		map<list<int>,map<Building,float>> schools;
		loop l over: possible_schools.keys {
			max_student_age <- max(max_student_age, max(l));
			min_student_age <- min(min_student_age, min(l));
			string type <- possible_schools[l];
			schools[l] <- (type in buildings_per_activity.keys) ? (buildings_per_activity[type] as_map (each:: each.shape.area)) : map<Building,float>([]);
		}
			
		if(csv_population != nil) {
			do create_population_from_file(working_places, schools, homes);
		} else {
			do create_population(working_places, schools, homes, min_student_age, max_student_age);
		}
		ask Individual {
			do initialize;
		}
		
		
		do assign_school_working_place(working_places,schools, min_student_age, max_student_age);
		
		do define_agenda(min_student_age, max_student_age);	


		ask num_infected_init among Individual {
			do defineNewCase;
		}
		
		total_number_individual <- length(Individual);

	}


	// Inputs
	//   working_places : map associating to each Building a weight (= surface * coefficient for this type of building to be a working_place)
	//   schools :  map associating with each school Building its area (as a weight of the number of students that can be in the school)
	//   min_student_age : minimum age to be in a school
	//   max_student_age : maximum age to go to a school
	action assign_school_working_place(map<Building,float> working_places,map<list<int>,map<Building,float>> schools, int min_student_age, int max_student_age) {
		
		// Assign to each individual a school and working_place depending of its age.
		// in addition, school and working_place can be outside.
		// Individuals too young or too old, do not have any working_place or school 
		ask Individual {
			last_activity <-first(staying_home);
			do enter_building(home);
			if (age >= min_student_age) {
				if (age <= max_student_age) {
					loop l over: schools.keys {
						if (age >= min(l) and age <= max(l)) {
							if (flip(proba_go_outside) or empty(schools[l])) {
								school <- the_outside;	
							} else {
								school <-schools[l].keys[rnd_choice(schools[l].values)];
							}
						}
					}
				} else if (age <= retirement_age) { 
					if (flip(proba_go_outside) or empty(working_places)) {
						working_place <- the_outside;	
					} else {
						working_place <-working_places.keys[rnd_choice(working_places.values)];
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
		
		Activity eating_act <- Activity first_with (each.name = act_eating);
		list<Activity> possible_activities_tot <- Activities.values - studying - working - staying_home;
		list<Activity> possible_activities_without_rel <- possible_activities_tot - visiting_friend;
		
		// Initialization for students or workers
		ask Individual where ((each.age <= retirement_age) and (each.age >= min_student_age))  {
			loop times: 7 {agenda_week<<[];}
			// Students and workers have an agenda similar for 6 days of the week ...
			loop i over: ([1,2,3,4,5,6,7] - non_working_days) {
				map<int,Activity> agenda_day;
				list<Activity> possible_activities <- empty(relatives) ? possible_activities_without_rel : possible_activities_tot;
				int current_hour;
				if (age <= max_student_age) {
					current_hour <- rnd(school_hours[0][0],school_hours[0][1]);
					agenda_day[current_hour] <- studying[0];
				} else {
					current_hour <-rnd(work_hours[0][0],work_hours[0][1]);
					agenda_day[current_hour] <- working[0];
				}
				if (flip(proba_lunch_outside_workplace)) {
					current_hour <- rnd(lunch_hours[0],lunch_hours[1]);
					if (not flip(proba_lunch_at_home) and (eating_act != nil) and not empty(eating_act.buildings)) {
						agenda_day[current_hour] <- eating_act;
					} else {
						agenda_day[current_hour] <- staying_home[0];
					}
					current_hour <- current_hour + rnd(1,2);
					if (age <= max_student_age) {
						agenda_day[current_hour] <- studying[0];
					} else {
						agenda_day[current_hour] <- working[0];
					}
				}
				if (age <= max_student_age) {
						current_hour <- rnd(school_hours[1][0],school_hours[1][1]);
				} else {
					current_hour <-rnd(work_hours[1][0],work_hours[1][1]);
				}
				agenda_day[current_hour] <- staying_home[0];
				current_hour <- current_hour + rnd(1,max_duration_lunch);
				
				if (age >= min_age_for_evening_act) and flip(proba_activity_evening) {
					agenda_day[current_hour] <- any(possible_activities);
					current_hour <- (current_hour + rnd(1,max_duration_default)) mod 24;
					agenda_day[current_hour] <- staying_home[0];
				}
				agenda_week[i-1] <- agenda_day;
			}
			
			// ... but it is diferent for non working days : they will pick activities among the ones that are not working, studying or staying home.
			loop i over: non_working_days {
				map<int,Activity> agenda_day;
				list<Activity> possible_activities <- empty(relatives) ? possible_activities_without_rel : possible_activities_tot;
				int num_activity <- rnd(0,max_num_activity_for_non_working_day);
				int current_hour <- rnd(first_act_old_hours[0],first_act_old_hours[1]);
				loop times: num_activity {
					agenda_day[current_hour] <- any(possible_activities);
					current_hour <- (current_hour + rnd(1,max_duration_default)) mod 24;
					agenda_day[current_hour] <- staying_home[0];
					current_hour <- (current_hour + rnd(1,max_duration_default)) mod 24;
				}
				agenda_week[i-1] <- agenda_day;
			}
			
		}
		
		// Initialization for retired individuals
		ask Individual where (each.age > retirement_age) {
			loop times: 7 {
				map<int,Activity> agenda_day;
				list<Activity> possible_activities <- empty(relatives) ? possible_activities_without_rel : possible_activities_tot;
				int num_activity <- rnd(0,max_num_activity_for_old_people);
				int current_hour <- rnd(first_act_old_hours[0],first_act_old_hours[1]);
				loop times: num_activity {
					agenda_day[current_hour] <- any(possible_activities);
					current_hour <- (current_hour + rnd(1,max_duration_default)) mod 24;
					agenda_day[current_hour] <- staying_home[0];
					current_hour <- (current_hour + rnd(1,max_duration_default)) mod 24;
				}
				agenda_week << agenda_day;
			}
		}
		
		// Initialization for the young children (before going to school)
		ask Individual where empty(each.agenda_week) {
			loop times:7 {
				agenda_week<<[];
			}
		} 
	}
	
	action init_epidemiological_parameters
	{
		if(load_epidemiological_parameter_from_file and file_exists(epidemiological_parameters))
		{
			csv_parameters <- csv_file(epidemiological_parameters,true);
			matrix data <- matrix(csv_parameters);
			map<string, list<int>> map_parameters;
			list possible_parameters <- distinct(data column_at epidemiological_csv_column_name);
			loop i from: 0 to: data.rows-1{
				if(contains(map_parameters.keys, data[epidemiological_csv_column_name,i] ))
				{
					add i to: map_parameters[string(data[epidemiological_csv_column_name,i])];
				}
				else
				{
					list<int> tmp_list;
					add i to: tmp_list;
					add tmp_list to: map_parameters at: string(data[epidemiological_csv_column_name,i]);
				}
			}
			loop aKey over: map_parameters.keys {
				switch aKey{
					match epidemiological_transmission_human{
						transmission_human <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):transmission_human;
					}
					match epidemiological_transmission_building{
						transmission_building <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):transmission_building;
					}
					match epidemiological_basic_viral_decrease{
						basic_viral_decrease <- float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):basic_viral_decrease;
					}
					match epidemiological_successful_contact_rate_building{
						successful_contact_rate_building <- float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):successful_contact_rate_building;
					}
					default{
						loop i from: 0 to:length(map_parameters[aKey])-1
						{
							int index_column <- map_parameters[aKey][i];
							list<string> tmp_list <- list(string(data[epidemiological_csv_column_detail,index_column]),string(data[epidemiological_csv_column_parameter_one,index_column]),string(data[epidemiological_csv_column_parameter_two,index_column]));
							if(i=length(map_parameters[aKey])-1)
							{
								loop aYear from:int(data[epidemiological_csv_column_age,index_column]) to: max_age
								{
									if(contains(map_epidemiological_parameters.keys,aYear))
									{
										add tmp_list to: map_epidemiological_parameters[aYear] at: string(data[epidemiological_csv_column_name,index_column]);
									}
									else
									{
										map<string, list<string>> tmp_map;
										add tmp_list to: tmp_map at: string(data[epidemiological_csv_column_name,index_column]);
										add tmp_map to: map_epidemiological_parameters at: aYear;
									}
								}
							}
							else
							{
								loop aYear from: int(data[epidemiological_csv_column_age,index_column]) to: int(data[epidemiological_csv_column_age,map_parameters[aKey][i+1]])-1
								{
									if(contains(map_epidemiological_parameters.keys,aYear))
									{
										add tmp_list to: map_epidemiological_parameters[aYear] at: string(data[epidemiological_csv_column_name,index_column]);
									}
									else
									{
										map<string, list<string>> tmp_map;
										add tmp_list to: tmp_map at: string(data[epidemiological_csv_column_name,index_column]);
										add tmp_map to: map_epidemiological_parameters at: aYear;
									}
								}
							}
						}
					}
				}
			}
		}
		else
		{
			loop aYear from:0 to: max_age
			{
				map<string, list<string>> tmp_map;
				add list(epidemiological_fixed,string(successful_contact_rate_human)) to: tmp_map at: epidemiological_successful_contact_rate_human;
				add list(epidemiological_fixed,string(reduction_contact_rate_asymptomatic)) to: tmp_map at: epidemiological_reduction_asymptomatic;
				add list(epidemiological_fixed,string(proportion_asymptomatic)) to: tmp_map at: epidemiological_proportion_asymptomatic;
				add list(epidemiological_fixed,string(proportion_dead_symptomatic)) to: tmp_map at: epidemiological_proportion_death_symptomatic;
				add list(epidemiological_fixed,string(basic_viral_release)) to: tmp_map at: epidemiological_basic_viral_release;
				add list(epidemiological_fixed,string(probability_true_positive)) to: tmp_map at: epidemiological_probability_true_positive;
				add list(epidemiological_fixed,string(probability_true_negative)) to: tmp_map at: epidemiological_probability_true_negative;
				add list(epidemiological_fixed,string(proportion_wearing_mask)) to: tmp_map at: epidemiological_proportion_wearing_mask;
				add list(epidemiological_fixed,string(reduction_contact_rate_wearing_mask)) to: tmp_map at: epidemiological_reduction_wearing_mask;
				add list(distribution_type_incubation,string(parameter_1_incubation),string(parameter_2_incubation)) to: tmp_map at: epidemiological_incubation_period;
				add list(distribution_type_serial_interval,string(parameter_1_serial_interval),string(parameter_2_serial_interval)) to: tmp_map at: epidemiological_serial_interval;
				add list(epidemiological_fixed,string(proportion_hospitalization)) to: tmp_map at: epidemiological_proportion_hospitalization;
				add list(epidemiological_fixed,string(proportion_icu)) to: tmp_map at: epidemiological_proportion_icu;
				add list(distribution_type_onset_to_recovery,string(parameter_1_onset_to_recovery),string(parameter_2_onset_to_recovery)) to: tmp_map at: epidemiological_onset_to_recovery;
				add tmp_map to: map_epidemiological_parameters at: aYear;
			}
		}
		
		loop aParameter over: force_parameters
		{
			list<string> list_value;
			switch aParameter
			{
				match epidemiological_successful_contact_rate_human{
					list_value <- list<string>(epidemiological_fixed,successful_contact_rate_human);
				}
				match epidemiological_reduction_asymptomatic{
					list_value <- list<string>(epidemiological_fixed,reduction_contact_rate_asymptomatic);
				}
				match epidemiological_proportion_asymptomatic{
					list_value <- list<string>(epidemiological_fixed,proportion_asymptomatic);
				}
				match epidemiological_proportion_death_symptomatic{
					list_value <- list<string>(epidemiological_fixed,proportion_dead_symptomatic);
				}
				match epidemiological_basic_viral_release{
					list_value <- list<string>(epidemiological_fixed,basic_viral_release);
				}
				match epidemiological_probability_true_positive{
					list_value <- list<string>(epidemiological_fixed,probability_true_positive);
				}
				match epidemiological_probability_true_negative{
					list_value <- list<string>(epidemiological_fixed,probability_true_negative);
				}
				match epidemiological_proportion_wearing_mask{
					list_value <- list<string>(epidemiological_fixed,proportion_wearing_mask);
				}
				match epidemiological_reduction_wearing_mask{
					list_value <- list<string>(epidemiological_fixed,reduction_contact_rate_wearing_mask);
				}
				match epidemiological_incubation_period{
					list_value <- list<string>(distribution_type_incubation,string(parameter_1_incubation),string(parameter_2_incubation));
				}
				match epidemiological_serial_interval{
					list_value <- list<string>(distribution_type_serial_interval,string(parameter_1_serial_interval));
				}
				match epidemiological_onset_to_recovery{
					list_value <- list<string>(distribution_type_onset_to_recovery,string(parameter_1_onset_to_recovery),string(parameter_2_onset_to_recovery));
				}
				match epidemiological_proportion_hospitalization{
					list_value <- list<string>(epidemiological_fixed,proportion_hospitalization);
				}
				match epidemiological_proportion_icu{
					list_value <- list<string>(epidemiological_fixed,proportion_icu);
				}
				default{
					
				}
				
			}
			if(list_value !=nil)
			{
				loop aYear from:0 to: max_age
				{
					map_epidemiological_parameters[aYear][aParameter] <- list_value;
				}
			}
		}
	}

}