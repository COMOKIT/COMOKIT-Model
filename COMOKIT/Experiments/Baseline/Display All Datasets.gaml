/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul
* 
* Description: 
* 	The model creates one simulation for each dataset and launches it with a no containment policy.
* 
* Parameters: 
* 	The datasets that will be loaded are defined given the 2 following global variables (defined in Parameters.gaml file): 
* 	- DEFAULT_DATASETS_FOLDER_NAME: the folder name of the dataset  (by default it is  'Datasets' ).
* 	- EXCLUDED_CASE_STUDY_FOLDERS_NAME: among all the folders located in DEFAULT_DATASETS_FOLDER_NAME, 
* 			this parameter specifies the ones that will be excluded. (by default it will be only 'Test Generate GIS Data')
* 
* Dataset: all datasets available in the Datasets folder.
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

experiment "Datasets" parent: "Abstract Experiment" autorun: true {

	action _init_ {
		list<string> dirs <- gather_dataset_names() - EXCLUDED_CASE_STUDY_FOLDERS_NAME;
		float simulation_seed <- rnd(2000.0);
		loop s over:  dirs {
			create simulation with: [dataset_path::build_dataset_path(_case_study_folder_name::s), seed::simulation_seed] {
				name <- s;
				ask Authority {
					policy <- create_no_containment_policy();
				}
			}
		}
	}

	output {
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false;

		display name synchronized: false type: opengl background: #black draw_env: false parent: default_3D_display {

			graphics "Simulation Name" {
				draw world.name  font: default at: {0, world.shape.height/2 - 30#px} color: text_color anchor: #top_left;
			}
			
			graphics "Day and Cases" {
				draw ("Day " + int((current_date - starting_date) /  #day)) + " | " + ("Cases " + world.number_of_infectious)  font: default at: {0, world.shape.height/2 - 50#px}  color: text_color anchor: #top_left;
			}
		}
	}
}