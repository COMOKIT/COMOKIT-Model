/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi, Alexis Drogoul
* Tags: covid19,epidemiology
***/
model CoVid19

import "../Model/Global.gaml"

global {

// Utils variable for the look and feel of simulation GUI
	font default <- font("Helvetica", 18, #bold);
	rgb text_color <- world.color.brighter.brighter;
	rgb background <- world.color.darker.darker;

	// Monitor the number of infectious individual
	int number_of_infectious <- 0 update: length(Individual where (each.is_infectious));

	/*
	 * Gloabl three steps initialization of a any simulation
	 */
	init {
		do init_epidemiological_parameters;
		do global_init;
		do create_authority;
	}

}

/*
 * The highest order abstraction to initialize a simulation instance of a COMOKIT model. Any
 * new use case, should extend it. It provides basic data set path management and display setup options for the GUI </br>
 * Also see Abstract Experiment with Parameters.gaml and Abstract Batch Experiment for more features. </br>
 * 
 */
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
			error "Datasets folder does not exist : " + datasets_folder_path;
		} else if not (folder_exists(dfp + csfd)) {
			error "Case study folder  does not exist : " + dfp + case_study_folder_name;
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

			agents "Individual" value: Individual where not (each.is_outside) {
				draw square(state = susceptible or clinical_status = recovered ? 10 : 20) color: state = latent ? #yellow : (self.is_infectious ? #orangered : (clinical_status = recovered ?
				#blue : #green));
			}

		}

		display "default_3D_display" synchronized: false type: opengl background: #black draw_env: false virtual: true {
			image file: file_exists(dataset_path + "/satellite.png") ? (dataset_path + "/satellite.png") : "../Utilities/white.png" transparency: 0.5 refresh: false;
			species Building transparency: 0.7 refresh: false {
				draw shape depth: rnd(50) color: #lightgrey empty: false width: 2;
			}

			agents "Other" value: Individual where (not each.is_outside and each.clinical_status = recovered or each.state = susceptible) transparency: 0.5 {
				draw sphere(30) color: (clinical_status = recovered ? #blue : #green) at: location - {0, 0, 30};
			}

			agents "Exposed" value: Individual where (not each.is_outside and each.clinical_status = latent) transparency: 0.5 {
				draw sphere(30) color: #yellow at: location - {0, 0, 30};
			}

			agents "Infectious" value: Individual where (not each.is_outside and each.is_infectious) transparency: 0.5 {
				draw sphere(50) color: #red at: location - {0, 0, 50};
			}

		}

		display "simple_display" parent: default_display synchronized: false type: opengl background: #black virtual: true draw_env: false {
			species Building {
				draw shape color: #lightgrey empty: true width: 2;
			}

			agents "Individual" value: Individual where not (each.is_outside) {
				draw square(self.is_infectious ? 30 : 10) color: state = latent ? #yellow : (self.is_infectious ? #orangered : (clinical_status = recovered ? #blue : #green));
			}

		}

		display "default_white_chart" virtual: true {
			chart "sir" background: #white axes: #black {
				data "susceptible" value: length(Individual where (each.state = susceptible)) color: #green marker: false style: line;
				data "latent" value: length(Individual where (each.is_latent())) color: #orange marker: false style: line;
				data "infected" value: length(Individual where (each.is_infectious)) color: #red marker: false style: line;
				data "recovered" value: length(Individual where (each.clinical_status = recovered)) color: #blue marker: false style: line;
				data "dead" value: length(Individual where (each.clinical_status = dead)) color: #black marker: false style: line;
			}

		}

		display "cumulative_incidence" virtual: true {
			chart "cumulative incidence" background: #white axes: #black {
				data "cumulative incidence" value: total_number_of_infected color: #red marker: false style: line;
			}

		}

	}

}