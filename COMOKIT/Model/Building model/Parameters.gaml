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
	//SCENARIO
	list<string> workplace_layer <- [classe];
	string building_dataset_path <- "";
	string agenda_scenario <- "simple" among: ["simple", "school day"];
	float arrival_time_interval <- 40 #mn;
	date starting_date <- date([2020,4,6,5,30]);
	date final_date <- date([2020,4,20,18,0]);
	string density_scenario <- "distance" among: ["distance", "num_people_building", "num_people_room"]; //location of the desk
	int num_people_per_building <- 100;  //if density_scenario = num_people_building
	int num_people_per_room <- 1; //if density_scenario = num_people_room
	float distance_people <- 1.5; //if density_scenario = distance

	//COMMON AREA BEHAVIOR
	float proba_wander <- 0.003;
	float wandering_time <- 1 #mn;
	float proba_change_desk <- 0.003;

	//QUEING PARAMETERS
	bool queueing <- false;
	float distance_queue <- 1#m;
	float waiting_time_entrance <- 10#s;

	//SANITATION PARAMETERS
	bool use_sanitation <- false;
	float proba_using_before_work <- 0.7;
	float proba_using_after_work <- 0.3;
	int nb_people_per_sanitation <- 2;
	float sanitation_usage_duration <- 10 #s;

	//EPIDEMIOLOGIC PARAMETERS
	int initial_nb_infected<-5;
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
//	float step <- 1#s update: 1#s;
	bool parallel <- false; // use parallel computation
	int limit_cpt_for_entrance_room_creation <- 10; //dark parameter - no need to change this value
//	float nb_step_for_one_day <- #day / 1#s update: #day / 1#s;

	//DISPLAY PARAMETERS
	bool display_pedestrian_path <- false parameter: "Display pedestrian path" category: "Visualization";
	bool display_free_space <- false parameter: "Display free space" category: "Visualization";
	bool display_desk <- false parameter: "Display desks" category: "Visualization";
	bool display_room_entrance <- true parameter: "Display room entrance" category: "Visualization";
	bool display_room_status <- false parameter: "Display room status" category: "Visualization";
	bool display_infection_grid <- false parameter: "Display infection grid" category: "Visualization";
	bool display_building_entrance <- true parameter: "Display building entrance" category: "Visualization";

	bool a_boolean_to_disable_parameters <- false;
	// Utils variable for the look and feel of simulation GUI
	font default <- font("Helvetica", 18, #bold) const: true;
	float coeff_visu_virus_load_cell <- 100.0;
	float coeff_visu_virus_load_room <- 3000.0;
		
	//PEDESTRIAN PARAMETERS
	float P_shoulder_length <- 0.45;
	float P_proba_detour <- 0.5;
	bool P_avoid_other <- true;
	float P_obstacle_consideration_distance <- 3.0;
	float P_pedestrian_consideration_distance <- 3.0;
	float P_minimal_distance <- 0.0;
	float P_tolerance_target <- 0.1;
	bool P_use_geometry_target <- true;

	float P_A_pedestrian_SFM  <- 0.16;
	float P_A_obstacles_SFM  <- 1.9;
	float P_B_pedestrian_SFM  <- 0.1;
	float P_B_obstacles_SFM  <- 1.0;
	float P_relaxion_SFM <- 0.5;
	float P_gama_SFM <- 0.35;
	float P_lambda_SFM <- 0.1;
}
