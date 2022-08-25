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
	
	string dataset_path <- "../Datasets/Alpes-Maritimes/";
	
	bool test_mode <- false;
	string csv_boundary_path <- dataset_path + "generated/boundary.csv" ;
	string csv_agenda_path <- dataset_path + "generated/agenda.data" ;
	string agenda_path <- dataset_path+"generated/agenda_data/";
	string shp_boundary_path <- dataset_path + "generated/boundary.shp";
	
	//Population data 
	string csv_building_type_weights_path <- (dataset_path+"Building type weights.csv") ;
		
	
	string csv_activity_weights_path <- (dataset_path+"Activity weights.csv") ;
	
	float step <- 1#h;
	date starting_date <- date([2022,2,14]);
	date ending_date <- date([2022,8,14]);
	
	int hospital_icu_capacity <- #max_int;
	
	float mask_ratio <- 0.5;
	float factor_contact_rate_wearing_mask <- 0.5;

	float density_ref_contact <- 200.0;
	map<string,float> building_type_infection_factor <- ["home"::0.5];
	string variant <- DELTA;
	int nb_init_infected <- 20;
	
	int num_replication_parameters <- 3;
	
}
