/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Benoit Gaudou, Damien Philippon, Patrick Taillandier
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Entities/Building.gaml"
import "Entities/Individual.gaml"
import "Entities/Hospital.gaml"
import "Entities/Activity.gaml"
import "Entities/Boundary.gaml"
import "Entities/Authority.gaml"
import "Entities/Activity.gaml"
import "Entities/Policy.gaml"
import "Constants.gaml"
import "Parameters.gaml"
import "Synthetic Population.gaml"

global {
	geometry shape <- envelope(shp_buildings);
	outside the_outside;
	map<int,map<string,list<string>>> map_epidemiological_parameters;
	action global_init {
		
		write "global init";
		if (shp_boundary != nil) {
			create Boundary from: shp_boundary;
		}
		if (shp_buildings != nil) {
			create Building from: shp_buildings with: [type::string(read(type_shp_attribute)), nb_households::max(1,int(read(flat_shp_attribute)))];
		}
		
		loop aBuilding_Type over: Building collect(each.type)
		{
			add 0 at: aBuilding_Type to: building_infections;
		}
		create outside;
		the_outside <- first(outside);
		do create_activities;
		do create_hospital;
		
		list<Building> homes <- Building where (each.type in possible_homes);
		map<string,list<Building>> buildings_per_activity <- Building group_by (each.type);
		
		map<Building,float> working_places;
		loop wp over: possible_workplaces.keys {
			if (wp in buildings_per_activity.keys) {
					working_places <- working_places +  (buildings_per_activity[wp] as_map (each:: (each.shape.area * possible_workplaces[wp])));  
			}
		}
		
		int min_student_age <- retirement_age;
		int max_student_age <- 0;
		map<list<int>,list<Building>> schools;
		loop l over: possible_schools.keys {
			max_student_age <- max(max_student_age, max(l));
			min_student_age <- min(min_student_age, min(l));
			string type <- possible_schools[l];
			schools[l] <- (type in buildings_per_activity.keys) ? buildings_per_activity[type] : list<Building>([]);
		}
			
		if(csv_population != nil) {
			do create_population_from_file(working_places, schools, homes);
		} else {
			do create_population(working_places, schools, homes, min_student_age, max_student_age);
		}
		ask Individual {
			do initialise_epidemio;
		}
		do assign_school_working_place(working_places,schools, min_student_age, max_student_age);
		
		do create_social_networks(min_student_age, max_student_age);	
		
		do define_agenda(min_student_age, max_student_age);	

		ask num_infected_init among Individual {
			do define_new_case;
		}
		
		total_number_individual <- length(Individual);

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
						allow_transmission_human <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_transmission_human;
					}
					match epidemiological_transmission_building{
						allow_transmission_building <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_transmission_building;
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
				add list(epidemiological_fixed,string(init_all_ages_successful_contact_rate_human)) to: tmp_map at: epidemiological_successful_contact_rate_human;
				add list(epidemiological_fixed,string(init_all_ages_factor_contact_rate_asymptomatic)) to: tmp_map at: epidemiological_factor_asymptomatic;
				add list(epidemiological_fixed,string(init_all_ages_proportion_asymptomatic)) to: tmp_map at: epidemiological_proportion_asymptomatic;
				add list(epidemiological_fixed,string(init_all_ages_proportion_dead_symptomatic)) to: tmp_map at: epidemiological_proportion_death_symptomatic;
				add list(epidemiological_fixed,string(basic_viral_release)) to: tmp_map at: epidemiological_basic_viral_release;
				add list(epidemiological_fixed,string(init_all_ages_probability_true_positive)) to: tmp_map at: epidemiological_probability_true_positive;
				add list(epidemiological_fixed,string(init_all_ages_probability_true_negative)) to: tmp_map at: epidemiological_probability_true_negative;
				add list(epidemiological_fixed,string(init_all_ages_proportion_wearing_mask)) to: tmp_map at: epidemiological_proportion_wearing_mask;
				add list(epidemiological_fixed,string(init_all_ages_factor_contact_rate_wearing_mask)) to: tmp_map at: epidemiological_factor_wearing_mask;
				add list(init_all_ages_distribution_type_incubation,string(init_all_ages_parameter_1_incubation),string(init_all_ages_parameter_2_incubation)) to: tmp_map at: epidemiological_incubation_period;
				add list(init_all_ages_distribution_type_serial_interval,string(init_all_ages_parameter_1_serial_interval),string(init_all_ages_parameter_2_serial_interval)) to: tmp_map at: epidemiological_serial_interval;
				add list(epidemiological_fixed,string(init_all_ages_proportion_hospitalisation)) to: tmp_map at: epidemiological_proportion_hospitalisation;
				add list(epidemiological_fixed,string(init_all_ages_proportion_icu)) to: tmp_map at: epidemiological_proportion_icu;
				add list(init_all_ages_distribution_type_onset_to_recovery,string(init_all_ages_parameter_1_onset_to_recovery),string(init_all_ages_parameter_2_onset_to_recovery)) to: tmp_map at: epidemiological_onset_to_recovery;
				add list(init_all_ages_distribution_type_onset_to_hospitalisation,string(init_all_ages_parameter_1_onset_to_hospitalisation),string(init_all_ages_parameter_2_onset_to_hospitalisation)) to: tmp_map at: epidemiological_onset_to_hospitalisation;
				add list(init_all_ages_distribution_type_hospitalisation_to_ICU,string(init_all_ages_parameter_1_hospitalisation_to_ICU),string(init_all_ages_parameter_2_hospitalisation_to_ICU)) to: tmp_map at: epidemiological_hospitalisation_to_ICU;
				add list(init_all_ages_distribution_type_stay_ICU,string(init_all_ages_parameter_1_stay_ICU),string(init_all_ages_parameter_2_stay_ICU)) to: tmp_map at: epidemiological_stay_ICU;
				add tmp_map to: map_epidemiological_parameters at: aYear;
			}
		}
		
		loop aParameter over: force_parameters
		{
			list<string> list_value;
			switch aParameter
			{
				match epidemiological_successful_contact_rate_human{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_successful_contact_rate_human);
				}
				match epidemiological_factor_asymptomatic{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_factor_contact_rate_asymptomatic);
				}
				match epidemiological_proportion_asymptomatic{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_asymptomatic);
				}
				match epidemiological_proportion_death_symptomatic{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_dead_symptomatic);
				}
				match epidemiological_basic_viral_release{
					list_value <- list<string>(epidemiological_fixed,basic_viral_release);
				}
				match epidemiological_probability_true_positive{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_probability_true_positive);
				}
				match epidemiological_probability_true_negative{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_probability_true_negative);
				}
				match epidemiological_proportion_wearing_mask{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_wearing_mask);
				}
				match epidemiological_factor_wearing_mask{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_factor_contact_rate_wearing_mask);
				}
				match epidemiological_incubation_period{
					list_value <- list<string>(init_all_ages_distribution_type_incubation,string(init_all_ages_parameter_1_incubation),string(init_all_ages_parameter_2_incubation));
				}
				match epidemiological_serial_interval{
					list_value <- list<string>(init_all_ages_distribution_type_serial_interval,string(init_all_ages_parameter_1_serial_interval));
				}
				match epidemiological_onset_to_recovery{
					list_value <- list<string>(init_all_ages_distribution_type_onset_to_recovery,string(init_all_ages_parameter_1_onset_to_recovery),string(init_all_ages_parameter_2_onset_to_recovery));
				}
				match epidemiological_proportion_hospitalisation{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_hospitalisation);
				}
				match epidemiological_onset_to_hospitalisation{
					list_value <- list<string>(init_all_ages_distribution_type_onset_to_hospitalisation,string(init_all_ages_parameter_1_onset_to_hospitalisation),string(init_all_ages_parameter_2_onset_to_hospitalisation));
				}
				match epidemiological_proportion_icu{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_icu);
				}
				match epidemiological_hospitalisation_to_ICU{
					list_value <- list<string>(init_all_ages_distribution_type_hospitalisation_to_ICU,string(init_all_ages_parameter_1_hospitalisation_to_ICU),string(init_all_ages_parameter_2_hospitalisation_to_ICU));
				}
				match epidemiological_stay_ICU{
					list_value <- list<string>(init_all_ages_distribution_type_stay_ICU,string(init_all_ages_parameter_1_stay_ICU),string(init_all_ages_parameter_2_stay_ICU));
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