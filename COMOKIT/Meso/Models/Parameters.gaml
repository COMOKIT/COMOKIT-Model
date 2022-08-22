/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* This is where all the parameters of the model are being declared and, 
* for some, initialised with default values.
* 
* Author: Huynh Quang Nghi, Benoit Gaudou, Damien Philippon, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

//@no_experiment

model CoVid19

import "../../Core/Models/Parameters.gaml"

global {
	
	// The actual dataset path
	//string dataset_path <- build_dataset_path();
	string dataset_path <- "../Datasets/Vinh Phuc/";
	
	
	bool parallel_computation <- false;
	// precomputation parameters
	bool use_activity_precomputation <- false; //if true, use precomputation model
	bool udpate_for_display <- false; // if true, do some additional computation only for display purpose
	//bool load_activity_precomputation_from_file <- false; //if true, use file to generate the population and their agenda and activities
	int nb_weeks_ref <- 2 min: 1; // number of weeks precomputed used (should not be higher than the number precomputed in the file)
	
	string file_activity_with_policy_precomputation_path <- "activity_with_policy_precomputation"; //file to use for precomputed activity when the policy is active
	string file_activity_without_policy_precomputation_path <- "activity_without_policy_precomputation"; //file to use for precomputed activity when the policy is not active
	
	string precomputation_folder <- "generated/"; //folder where are located all the precomputed files
	string file_population_precomputation_path <- "population_precomputation";
	string file_agenda_precomputation_path <-"agenda_precomputation";
	string file_building_precomputation_path <-"building_precomputation";
	
	
	//GIS data
	string shp_boundary_path <- (dataset_path+"boundary.shp");
	string shp_buildings_path <- (dataset_path+"buildings.shp");

	//Population data 
	string csv_population_path <-(dataset_path+"population.csv") ;
	string csv_population_attribute_mappers_path <- (dataset_path+"Population Records.csv");
	string csv_parameter_population_path <- (dataset_path+"Population parameter.csv");
	string csv_parameter_agenda_path <- (dataset_path+"Agenda parameter.csv") ;
	string csv_activity_weights_path <- (dataset_path+"Activity weights.csv") ;
	string csv_building_type_weights_path <- (dataset_path+"Building type weights.csv") ;
		
	
}