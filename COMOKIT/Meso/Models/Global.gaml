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

import "../../Core/Models/Entities/Authority.gaml"

import "Parameters.gaml" 


import "Entities/Activity.gaml"

import "Entities/Building.gaml"
import "Entities/Individual.gaml" 
import "Entities/Hospital.gaml"
import "Entities/Activity.gaml"
import "Entities/Boundary.gaml"
import "Entities/Activity.gaml"
import "Synthetic Population.gaml"
 
global {
	
		/** 
	 * Individuals access
	 */
	 //geometry shape <-envelope(shape_file(shp_boundary_path)); 
	species<Individual> individual_species;// <- Individual; // by default
	//map<string,string> state_individuals;
	list agents_history; 
	list<int> all_individuals_id;
	
	list<Building> all_buildings;
	geometry shape <- envelope(file_exists(shp_boundary_path) ?shape_file(shp_boundary_path) : shape_file(shp_buildings_path) );
	Outside the_outside;
	
	

	list<AbstractIndividual> individuals_precomputation;
	list<int> individuals_tested; 
	list<int> individuals_dead;
	map<string, Building> all_buildings_map;
	
	int current_week <- starting_date.week_of_year mod nb_weeks_ref update: current_date.week_of_year mod nb_weeks_ref;
	
	bool politic_is_active <- false;
	Abstract_individual_precomputation bot_abstract_individual_precomputation;
	float t_ref <- machine_time;
	float t_ref2 <- machine_time;
	
	action define_individual_species {
		individual_species <- Individual;
	}
	
	action global_init {
		do console_output("global init");
		do define_individual_species;
		create Outside;
		the_outside <- first(Outside);
		do init_building_type_parameters;
			
		if not use_activity_precomputation {
			if (file_exists(shp_boundary_path) != nil) { create Boundary from: shape_file(shp_boundary_path); }
		
			do create_buildings();
			list<string> all_building_functions <- remove_duplicates(Building accumulate(each.functions)); 
			loop aBuilding_Type over: all_building_functions
			{
				add 0 at: aBuilding_Type to: building_infections;
			} 	
		} else {
			all_buildings_map[to_bd_id(the_outside)] <- the_outside;
		}
		
		//THIS SHOULD BE REMOVED ONCE WE FINALLY HAVE HOSPITAL IN SHAPEFILE
		add 0 at: "Hospital" to: building_infections;
		add 0 at: "Outside" to: building_infections;
		do console_output("building and boundary : done");
		
		do create_activities;
		do create_hospital;
		if not use_activity_precomputation {
			all_buildings <- list<Building>(Building.population+(Building.subspecies accumulate each.population));
			do console_output("Activities and special buildings (hospitals and outside) : done");
			do console_output("Start creating and locating population from "+(file_exists(csv_population_path)?"file":"built-in generator"));	
			float t <- machine_time;
		
			//do load_population_and_agenda_from_file();
			//ask individuals  { do initialise_epidemiological_behavior(); }
			map<string,list<Building>> buildings_per_activity <- map<string,list<Building>> (build_buildings_per_function());
			list<Building> homes <- remove_duplicates(possible_homes accumulate buildings_per_activity[each]);	
			homes >> nil;
			map<Building,float> working_places <- gather_available_workplaces(buildings_per_activity);
			map<list<int>,list<Building>> schools <- gather_available_schoolplaces(buildings_per_activity);
			int min_student_age <- min(schools.keys accumulate (each));
			int max_student_age <- max(schools.keys accumulate (each));
			do console_output("Finding homes, workplaces and schools : done");
			
			if(file_exists(csv_population_path) ) {
				do create_population_from_file(homes, min_student_age, max_student_age);
			} else {
				do create_population(working_places, schools, homes, min_student_age, max_student_age);
			}
			all_individuals <- agents of_generic_species Individual;
			write sample(length(Individual));
			write sample(length(all_individuals));
			
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

            do console_output("Give people an epidemic behavior");
            t <- machine_time;
            ask all_individuals  { do initialise_epidemiological_behavior();}
            do console_output("-- "+with_precision(all_individuals count (each.is_wearing_mask) * 1.0 / length(all_individuals),2)+"% wearing a mask  | "
                +with_precision(mean(all_individuals collect (each.vax_willingness)),2)+" average vax hesitancy");
            do console_output("-- achieved in "+(machine_time-t)/1000+"s");
            
			total_number_individual <- length(all_individuals);

			do console_output("Population of "+total_number_individual+" individuals");		
		} else {
			//use to test immunity
			create Abstract_individual_precomputation {
				bot_abstract_individual_precomputation <- self;
			}
			//optimized COMOKIT - just get the list of possible agents
			all_individuals_id <- list<string>(folder(dataset_path + precomputation_folder + file_agenda_precomputation_path).contents) collect int(each replace (".data",""));
			total_number_individual <- length(all_individuals_id);
			loop times: total_number_individual {
				individuals_precomputation << nil;
				agents_history<<nil;
			}
			ask Outside {
				is_active <- not empty(proba_outside_contamination_per_hour) and (sum(proba_outside_contamination_per_hour.values) > 0.0);
			}
		}
		do console_output("Population of "+total_number_individual+" individuals");	
		do init_covid_cases();
		do console_output("Introduce "+all_individuals count (each.is_infected)+" infected cases");
	}
	
	
	action create_authority {
		create Authority;
		do define_policy;
		if (use_activity_precomputation) {
			ask Authority {
				ask policy {
					do apply;
					politic_is_active <- is_active();
				}
			}
		}
		
		ask world { do console_output("Create authority: "+Authority[0].name, caller::"Authority.gaml");}
	}
	reflex clean_memory_info when: every(1#week) {
		ask experiment{
			do compact_memory;
		}
		//write "Number of individuals: " + length(all_individuals) +" Number of buildings: " + length(all_buildings_map);
	}
	
	
	bool firsts <- true;
	reflex e when: firsts {
		t_ref2 <- machine_time;
		firsts <- false;
	}
	
	reflex end when:  cycle > 24 and (use_activity_precomputation ? empty(all_individuals): ((all_individuals count (each.is_susceptible or (each.state = removed))) = length(all_individuals))) {
		write "nb cycle: " + cycle;
		write "time tot: " + (machine_time - t_ref);
		write "time cycle: " + (machine_time - t_ref2) / cycle;
		do pause;
		
	}
	action init_building_type_parameters {
		file csv_parameters <- csv_file(building_type_per_activity_parameters,",",true);
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
		if (file_exists(shp_buildings_path) != nil) { 
			create Building from: shape_file(shp_buildings_path) with: [fcts::string(read(type_shp_attribute)), nb_households::max(1,int(read(flat_shp_attribute)))] ;
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
		do console_output("Init epidemiological global parameters ---");
		if(load_epidemiological_parameter_from_file and file_exists(epidemiological_parameters)) {
			float t <- machine_time;
			// Read the file data
			file csv_parameters <- csv_file(epidemiological_parameters,true);
			matrix data <- matrix(csv_parameters);
			
			// found header schem
			int detail_idx <- data.columns - epidemiological_csv_params_number;
			int val_idx <- detail_idx+1;
			
			map<string,int> read_entry_idx;
			loop h from:1 to:data.columns-epidemiological_csv_params_number-1 { 
				switch  data[0,h] { match AGE {read_entry_idx[AGE] <- h;} match SEX {read_entry_idx[SEX] <- h;}  match COMORBIDITIES {read_entry_idx[COMORBIDITIES] <- h;} }
			}
			
			if not(empty(read_entry_idx)) {error "Global epidemiological parameters dependant over "+read_entry_idx.keys
				+" are not yet supported, please consider raising an issue if feature required - https://github.com/COMOKIT/COMOKIT-Model/issues";
			}
			
			loop l from:1 to:data.rows-1 {
				
				string param <- data[l,epidemiological_csv_column_name];
				
				if not(forced_epidemiological_parameters contains param) {
					
					string detail  <- data[l,detail_idx];
					float val <- detail=epidemiological_fixed ?  float(data[l,val_idx]) : world.get_rnd_from_distribution(detail, float(data[l,val_idx]),float(data[l,val_idx+1]));
					
					switch param {
						match epidemiological_transmission_human { init_selfstrain_reinfection_probability <- val; }
						match epidemiological_allow_viral_individual_factor{ allow_viral_individual_factor <- bool(data[l,val_idx]); }
						match epidemiological_transmission_building{ allow_transmission_building <- bool(data[l,val_idx]); }
						match epidemiological_basic_viral_decrease { basic_viral_decrease <- val; }
						match epidemiological_basic_viral_release{  basic_viral_release  <- val; }
						match epidemiological_successful_contact_rate_building{ successful_contact_rate_building <- val; }
						match proportion_antivax { init_all_ages_proportion_antivax <-  val; }
						match epidemiological_proportion_wearing_mask{ init_all_ages_proportion_wearing_mask <- val; }
						match epidemiological_factor_wearing_mask{ init_all_ages_factor_contact_rate_wearing_mask <- val; }
					}
				}
				
			}
			do console_output("\t process parameter files in "+with_precision((machine_time-t)/1000,2)+"s");
		}
	}
	
	/*
	 * Initialize SARS-CoV-2 and variants from files, force parameters and/or default parameters
	 * TODO : test it - damne it's so complicated -  and is clearly not flexible enough for Individual and Biological Entity (they do not have sex)
	 */
	action init_sars_cov_2  {
		do console_output("Init sars-cov-2 and variants ---");
		float t <- machine_time;
		
		csv_file epi_params <- load_epidemiological_parameter_from_file and file_exists(sars_cov_2_parameters) ? csv_file(sars_cov_2_parameters,false) : nil;
		map<map<string,int>,map<string,list<string>>> virus_epidemiological_default_profile <- init_sarscov2_epidemiological_profile(epi_params);
		
		// ----------------------------
		//  CREATION OF SARS-CoV-2
		create sarscov2 with:[source_of_mutation::nil,name::SARS_CoV_2,epidemiological_distribution::virus_epidemiological_default_profile] returns: original_sars_cov_2;
		original_strain <- first(original_sars_cov_2);
		do console_output("\t----"+sample(first(original_sars_cov_2).get_epi_id()));
		do console_output("\tSars-CoV-2 original strain created ("+with_precision((machine_time-t)/1000,2)+"s)");
		t <- machine_time;
		
		// Creation of variant
		if folder_exists(variants_folder) and not(empty(folder(variants_folder))) {
			list<string> variant_files <- folder(variants_folder).contents;
			loop vf over:variant_files where (file_exists(each)) {
				map<map<string,int>,map<string,list<string>>> variant_profile <- init_sarscov2_epidemiological_profile(csv_file(vf,false));
				string variant_name <- first(last(vf split_with "/") split_with ".");
				create sarscov2 with:[source_of_mutation::original_strain,epidemiological_distribution::variant_profile] returns: variants;
				VOC <+  first(variants); // TODO should specify the source of mutation and type of variant (i.e. VOC or VOI)
			}
		} else { do init_variants; }
		
		do console_output("\tVariants created - VOC:"+VOC collect each.name+" - VOI:"+VOI collect each.name+" ("+with_precision((machine_time-t)/1000,2)+"s)");
	}
	
	/*
	 * Initialize an epidemiological profile: <p>
	 * <ul>
	 *  <i> key - AGE-SEXE-COMORBIDITIES
	 *  <i> value::key - epidemiological aspect
	 *  <i> value::value - type of distribution, param1, param2
	 * </ul>
	 * Can be used to init any variants - csv file should be loaded without header
	 */
	map<map<string,int>,map<string,list<string>>> init_sarscov2_epidemiological_profile(csv_file parameters <- nil) {
		map<map<string,int>,map<string,list<string>>> profile <- map([]);
		
		// If there is a parameter file
		if(parameters != nil){
			
			matrix data <- matrix(parameters);
			
			// FOUND HEADERS
			map<string,int> read_entry_idx;
			loop h from:1 to:data.columns-epidemiological_csv_params_number-1 { 
				switch lower_case(string(data[h,0])) { 
					match AGE {read_entry_idx[AGE] <- h;} 
					match SEX {read_entry_idx[SEX] <- h;}  
					match COMORBIDITIES {read_entry_idx[COMORBIDITIES] <- h;}
				}
			}
			
			// write sample(read_entry_idx);
			
			// FIRST ROUND TO FOUND USER ENTRIES
			map<string,list<pair<map<string,int>,list<string>>>> var_to_user_entries_and_params  <- [];
			list<int> params_idx;
			loop pi from:1 to:epidemiological_csv_params_number { params_idx <+ data.columns - pi; }
			params_idx <-  params_idx sort each;
			
			// Read each line of parameter file
			loop i from:  1 to:data.rows-1 {
				string var <- data[epidemiological_csv_column_name,i];
				
				// Record entries, i.e. age x sex x comorbidities
				map<string,int> entry <- [];
				loop e over:read_entry_idx.keys {
					string v <-  data[read_entry_idx[e],i];
					if v != nil and v != "" and not(empty(v)) { entry[e] <- int(v); }
				}
				
				// Record parameters, i.e. detail x  param 1 x param 2
				list<string> params;
				loop pi over:params_idx { params <+ data[pi,i]; }
				
				// write "Process (l"+i+") var "+var+" "+sample(entry)+" => "+params;
				
				if not(var_to_user_entries_and_params contains_key var) {var_to_user_entries_and_params[var] <- [];}
				var_to_user_entries_and_params[var] <+ entry::params;
			}
			
			// SECOND ROUND TO FIT REQUESTED DISTRIBUTION WITH USER ENTRIES
			loop v over:var_to_user_entries_and_params.keys {
				
				// For a given variable of the virus get all possible pair of entry :: parameter
				// i.e.  [AGE,SEX,COMORBIDITIES] x [detail,param1,param2]
				// the map key may be empty, or contains one or more of the 3 given dimensions
				list<pair<map<string,int>,list<string>>> matches <- var_to_user_entries_and_params[v];
				
				// If there is only one parameter line for this variable, then ignore all entry (i.e. no age, sex or comorbidities determinants)
				if length(matches) = 1 {
					if not(profile contains_key epidemiological_default_entry) { profile[epidemiological_default_entry] <- [];} 
					profile[epidemiological_default_entry][v] <- first(matches).value;
				}  else {
					//  Turn parameter file age range into fully explicit integer age
					map<int,list<int>>  age_entry_mapping <- [];
					if (read_entry_idx contains_key AGE) and (matches all_match (each.key contains_key AGE)) {
						list<int> age_range <- matches collect (each.key[AGE]) sort (each);
						if length(age_range)=1 and (first(age_range)=0 or first(age_range)=max_age) {}
						else {
							list<int> ages <- [];
							age_range >- first(ages);
							loop age  from:first(ages) to:max_age {
								if first(age_range) = age { 
									age_entry_mapping[first(ages)] <- ages; ages <- []; age_range >- age;
								}
								ages <+ age;
							}
							age_entry_mapping[first(ages)] <- ages;
						}
					}
					//  Adapt all entries to actual age
					loop em over:matches {
						map<string, int> current_entry <- copy(em.key);
						if empty(age_entry_mapping) { 
							current_entry[] >- AGE;
							if empty(current_entry) { current_entry <- epidemiological_default_entry;}
							if not(profile contains_key current_entry) {profile[current_entry]  <- [];}
							profile[current_entry][v] <- em.value;
						} else {
							loop actual_age over:age_entry_mapping[current_entry[AGE]] {
								map<string,int> actual_entry  <- copy(current_entry);
								actual_entry[AGE] <- actual_age;
								if not(profile contains_key actual_entry) { profile[actual_entry]  <- []; }
								profile[actual_entry][v] <- em.value;
							}
						}
					}	
				}
			}
		
			

		}
		// There is no parameter file
		else {
			 forced_sars_cov_2_parameters <-  SARS_COV_2_EPI_PARAMETERS + SARS_COV_2_EPI_FLIP_PARAMETERS;
		}
		
		map<string,list<string>> default_vals;
		//write "Init default and missing parameters - "+sample(SARS_COV_2_PARAMETERS);
		
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
				match epidemiological_reinfection_probability {  params <- [epidemiological_fixed, init_selfstrain_reinfection_probability];}
				
				match epidemiological_viral_individual_factor { params <- 
					[init_all_ages_distribution_viral_individual_factor,string(init_all_ages_parameter_1_viral_individual_factor),string(init_all_ages_parameter_2_viral_individual_factor)];
				}
				
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
				match epidemiological_stay_Hospital{ params  <- [init_all_ages_distribution_type_stay_Hospital,string(init_all_ages_parameter_1_stay_Hospital),string(init_all_ages_parameter_2_stay_Hospital)];}
				default{ /*There is no sens to have a default value for all parameters, or may be 42 */}
			}
				
			default_vals[aParameter] <- params;
			if forced_sars_cov_2_parameters contains aParameter { 
				loop k over:profile.keys {
					if profile[k] contains_key aParameter {
						profile[k][aParameter] <- params;
					}
				}
			}
		}
		
		// In any case, we should have a default value in the distribution of epidemiological attributes, that gives a value whatever epidemiological entry is
		if not(profile contains_key epidemiological_default_entry) { profile[epidemiological_default_entry] <-  default_vals; }
		else {
			loop p over:default_vals.keys - profile[epidemiological_default_entry].keys {  
				profile[epidemiological_default_entry][p] <-  default_vals[p]; 
			}
		}
		
		return profile;
	}
	
	
	reflex need_to_load when: use_activity_precomputation and (Authority[0].policy.is_active()  != politic_is_active){
		politic_is_active <- Authority[0].policy.is_active();
		if (file_activity_without_policy_precomputation_path != file_activity_with_policy_precomputation_path) {
				do update_precomputed_activity;		
		}
	}

	action update_precomputed_activity {
		ask all_buildings {
			entities_inside_int <- [];
			individuals_precomputation <- [];
			precomputation_loaded <- false;
		}
		write "update precomputation";
		
		ask  all_individuals {
			ask world {do update_individual(Individual(myself));}
		}
		
		if udpate_for_display {
			ask container<Building>(Building.population+(Building.subspecies accumulate each.population)) {
				nb_currents  <- empty(entities_inside) ? 0  :length(entities_inside[current_week][current_day][current_hour] accumulate each);		
			}
		}
		
	}
		 
	 /*
	  * Initialize vaccines based on given parameters (default or TODO parameter file)
	  */
	 action init_vaccines {
	 	do console_output("Init vaccines ----");
	 	float t <- machine_time;
	 	
	 	ARNm <+ create_covid19_vaccine(pfizer_biontech,length(pfizer_doses_immunity),pfizer_doses_schedule,pfizer_doses_immunity,
	 		pfizer_doses_sympto=nil?list_with(length(pfizer_doses_immunity),0.0):pfizer_doses_sympto,
	 		pfizer_doses_sever=nil?list_with(length(pfizer_doses_immunity),0.0):pfizer_doses_sever
	 	);
	 	Adeno <+ create_covid19_vaccine(astra_zeneca,length(pfizer_doses_immunity),astra_doses_schedule,astra_doses_immunity,
	 		astra_doses_sympto=nil?list_with(length(astra_doses_immunity),0.0):astra_doses_sympto,
	 		astra_doses_sever=nil?list_with(length(astra_doses_immunity),0.0):astra_doses_sever
	 	);
	 	vaccines <- ARNm + Adeno;
	 	
	 	do console_output("\tVaccines: "+vaccines collect (each.name)+" created ("+with_precision((machine_time-t)/1000,2)+"s)");
	 }
	 
	 /*
	  * Initialize sars-cov-2 infected agents at start
	  */
	 action init_covid_cases {
	 	if (use_activity_precomputation) {
	 		list<int> infected_individuals <- num_infected_init among all_individuals_id;
	 		loop id_id over: infected_individuals {
	 			do load_individual(id_id);
	 		}
	 		ask all_individuals {
	 			do define_new_case(original_strain);
	 		}
	 	} else {
	 		ask num_infected_init among all_individuals { do define_new_case(original_strain); }
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
	bool DEBUG <- true;
	bool SAVE_LOG <- false;
	string log_name <- "log.txt";
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
			if SAVE_LOG {save msg to:log_name rewrite: false format:text;}
		}
	}
	
	// --------- //
	// BENCHMARK //
	// --------- //
	
	bool BENCHMARK <- false;
	float p1;float p2;float p3;float p4;float p5;float p6;float p7;float p8;float p9;float p10;
	float p11;float p12;float p13;float p14;float p15;float p16;float p17;float p18;float p19;float p20;
	
	
	
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
	
	reflex benchmark_info when:BENCHMARK and every(10#cycle) {
		write bench;
	}
	
	
}