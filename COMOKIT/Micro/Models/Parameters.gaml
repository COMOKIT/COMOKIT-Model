/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Parameters for COMOKIT Building
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/
@no_experiment
model Parameters

import "Constants.gaml"

global {
	
	string dataset_path <- "../Datasets/Danang Hospital/";
	
	date starting_date <- date([2020,4,6]);
	date final_date <- date([2020,4,20]);
	float step_duration <- 1#mn;
		
	//EPIDEMIOLOGIC PARAMETERS
	string variant <- DELTA; 
	
	int initial_nb_infected<-1;
	string init_state <- "symptomatic";
	float infectionDistance <- 2#m;
	float diminution_infection_rate_separator <- 0.9;
	float unit_cell_size <- 2#m;

	float basic_viral_air_increase_per_day <- 0.1;
	float basic_viral_local_increase_per_day <- 0.1;
	float basic_viral_air_decrease_per_day <- 0.025;
	float basic_viral_local_decrease_per_day <- 0.025;
	float ventilated_viral_air_decrease_per_day <- 0.1;

	bool allow_air_transmission <- true;
	bool allow_direct_transmission <- true;
	bool allow_local_transmission <- true;

	float default_ceiling_height <- 3#m;

	//INTERVENTION PARAMETERS
	float separator_proba <- 0.0; // proba to have a seperator between desks
	float ventilation_proba <- 0.0;

	//SIMULATION PARAMETERS
	bool parallel <- false; // use parallel computation
	int limit_cpt_for_entrance_room_creation <- 10; //dark parameter - no need to change this value
//	float nb_step_for_one_day <- #day / 1#s update: #day / 1#s;

	//DISPLAY PARAMETERS
	bool display_pedestrian_path <- false parameter: "Display pedestrian path" category: "Visualization";
	bool display_free_space <- false parameter: "Display free space" category: "Visualization";
	bool display_desk <- false parameter: "Display desks" category: "Visualization";
	bool display_room_entrance <- false parameter: "Display room entrance" category: "Visualization";
	bool display_room_status <- true parameter: "Display room status" category: "Visualization";
	bool display_infection_grid <- false parameter: "Display infection grid" category: "Visualization";
	bool display_building_entrance <- false parameter: "Display building entrance" category: "Visualization";


	bool a_boolean_to_disable_parameters <- false;
	
	
	float density_max_admi <- 3.0;// 5.4;
	float min_density_threshold <- #max_float;
	float lambda <- 1.913 ;
	float lane_width <- 3.0;
	obj_file pple_walk<- obj_file("../Utilities/people.obj", 90::{-1, 0, 0});
	obj_file pple_lie <- obj_file("../Utilities/people.obj", 0::{-1, 0, 0});
	float people_size <- 1.7;
	float udpate_path_weights_every	<- 5#mn;
	// Utils variable for the look and feel of simulation GUI
	font default <- font("Helvetica", 18, #bold) const: true;
	float coeff_visu_virus_load_cell <- 100.0;
	float coeff_visu_virus_load_room <- 3000.0;
		
	//PEDESTRIAN PARAMETERS
	float P_shoulder_length <- 0.2;
	float P_proba_detour <- 0.5;
	bool P_avoid_other <- false;
	float P_obstacle_consideration_distance <- 3.0;
	float P_pedestrian_consideration_distance <- 3.0;
	float P_minimal_distance <- 0.0;
	float P_tolerance_target <- 0.2;

	bool P_use_geometry_target <- true;

	float P_A_pedestrian_SFM  <- 0.16;
	float P_A_obstacles_SFM  <- 1.9;
	float P_B_pedestrian_SFM  <- 0.1;
	float P_B_obstacles_SFM  <- 1.0;
	float P_relaxion_SFM <- 0.5;
	float P_gama_SFM <- 0.35;
	float P_lambda_SFM <- 0.1;
	
	//FLOOR RELEVANT PARAMETER
	int nb_floor <- 2;
	list<bool> show_floor <- [true, false, true, true, true, true, true, true]
							parameter: "which floor show" category: "Visualization";
}
