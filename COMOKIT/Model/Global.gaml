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
		ask num_infected_init among all_individuals { do define_new_case(original_strain); }
		
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
	
	/*
	 * Initialization of global epidemiological mechanism in the model, such as environmental contamination, allow individual viral load or not, proportion of agent wearing mask, etc.
	 */
	action init_epidemiological_parameters {
		if(load_epidemiological_parameter_from_file and file_exists(sars_cov_2_parameters)) {
			csv_parameters <- csv_file(sars_cov_2_parameters,true);
			matrix data <- matrix(csv_parameters);
			
			
			// TODO  : init from the old file
			
			loop aParam over:forced_epidemiological_parameters  {
				switch aParam {
					match epidemiological_transmission_human { init_selfstrain_reinfection_probability <- init_selfstrain_reinfection_probability; }
					match epidemiological_allow_viral_individual_factor{ allow_viral_individual_factor <- allow_viral_individual_factor; }
					match epidemiological_transmission_building{ allow_transmission_building <- allow_transmission_building;   }
					match epidemiological_basic_viral_decrease { basic_viral_decrease <- basic_viral_decrease; }
					match epidemiological_basic_viral_release{  basic_viral_release  <- basic_viral_release; }
					match epidemiological_successful_contact_rate_building{ successful_contact_rate_building <- successful_contact_rate_building; }
					match proportion_antivax { init_all_ages_proportion_antivax <-  init_all_ages_proportion_antivax; }
					match epidemiological_proportion_wearing_mask{ init_all_ages_proportion_wearing_mask <- init_all_ages_proportion_wearing_mask; }
					match epidemiological_factor_wearing_mask{ init_all_ages_factor_contact_rate_wearing_mask <- init_all_ages_factor_contact_rate_wearing_mask; }
				}
			} 
		}
	}
	
	/*
	 * Initialize SARS-CoV-2 and variants from files, force parameters and/or default parameters
	 * TODO : test it - damne it's so complicated -  and is clearly not flexible enough for Individual and Biological Entity (they do not have sex)
	 */
	action init_sars_cov_2  {
		
		map<list<int>,map<string,list<string>>> virus_epidemiological_default_profile <- map([]);
		
		// build empty individual entries
		list<list<int>> epi_keys <- [];
		loop a from:0  to:max_age  { loop s over:[0,1] { loop c over:comorbidities_range { epi_keys <+ [a,s,c]; } }  }
		
		//build the empty virus profile
		
		// If there is a parameter file
		if(load_epidemiological_parameter_from_file and file_exists(sars_cov_2_parameters)){
			
			csv_file epi_params <- csv_file(sars_cov_2_parameters); 
			matrix data <- matrix(epi_params);
			
			// FOUND HEADERS
			map<string,int> read_entry_idx;
			loop h from:1 to:data.columns-epidemiological_csv_params_number-1 { 
				switch  data[0,h] { match AGE {read_entry_idx[AGE] <- h;} match SEX {read_entry_idx[SEX] <- h;}  match COMORBIDITIES {read_entry_idx[COMORBIDITIES] <- h;} }
			}
			
			// FIRST ROUND TO FOUND USE ENTRIES
			map<string,list<pair<map<string,int>,list<string>>>> var_to_user_entries_and_params  <- [];
			list<int> params_idx;
			loop pi from:1 to:epidemiological_csv_params_number { params_idx <+ data.columns - pi; }
			
			loop i from:  1 to:data.rows-1 {
				string var <- data[i,epidemiological_csv_column_name];
				
				map<string,int> entry <- [];
				loop e over:read_entry_idx.keys {
					string v <-  data[i,read_entry_idx[e]];
					if v != nil and v != "" and not(empty(v)) { entry[e] <- int(v); }
				}
				
				list<string> params;
				loop pi over:params_idx { params <+ data[i,pi]; }
				
				var_to_user_entries_and_params[var] <+ pair<map<string,int>,list<string>>(entry,params);
			}
			
			// SECOND ROUND TO FIT FULL DISTRIBUTION WITH USER ENTRIES
			loop k over:epi_keys {
				virus_epidemiological_default_profile[k] <- [];
				loop v over:var_to_user_entries_and_params.keys {
					list<string> matching_params;
					
					list<pair<map<string,int>,list<string>>> potential_match <- var_to_user_entries_and_params[v];
					if length(potential_match) = 1 {
						matching_params <- first(potential_match).value;
					}  else {
						if (read_entry_idx contains_key AGE) and (potential_match all_match (each.key contains_key AGE)) {
							list<int> age_range <- potential_match collect (each.key[AGE]) sort (each);
							int a_match  <- age_range first_with  (each > k[epidemiological_age_entry]);
							potential_match <- potential_match where (each.key[AGE]=a_match);
						}
						if (read_entry_idx contains_key SEX) and (potential_match all_match (each.key contains_key SEX)) {
							potential_match <- potential_match where (each.key[SEX]=k[epidemiological_gender_entry]);
						}
						if read_entry_idx contains_key COMORBIDITIES and (potential_match all_match (each.key contains_key COMORBIDITIES)) {
							potential_match <- potential_match where (each.key[COMORBIDITIES]=k[epidemiological_csv_params_number]);
						}
						if length(potential_match) != 1 {error "Found more than one potential match for epidemiological parameter distribution entry "+k;}
						matching_params <- first(potential_match).value;
					}
					
					virus_epidemiological_default_profile[k][v] <- matching_params;
				}
				
			}
			

		}
		// There is no parameter file
		else {
			 forced_sars_cov_2_parameters <-  SARS_COV_2_EPI_PARAMETERS + SARS_COV_2_EPI_FLIP_PARAMETERS;
		}
		
		
		map<string,list<string>> default_vals;
		
		//In the case the user wanted to load parameters from the file, but change the value of some of them for an experiment, 
		// the force_parameters list should contain the key for the parameter, so that the value given will replace the one already
		// defined in the matrix
		loop aParameter over: SARS_COV_2_PARAMETERS  {
			list<string> params;
			switch aParameter {	
				// Fixe values
				match epidemiological_successful_contact_rate_human{ params <- [epidemiological_fixed,init_all_ages_successful_contact_rate_human]; }
				match epidemiological_factor_asymptomatic{ params <- [epidemiological_fixed,init_all_ages_factor_contact_rate_asymptomatic]; }
				match epidemiological_proportion_asymptomatic{ params <- [epidemiological_fixed,init_all_ages_proportion_asymptomatic]; }
				match epidemiological_proportion_death_symptomatic{ params <- [epidemiological_fixed,init_all_ages_proportion_dead_symptomatic];}
				match epidemiological_probability_true_positive{ params <- [epidemiological_fixed,init_all_ages_probability_true_positive]; }
				match epidemiological_probability_true_negative{ params <- [epidemiological_fixed,init_all_ages_probability_true_negative]; }
				match epidemiological_immune_evasion { params <- [epidemiological_fixed, init_immune_escapement]; }
				
				match epidemiological_incubation_period_symptomatic{ params <- 
					[init_all_ages_distribution_type_incubation_period_symptomatic, string(init_all_ages_parameter_1_incubation_period_symptomatic),string(init_all_ages_parameter_2_incubation_period_symptomatic)]; 
				}
				match epidemiological_incubation_period_asymptomatic{params <- 
					[init_all_ages_distribution_type_incubation_period_asymptomatic,string(init_all_ages_parameter_1_incubation_period_asymptomatic),string(init_all_ages_parameter_2_incubation_period_asymptomatic)]; 
				}
				match epidemiological_serial_interval{params <- [init_all_ages_distribution_type_serial_interval,string(init_all_ages_parameter_1_serial_interval),string(init_all_ages_parameter_2_serial_interval)]; }
				match epidemiological_infectious_period_symptomatic{ params <-
					[init_all_ages_distribution_type_infectious_period_symptomatic,string(init_all_ages_parameter_1_infectious_period_symptomatic),string(init_all_ages_parameter_2_infectious_period_symptomatic)];
				}
				match epidemiological_infectious_period_asymptomatic{ params <- 
					[init_all_ages_distribution_type_infectious_period_asymptomatic,string(init_all_ages_parameter_1_infectious_period_asymptomatic),string(init_all_ages_parameter_2_infectious_period_asymptomatic)];
				}
				match epidemiological_proportion_hospitalisation{ params <- [epidemiological_fixed,init_all_ages_proportion_hospitalisation]; }
				match epidemiological_onset_to_hospitalisation{ params <- 
					[init_all_ages_distribution_type_onset_to_hospitalisation,string(init_all_ages_parameter_1_onset_to_hospitalisation),string(init_all_ages_parameter_2_onset_to_hospitalisation)];
				}
				match epidemiological_proportion_icu{ params  <- [epidemiological_fixed,init_all_ages_proportion_icu]; }
				match epidemiological_hospitalisation_to_ICU{ params <- 
					[init_all_ages_distribution_type_hospitalisation_to_ICU,string(init_all_ages_parameter_1_hospitalisation_to_ICU),string(init_all_ages_parameter_2_hospitalisation_to_ICU)];
				}
				match epidemiological_stay_ICU{ params  <- [init_all_ages_distribution_type_stay_ICU,string(init_all_ages_parameter_1_stay_ICU),string(init_all_ages_parameter_2_stay_ICU)];}
				default{ /*There is no sens to have a default value for all parameters, or may be 42 */}
				default_vals[aParameter] <- params;
				if forced_sars_cov_2_parameters  contains aParameter { loop e over:epi_keys  { virus_epidemiological_default_profile[e][aParameter] <- params;} }
			}
		}
		
		// In any case, we should have a default value in the distribution of epidemiological attributes, that gives a value whatever epidemiological entry is
		virus_epidemiological_default_profile[epidemiological_default_entry] <-  default_vals;
		
		// ----------------------------
		//  CREATION OF SARS-CoV-2
		create sarscov2 with:[source_of_mutation::nil,name::SARS_CoV_2,epidemiological_distribution::virus_epidemiological_default_profile] returns: original_sars_cov_2;
		original_strain <- first(original_sars_cov_2);
		
		// Creation of variant
		if folder_exists(variants_folder) and not(empty(folder(variants_folder))) {
			// TODO : loop over files to init variants, based on name and var.
		} else { do init_variants; } 
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