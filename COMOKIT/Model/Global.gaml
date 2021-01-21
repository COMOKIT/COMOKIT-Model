/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* This file contains global declarations of actions and attributes, used
* mainly for the purpose of initialising the model in experiments
* 
* Author: Benoit Gaudou, Damien Philippon, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

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
	
	
	/**
	 * Individuals access
	 */
	 
	species<Individual> individual_species <- Individual; // by default
	container<Individual> all_individuals -> {container<Individual>(individual_species.population+(individual_species.subspecies accumulate each.population))};
	geometry shape <- envelope(shp_buildings);
	outside the_outside;
	
	list<string> possible_homes ;  //building type that will be considered as home	
	map<string, list<string>> activities; //list of activities, and for each activity type, the list of possible building type
	
	map<int,map<string,list<string>>> map_epidemiological_parameters;
	action global_init {
		
		do console_output("global init");
		do init_building_type_parameters;
		
		if (shp_boundary != nil) { create Boundary from: shp_boundary; }
		do create_buildings();
		
		loop aBuilding_Type over: Building collect(each.type)
		{
			add 0 at: aBuilding_Type to: building_infections;
		}
		//THIS SHOULD BE REMOVED ONCE WE FINALLY HAVE HOSPITAL IN SHAPEFILE
		add 0 at: "Hospital" to: building_infections;
		add 0 at: "Outside" to: building_infections;
		do console_output("building and boundary : done");
		
		create outside;
		the_outside <- first(outside);
		do create_activities;
		do create_hospital;
		do console_output("Activities and special buildings (hospitals and outside) : done");
		
		list<Building> homes <- Building where (each.type in possible_homes);	
		map<string,list<Building>> buildings_per_activity <- Building group_by (each.type);
		map<Building,float> working_places <- gather_available_workplaces(buildings_per_activity);
		map<list<int>,list<Building>> schools <- gather_available_schoolplaces(buildings_per_activity);
		int min_student_age <- min(schools.keys accumulate (each));
		int max_student_age <- max(schools.keys accumulate (each));
		do console_output("Finding homes, workplaces and schools : done");
				
		do console_output("Start creating and locating population from "+(csv_population!=nil?"file":"built-in generator"));	
		float t <- machine_time;
		if(csv_population != nil) {
			do create_population_from_file(homes, min_student_age, max_student_age);
		} else {
			do create_population(working_places, schools, homes, min_student_age, max_student_age);
		}
		do console_output("-- achieved in "+(machine_time-t)/1000+"s");
		
		do console_output("Start init epidemiological state of people");
		t <- machine_time;
		ask all_individuals { do initialise_epidemio; }
		do console_output("-- achieved in "+(machine_time-t)/1000+"s");
		
		do console_output("Start assigning school and workplaces");
		t <- machine_time;
		do assign_school_working_place(working_places,schools, min_student_age, max_student_age);
		do console_output("-- achieved in "+(machine_time-t)/1000+"s");
		
		do console_output("Start building friendship network");
		t <- machine_time;
		do create_social_networks(min_student_age, max_student_age);
		do console_output("-- achieved in "+(machine_time-t)/1000+"s");
		
		do console_output("Start defining agendas");
		t <- machine_time;
		do define_agenda(min_student_age, max_student_age);
		do console_output("-- achieved in "+(machine_time-t)/1000+"s");
		do console_output("Population of "+length(all_individuals)+" individuals");

		do console_output("Introduce "+num_infected_init+" infected cases");
		ask num_infected_init among all_individuals {
			do define_new_case;
		}
		
		total_number_individual <- length(all_individuals);

	}


	action init_building_type_parameters {
		csv_parameters <- csv_file(building_type_per_activity_parameters,",",true);
		matrix data <- matrix(csv_parameters);
		// Modifiers can be weights, age range, or anything else
		list<string> available_modifiers <- [WEIGHT,RANGE];
		map<string,string> activity_modifiers;
		//Loading the different rows number for the parameters in the file
		loop i from: 0 to: data.rows-1{
			string activity_type <- data[0,i];
			bool modifier <- available_modifiers contains activity_type;
			list<string> bd_type;
			loop j from: 1 to: data.columns - 1 {
				if (data[j,i] != nil) {	 
					if modifier {
						activity_modifiers[data[j,i-1]] <- data[j,i]; 
					} else {
						if data[j,i] != nil or data[j,i] != "" {bd_type << data[j,i];}
					}
				}
			}
			if not(modifier) { activities[activity_type] <- bd_type; }
		}
		
		if activities contains_key act_studying {
			loop acts over:activities[act_studying] where not(possible_schools contains_key each) {
				pair age_range <- activity_modifiers contains_key acts ? 
					pair(split_with(activity_modifiers[acts],SPLIT)) : pair(school_age::active_age); 
				possible_schools[acts] <- [int(age_range.key),int(age_range.value)];
			}
			remove key: act_studying from:activities;
		}
		
		if activities contains_key act_working {
			loop actw over:activities[act_working] where not(possible_workplaces contains_key each) { 
				possible_workplaces[actw] <- activity_modifiers contains_key actw ? 
					float(activity_modifiers[actw]) : 1.0;
			}
			remove key: act_working from:activities;
		}
		
		if activities contains_key act_home {
			possible_homes<- activities[act_home];
			remove key: act_home from:activities;
		}
	}
	
	// Creating the buildings from a file (should be overloaded to add more attributes to buildings)
	action create_buildings {
		if (shp_buildings != nil) { 
			create Building from: shp_buildings with: [type::string(read(type_shp_attribute)), nb_households::max(1,int(read(flat_shp_attribute)))];
		}
		else {error "The mandatory shapefile of buildings is missing !";}
	}
		
	// gather all workplaces with the area
	map<Building,float> gather_available_workplaces(map<string,list<Building>> blds_per_activity) {
		map<Building,float> working_places <- [];
		loop wp over: possible_workplaces.keys {
			if (wp in blds_per_activity.keys) {
					working_places <- working_places +  (blds_per_activity[wp] as_map (each:: (each.shape.area * possible_workplaces[wp])));  
			}
		}
		return working_places;
	}
	
	// gather all schoolplaces according to student age range
	map<list<int>,list<Building>> gather_available_schoolplaces(map<string,list<Building>> blds_per_activity) {
		int min_student_age <- retirement_age;
		int max_student_age <- 0;
		map<list<int>,list<Building>> schools;
		loop t over: possible_schools.keys {
			max_student_age <- max(max_student_age, max(possible_schools[t]));
			min_student_age <- min(min_student_age, min(possible_schools[t]));
			if schools contains_key possible_schools[t] { schools[possible_schools[t]] <<+ blds_per_activity[t]; } 
			else { schools[possible_schools[t]] <- blds_per_activity[t]; }
		}
		return schools;
	}
	
	//Action used to initialise epidemiological parameters according to the file and parameters forced by the user
	action init_epidemiological_parameters
	{
		
		//In the case no file was provided, then we simply create the matrix from the default parameters, that are not age dependent
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
			add list(init_all_ages_distribution_type_incubation_period_symptomatic,string(init_all_ages_parameter_1_incubation_period_symptomatic),string(init_all_ages_parameter_2_incubation_period_symptomatic)) to: tmp_map at: epidemiological_incubation_period_symptomatic;
			add list(init_all_ages_distribution_type_incubation_period_asymptomatic,string(init_all_ages_parameter_1_incubation_period_asymptomatic),string(init_all_ages_parameter_2_incubation_period_asymptomatic)) to: tmp_map at: epidemiological_incubation_period_asymptomatic;
			add list(init_all_ages_distribution_type_serial_interval,string(init_all_ages_parameter_1_serial_interval),string(init_all_ages_parameter_2_serial_interval)) to: tmp_map at: epidemiological_serial_interval;
			add list(epidemiological_fixed,string(init_all_ages_proportion_hospitalisation)) to: tmp_map at: epidemiological_proportion_hospitalisation;
			add list(epidemiological_fixed,string(init_all_ages_proportion_icu)) to: tmp_map at: epidemiological_proportion_icu;
			add list(init_all_ages_distribution_type_infectious_period_symptomatic,string(init_all_ages_parameter_1_infectious_period_symptomatic),string(init_all_ages_parameter_2_infectious_period_symptomatic)) to: tmp_map at: epidemiological_infectious_period_symptomatic;
			add list(init_all_ages_distribution_type_infectious_period_asymptomatic,string(init_all_ages_parameter_1_infectious_period_asymptomatic),string(init_all_ages_parameter_2_infectious_period_asymptomatic)) to: tmp_map at: epidemiological_infectious_period_asymptomatic;
			add list(init_all_ages_distribution_type_onset_to_hospitalisation,string(init_all_ages_parameter_1_onset_to_hospitalisation),string(init_all_ages_parameter_2_onset_to_hospitalisation)) to: tmp_map at: epidemiological_onset_to_hospitalisation;
			add list(init_all_ages_distribution_type_hospitalisation_to_ICU,string(init_all_ages_parameter_1_hospitalisation_to_ICU),string(init_all_ages_parameter_2_hospitalisation_to_ICU)) to: tmp_map at: epidemiological_hospitalisation_to_ICU;
			add list(init_all_ages_distribution_type_stay_ICU,string(init_all_ages_parameter_1_stay_ICU),string(init_all_ages_parameter_2_stay_ICU)) to: tmp_map at: epidemiological_stay_ICU;
			add list(init_all_ages_distribution_viral_individual_factor,string(init_all_ages_parameter_1_viral_individual_factor),string(init_all_ages_parameter_2_viral_individual_factor)) to: tmp_map at: epidemiological_viral_individual_factor;
			add tmp_map to: map_epidemiological_parameters at: aYear;
		}
		
		//If there are any file given as an epidemiological parameters, then we get the parameters value from it
		if(load_epidemiological_parameter_from_file and file_exists(epidemiological_parameters))
		{
			csv_parameters <- csv_file(epidemiological_parameters,true);
			matrix data <- matrix(csv_parameters);
			map<string, list<int>> map_parameters;
			//Loading the different rows number for the parameters in the file
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
			//Initalising the matrix of age dependent parameters and other non-age dependent parameters
			loop aKey over: map_parameters.keys {
				switch aKey{
					//Four parameters are not age dependent : allowing human to human transmission, allowing environmental contamination, 
					//and the parameters for environmental contamination
					match epidemiological_transmission_human{
						if(force_parameters contains(epidemiological_transmission_human))=false{
							allow_transmission_human <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?
							bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_transmission_human;
						}
					}
					match epidemiological_allow_viral_individual_factor{
						if(force_parameters contains(epidemiological_allow_viral_individual_factor))=false{
							allow_viral_individual_factor <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?
							bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_viral_individual_factor;
						}
					}
					match epidemiological_transmission_building{
						if(force_parameters contains(epidemiological_transmission_building))=false{
							allow_transmission_building <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?
							bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_transmission_building;
						}
					}
					match epidemiological_basic_viral_decrease{
						if(force_parameters contains(epidemiological_basic_viral_decrease))=false{
							basic_viral_decrease <- float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):basic_viral_decrease;
						}
					}
					match epidemiological_successful_contact_rate_building{
						if(force_parameters contains(epidemiological_successful_contact_rate_building))=false{
							successful_contact_rate_building <- float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):successful_contact_rate_building;
						}
					}
					//all the other parameters could be defined as age dependent, and therefore, stocked in the matrix of parameters
					default{
						loop i from: 0 to:length(map_parameters[aKey])-1
						{
							int index_column <- map_parameters[aKey][i];
							list<string> tmp_list <- list(string(data[epidemiological_csv_column_detail,index_column]),string(data[epidemiological_csv_column_parameter_one,index_column]),string(data[epidemiological_csv_column_parameter_two,index_column]));
							
							//If the parameter was provided only once in the file, then the value will be used for all ages, 
							// else, different values would be loaded according to the age categories given, hence the age dependent matrix
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
		
		//In the case the user wanted to load parameters from the file, but change the value of some of them for an experiment, 
		// the force_parameters list should contain the key for the parameter, so that the value given will replace the one already
		// defined in the matrix
		loop aParameter over: force_parameters
		{
			list<string> list_value;
			switch aParameter
			{
				match epidemiological_transmission_human{
					allow_transmission_human <- allow_transmission_human;
				}
				match epidemiological_allow_viral_individual_factor{
					allow_viral_individual_factor <- allow_viral_individual_factor;
				}
				match epidemiological_transmission_building{
					allow_transmission_building <- allow_transmission_building;
				}
				match epidemiological_basic_viral_decrease{
					basic_viral_decrease <- basic_viral_decrease;
				}
				match epidemiological_successful_contact_rate_building{
					successful_contact_rate_building <- successful_contact_rate_building;
				}
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
				match epidemiological_incubation_period_symptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_incubation_period_symptomatic,string(init_all_ages_parameter_1_incubation_period_symptomatic),string(init_all_ages_parameter_2_incubation_period_symptomatic));
				}
				match epidemiological_incubation_period_asymptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_incubation_period_asymptomatic,string(init_all_ages_parameter_1_incubation_period_asymptomatic),string(init_all_ages_parameter_2_incubation_period_asymptomatic));
				}
				match epidemiological_serial_interval{
					list_value <- list<string>(init_all_ages_distribution_type_serial_interval,string(init_all_ages_parameter_1_serial_interval));
				}
				match epidemiological_infectious_period_symptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_infectious_period_symptomatic,string(init_all_ages_parameter_1_infectious_period_symptomatic),string(init_all_ages_parameter_2_infectious_period_symptomatic));
				}
				match epidemiological_infectious_period_asymptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_infectious_period_asymptomatic,string(init_all_ages_parameter_1_infectious_period_asymptomatic),string(init_all_ages_parameter_2_infectious_period_asymptomatic));
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
	
	// ------------- //
	// EMPTY METHODS // 
	
	/*
	 * Add actions to be triggered before COMOKIT initializes
	 */
	action before_init {}
	
	/*
	 * Add actions after COMOKIT have been initialized but before starting simulation
	 */
	action after_init {}
	
	// ----- //
	// DEBUG //
	// ----- //
	
	// Global debug mode to print in console all messages called from #console_output()
	bool DEBUG <- false;
	list<string> levelList const:true <- ["trace","debug","warning","error"]; 
	// the available level of debug among debug, error and warning (default = debug)
	string LEVEL init:"debug" among:["trace","debug","warning","error"];
	// Simple print_out method
	action console_output(string output, string caller <- "Global.gaml", string level <- LEVEL) { 
		if DEBUG {
			string msg <- "["+caller+"] "+output;
			if levelList index_of LEVEL <= levelList index_of level {
				switch level {
					match "error" {error msg;}
					match "warning" {warn msg;}
					default {write msg;}
				}	
			}
		}
	}
	
	// --------- //
	// BENCHMARK //
	// --------- //
	
	bool BENCHMARK <- false;
	
	map<string,float> bench <- [
		"Abstract Batch Experiment.observerPattern"::0.0,
		"Authority.apply_policy"::0.0,
		"Authority.init_stats"::0.0,
		"Biological Entity.infect_others"::0.0,
		"Biological Entity.update_time_before_death"::0.0,
		"Biological Entity.update_time_in_ICU"::0.0,
		"Building.update_viral_load"::0.0,
		"Individual.become_infected_outside"::0.0,
		"Individual.infect_others"::0.0,
		"Individual.execute_agenda"::0.0,
		"Individual.update_epidemiology"::0.0,
		"Individual.add_to_dead"::0.0,
		"Individual.add_to_hospitalised"::0.0,
		"Individual.add_to_ICU"::0.0
	];

}