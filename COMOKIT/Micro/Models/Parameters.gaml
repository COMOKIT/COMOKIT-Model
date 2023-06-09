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
	
	string dataset_path <- "../Datasets/Simple Building/";
	
	date starting_date <- date([2020,4,6]);
	date final_date <- date([2020,4,20]);
	float step_duration <- 1#mn;
		
	//EPIDEMIOLOGIC PARAMETERS
	string variant <- DELTA; 
	
	float infectionDistance <- 1.5#m;
	float unit_cell_size <- 1#m;

	float basic_viral_air_increase_per_day <- 2.0;
	float basic_viral_local_increase_per_day <- 1.0;
	float basic_viral_air_decrease_per_day <- 0.3;
	float basic_viral_local_decrease_per_day <- 0.3;
	float ventilated_viral_air_decrease_per_day <- 1.8;

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
	float coeff_visu_virus_load_cell <- 500.0;
	float coeff_visu_virus_load_room <- 5000.0;
		
	
	float min_distance_between_people <- 0.0;
	

}
