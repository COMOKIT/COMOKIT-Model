/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* The base of all experiments in COMOKIT. Provides a set of utilities
* (dataset path management, virtual displays, graphic constants, ...) 
* that can be reused, inherited or redefined in child experiments.
* Also see Abstract Experiment with Parameters.gaml and Abstract 
* Batch Experiment for more features in terms of parameterization 
* and exploration of simulations.
* 
* Author: Huynh Quang Nghi, Alexis Drogoul
* Tags: covid19,epidemiology
******************************************************************/
model CoVid19

import "../Model/Global.gaml"

global {

// Utils variable for the look and feel of simulation GUI
	font default <- font("Helvetica", 18, #bold) const: true;
	rgb text_color <- world.color.brighter.brighter const: true;
	rgb background <- world.color.darker.darker const: true;

	// Monitor the number of infectious individual
	int number_of_infectious <- 0 update: length(all_individuals where (each.is_infectious));

	/*
	 * Gloabl three steps initialization of a any simulation
	 */
	init {
		do before_init;
		do init_epidemiological_parameters;
		do global_init;
		do create_authority;
		do after_init;
	}

}


experiment "Abstract Experiment" virtual: true {

// ----------------------------------------------------- //
//				 DATASET PATH MANAGEMENT				 //
// ----------------------------------------------------- //


	string with_path_termination(string p) {
		return last(p) = "/" ? p : p+"/";
	}

/*
	 * build the data set folder from provided case_study and dataset_folder </br>
	 * Default value are dataset_folder = "Datasets" and case_study = "Vinh Phuc"
	 */
	string build_dataset_path (string _datasets_folder_path <- project_path + DEFAULT_DATASETS_FOLDER_NAME, string _case_study_folder_name <- DEFAULT_CASE_STUDY_FOLDER_NAME) {
		string dfp <- with_path_termination(_datasets_folder_path);
		string csfd <- with_path_termination(_case_study_folder_name);
		if not (folder_exists(dfp)) {
			error "Datasets folder does not exist : " + _datasets_folder_path;
		} else if not (folder_exists(dfp + csfd)) {
			error "Case study folder  does not exist : " + dfp + _case_study_folder_name;
		}
		return dfp + csfd;
	}

	/*
	 * Gather all the sub-folder of the given dataset_folder
	 */
	list<string> gather_dataset_names (string _datasets_folder_path <- project_path + DEFAULT_DATASETS_FOLDER_NAME) {
		string dfp <- with_path_termination(_datasets_folder_path);
		if not (folder_exists(dfp)) {
			error "Datasets folder does not exist : " + dfp;
		}
		list<string> dirs <- folder(dfp).contents;
		dirs <- dirs where folder_exists(dfp + each);
		return dirs;
	}

	/*
	 * Ask user to choose a dataset among available ones
	 */
	string ask_dataset_path (string _datasets_folder_path <- project_path + DEFAULT_DATASETS_FOLDER_NAME) {
		string dfp <- with_path_termination(_datasets_folder_path);
		list<string> dirs <- gather_dataset_names(dfp) - EXCLUDED_CASE_STUDY_FOLDERS_NAME;
		string question <- "Choose one dataset among : " + dirs;
		return dfp + "/" + user_input(question, [choose("Your choice", string, first(dirs), dirs)])["Your choice"] + "/";
	}

	// ----------------------------------------------------- //
	//				 MAIN DEFAULT DISPLAY					 //
	// ----------------------------------------------------- //
	output {
		display "default_display" synchronized: false type: opengl background: background virtual: true draw_env: false {
			overlay position: {5, 5} size: {700 #px, 200 #px} transparency: 1 {
				draw world.name font: default at: {20 #px, 20 #px} anchor: #top_left color: text_color;
				draw ("Day " + int((current_date - starting_date) / #day)) + " | " + ("Cases " + world.number_of_infectious) font: default at: {20 #px, 50 #px} anchor: #top_left color:
				text_color;
			}

			image file: file_exists(dataset_path + "/satellite.png") ? (dataset_path + "/satellite.png") : "../Utilities/white.png" transparency: 0.5 refresh: false;
			species Building {
				draw shape color: viral_load > 0 ? rgb(255 * viral_load, 0, 0) : #lightgrey empty: true width: 2;
			}

			agents "Individual" value: all_individuals where not (each.is_outside) {
				draw square(state = susceptible or clinical_status = recovered ? 10 : 20) color: state = latent ? #yellow : (self.is_infectious ? #orangered : (clinical_status = recovered ?
				#blue : #green));
			}

		}

		display "default_3D_display" synchronized: false type: opengl background: #black draw_env: false virtual: true {
			image file: file_exists(dataset_path + "/satellite.png") ? (dataset_path + "/satellite.png") : "../Utilities/white.png" transparency: 0.5 refresh: false;
			species Building transparency: 0.7 refresh: false {
				draw shape depth: rnd(50) color: #lightgrey empty: false width: 2;
			}

			agents "Other" value: all_individuals where (not each.is_outside and each.clinical_status = recovered or each.state = susceptible) transparency: 0.5 {
				draw sphere(30) color: (clinical_status = recovered ? #blue : #green) at: location - {0, 0, 30};
			}

			agents "Exposed" value: all_individuals where (not each.is_outside and each.clinical_status = latent) transparency: 0.5 {
				draw sphere(30) color: #yellow at: location - {0, 0, 30};
			}

			agents "Infectious" value: all_individuals where (not each.is_outside and each.is_infectious) transparency: 0.5 {
				draw sphere(50) color: #red at: location - {0, 0, 50};
			}

		}

		display "simple_display" parent: default_display synchronized: false type: opengl background: #black virtual: true draw_env: false {
			species Building {
				draw shape color: #lightgrey empty: true width: 2;
			}

			agents "Individual" value: all_individuals where not (each.is_outside) {
				draw square(self.is_infectious ? 30 : 10) color: state = latent ? #yellow : (self.is_infectious ? #orangered : (clinical_status = recovered ? #blue : #green));
			}

		}
		
		// OUTBREAK
		
		display "states_evolution_chart" virtual: true refresh: every(24#cycle) {
			chart "Population epidemiological states evolution" background: #white axes: #black color: #black title_font: default legend_font: font("Helvetica", 14, #bold) {
				data "Susceptible" value: length(all_individuals where (each.state = susceptible)) color: #green marker: false style: line;
				data "Latent" value: length(all_individuals where (each.is_latent())) color: #orange marker: false style: line;
				data "Infectious" value: length(all_individuals where (each.is_infectious)) color: #red marker: false style: line;
				data "Recovered" value: length(all_individuals where (each.clinical_status = recovered)) color: #blue marker: false style: line;
				data "Dead" value: length(all_individuals where (each.clinical_status = dead)) color: #black marker: false style: line;
			}

		}

		display "cumulative_incidence" virtual: true {
			chart "Cumulative incidence" background: #white axes: #black {
				data "cumulative incidence" value: total_number_of_infected color: #red marker: false style: line;
			}
		}
		
		display "secondary_infection_distribution" virtual:true {
			chart "Distribution of the number of people infected per individual" type: histogram {
				loop i over:[pair(0,0),pair(1,1),pair(2,4),pair(5,9),pair(10,24),
					pair(24,49),pair(50,99),pair(100,499),pair(500,10000)
				] {
					data i.key=i.value?string(i.key):string(i) 
						value: all_individuals count (each.number_of_infected_individuals>=int(i.key) and each.number_of_infected_individuals<=int(i.value));
				}
			}
		}
		
		// DEMOGRAPHICS
		
		display "demographics_age" virtual: true {
			chart "Ages" type: histogram {
				loop i from: 0 to: max_age { data ""+i value: all_individuals count(each.age = i); }
			}
		}
		
		display "demographics_sex" virtual: true {
			chart "sex" type: pie {
				data "Male" value: all_individuals count (each.sex=0);
				data "Female" value: all_individuals count (each.sex=1);
			}
		}
		
		display "demographics_employed" virtual: true {
			chart "unemployed" type: pie {
				data "Employed" value: all_individuals count not(each.is_unemployed);
				data "Unemployed" value: all_individuals count each.is_unemployed;
			}
		}
		
		display "demographics_household_size" virtual: true {
			chart "Household size" type:histogram {
				loop i from: 0 to:max(all_individuals collect (length(each.relatives))) { 
					data string(i) value: all_individuals count (length(each.relatives)=i);
				}
			}
		}	 

	}
	
	permanent {
		
		display "infected_cases" toolbar: false background: #black virtual: true refresh: every(24#cycle){
			chart "Infected cases" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
				loop s over: simulations {
					data s.name value: s.number_of_infectious color: s.color marker: false style: line thickness: 2; 		
				}
			}
		}
		
		display "cumulative_incidence" toolbar: false background: #black virtual: true refresh: every(24#cycle){
			chart "Cumulative incidence" background: #black axes: #white color: #white title_font: default legend_font: font("Helvetica", 14, #bold) {
				loop s over: simulations {
					data s.name value: s.total_number_of_infected color: s.color marker: false style: line thickness: 2; 
				}
			}
		}		
	}	

}