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

import "Constants.gaml"

global {
	
	// Parameter folder path
	string parameters_folder_path <- experiment.project_path+"Parameters";
	// The case study name and dataset path variable to be used in models
	string case_study_folder_name; // The case study folder
	string datasets_folder_path; // The path from root project to the data set folder (can contains several case studies)
	// Default dataset management
	list<string> EXCLUDED_CASE_STUDY_FOLDERS_NAME <- ["Test Generate GIS Data"] const:true;
	string DEFAULT_CASE_STUDY_FOLDER_NAME <- "Vinh Phuc" const: true;
	string DEFAULT_DATASETS_FOLDER_NAME <- "Datasets"  const: true;
	// The actual dataset path
	string dataset_path <- build_dataset_path();
	
	//GIS data
	file shp_boundary <- file_exists(dataset_path+"boundary.shp") ? shape_file(dataset_path+"boundary.shp"):nil;
	file shp_buildings <- file_exists(dataset_path+"buildings.shp") ? shape_file(dataset_path+"buildings.shp"):nil;

	//Population data 
	csv_file csv_population <- file_exists(dataset_path+"population.csv") ? csv_file(dataset_path+"population.csv",separator,qualifier,header):nil;
	csv_file csv_population_attribute_mappers <- file_exists(dataset_path+"Population Records.csv")?csv_file(dataset_path+"Population Records.csv",",",true):nil;
	csv_file csv_parameter_population <- file_exists(dataset_path+"Population parameter.csv") ? csv_file(dataset_path+"Population parameter.csv",",",true):nil;
	csv_file csv_parameter_agenda <- file_exists(dataset_path+"Agenda parameter.csv") ? csv_file(dataset_path+"Agenda parameter.csv",",",true):nil;
	csv_file csv_activity_weights <- file_exists(dataset_path+"Activity weights.csv") ? csv_file(dataset_path+"Activity weights.csv",",",string, false):nil;
	csv_file csv_building_type_weights <- file_exists(dataset_path+"Building type weights.csv") ? csv_file(dataset_path+"Building type weights.csv",",",string, false):nil;
	
	
	//simulation step
	float step<-1#h;
	date starting_date <- date([2020,3,2]);
	
	int num_infected_init <- 2; //number of infected individuals at the initialization of the simulation
	int num_recovered_init <- 0; //The number of people that have already been infected in the past

	//Epidemiological parameters
	float nb_step_for_one_day <- #day/step; //Used to define the different period used in the model
	
	bool load_epidemiological_parameter_from_file <- true; //Allowing parameters being loaded from a csv file 
	string epidemiological_parameters <- (last(parameters_folder_path)="/"?parameters_folder_path:parameters_folder_path+"/")
		+"Epidemiological Parameters.csv"; //File for the parameters
	file csv_parameters <- file_exists(epidemiological_parameters)?csv_file(epidemiological_parameters):nil;
	
	//Dynamics
	bool allow_transmission_human <- true; //Allowing human to human transmission
	bool allow_transmission_building <- true; //Allowing environment contamination and infection
	bool allow_viral_individual_factor <- false; //Allowing individual effects on the beta and viral release
	
	
	//Environmental contamination
	float successful_contact_rate_building <- 2.5 * 1/(14.69973*nb_step_for_one_day);//Contact rate for environment to human transmission derivated from the R0 and the mean infectious period
	float reduction_coeff_all_buildings_inhabitants <- 0.01; //reduction of the contact rate for individuals belonging to different households leaving in the same building
	float reduction_coeff_all_buildings_individuals <- 0.05; //reduction of the contact rate for individuals belonging to different households leaving in the same building
	float basic_viral_release <- 3.0; //Viral load released in the environment by infectious individual
	float basic_viral_decrease <- 0.33; //Value to decrement the viral load in the environment
	
	
	//These parameters are used when no CSV is loaded to build the matrix of parameters per age
	float init_all_ages_successful_contact_rate_human <- 2.5 * 1/(14.69973);//Contact rate for human to human transmission derivated from the R0 and the mean infectious period
	float init_all_ages_factor_contact_rate_asymptomatic <- 0.55; //Factor of the reduction for successful contact rate for  human to human transmission for asymptomatic individual
	float init_all_ages_proportion_asymptomatic <- 0.3; //Proportion of asymptomatic infections
	float init_all_ages_proportion_dead_symptomatic <- 0.01; //Proportion of symptomatic infections dying
	float init_all_ages_probability_true_positive <- 0.89; //Probability of successfully identifying an infected
	float init_all_ages_probability_true_negative <- 0.92; //Probability of successfully identifying a non infected
	float init_all_ages_proportion_wearing_mask <- 0.0; //Proportion of people wearing a mask
	float init_all_ages_factor_contact_rate_wearing_mask <- 0.5; //Factor of reduction for successful contact rate of an infectious individual wearing mask
	string init_all_ages_distribution_type_incubation_period_symptomatic <- "Lognormal"; //Type of distribution of the incubation period; Among normal, lognormal, weibull, gamma
	float init_all_ages_parameter_1_incubation_period_symptomatic <- 1.57; //First parameter of the incubation period distribution for symptomatic
	float init_all_ages_parameter_2_incubation_period_symptomatic <- 0.65; //Second parameter of the incubation period distribution for symptomatic
	string init_all_ages_distribution_type_incubation_period_asymptomatic <- "Lognormal"; //Type of distribution of the incubation period; Among normal, lognormal, weibull, gamma
	float init_all_ages_parameter_1_incubation_period_asymptomatic <- 1.57; //First parameter of the incubation period distribution for asymptomatic
	float init_all_ages_parameter_2_incubation_period_asymptomatic <- 0.65; //Second parameter of the incubation period distribution for asymptomatic
	string init_all_ages_distribution_type_serial_interval <- "Normal"; //Type of distribution of the serial interval
	float init_all_ages_parameter_1_serial_interval <- 3.96;//First parameter of the serial interval distribution
	float init_all_ages_parameter_2_serial_interval <- 3.75;//Second parameter of the serial interval distribution
	string init_all_ages_distribution_type_infectious_period_symptomatic <- "Lognormal";//Type of distribution of the time from onset to recovery
	float init_all_ages_parameter_1_infectious_period_symptomatic <- 3.034953;//First parameter of the time from onset to recovery distribution
	float init_all_ages_parameter_2_infectious_period_symptomatic <- 0.34;//Second parameter of the time from onset to recovery distribution
	string init_all_ages_distribution_type_infectious_period_asymptomatic <- "Lognormal";//Type of distribution of the time from onset to recovery
	float init_all_ages_parameter_1_infectious_period_asymptomatic <- 3.034953;//First parameter of the time from onset to recovery distribution
	float init_all_ages_parameter_2_infectious_period_asymptomatic <- 0.34;//Second parameter of the time from onset to recovery distribution
	float init_all_ages_proportion_hospitalisation <- 0.2; //Proportion of symptomatic cases hospitalized
	string init_all_ages_distribution_type_onset_to_hospitalisation <- "Lognormal";//Type of distribution of the time from onset to hospitalization
	float init_all_ages_parameter_1_onset_to_hospitalisation  <- 3.034953;//First parameter of the time from onset to hospitalization distribution
	float init_all_ages_parameter_2_onset_to_hospitalisation  <- 0.34;//Second parameter of the time from onset to hospitalization distribution
	float init_all_ages_proportion_icu <- 0.1; //Proportion of hospitalized cases going through ICU
	string init_all_ages_distribution_type_hospitalisation_to_ICU <- "Lognormal";//Type of distribution of the time from hospitalization to ICU
	float init_all_ages_parameter_1_hospitalisation_to_ICU  <- 3.034953;//First parameter of the time from hospitalization to ICU
	float init_all_ages_parameter_2_hospitalisation_to_ICU  <- 0.34;//Second parameter of the time from hospitalization to ICU
	string init_all_ages_distribution_type_stay_ICU <- "Lognormal";//Type of distribution of the time to stay in ICU
	float init_all_ages_parameter_1_stay_ICU <- 3.034953;//First parameter of the time to stay in ICU
	float init_all_ages_parameter_2_stay_ICU <- 0.34;//Second parameter of the time to stay in ICU
	string init_all_ages_distribution_viral_individual_factor <- "Lognormal"; //Type of distribution of the individual factor for beta and viral release
	float init_all_ages_parameter_1_viral_individual_factor <- -0.125; //First parameter of distribution of the individual factor for beta and viral release
	float init_all_ages_parameter_2_viral_individual_factor <- 0.5; //Second parameter of distribution of the individual factor for beta and viral release
	int ICU_capacity<-17; //Capacity of ICU for one hospital (from file)
	int hospitalisation_capacity <- 200; //Capacity of hospitalisation admission for one hospital (assumed)
	list<string> force_parameters;
	
	//Synthetic population parameters
	
	// ------ From file
	string OTHER <- "OTHER" const:true;
	string EMPTY <- "EMPTY" const:true;
	// **
	string separator <- ";"; // File separator for synthetic population micro-data
	string qualifier <- "\""; // The default text qualifier
	bool header <- true; // If there is a header or not
	
	string age_var; // The variable name for "age" Individual attribute 
	map<string,list<float>> age_map;  // The mapping of value for gama to translate, if nill then direct cast to int 
	string gender_var; // The variable name for "sex" Individual attribute 
	map<string,int> gender_map; // The mapping of value for gama to translate sex into 0=male 1=female, if nill then cast to int
	string unemployed_var; // The variable that represent employment status 
	map<string,bool> unemployed_map; // false = employed, true = unemployed
	string householdID; // The variable for household identification
	string individualID <- nil; // The variable for individual identification
	// **
	int number_of_individual <- -1; // Control the number of Individual agent in the simulation from the file: if <0 or more than record in the file, takes the exact number of individual in the file
	
	// ------ From default Gaml generator
	float male_ratio <- 21/41; // Ratio of 105 males for 100 females, see https://ourworldindata.org/gender-ratio
	float proba_active_family <- 0.95;
	float number_children_mean <- 2.0;
	float number_children_std <- 0.5;
	int number_children_max <- 3;
	float proba_grandfather<-  0.2; //rate of grandfathers (individual with age > retirement_age) - num of grandfathers = N_grandfather * num of possible homes
	float proba_grandmother<- 0.3; //rate of grandmothers (individual with age > retirement_age) - num of grandmothers = M_grandmother * num of possible homes
	int school_age <- 3;
	int active_age <- 16;
	int high_education_age <- 24;
	int retirement_age <- 55; //an individual older than (retirement_age + 1) are not working anymore
	int max_age <- 100; //max age of individual
	float nb_friends_mean <- 5.0; //Mean number of friends living in the considered area
	float nb_friends_std <- 3.0;//Stand deviation of the number of friends living in the considered area
	float nb_classmates_mean <- 10.0; //Mean number of classmates with which an Individual will have close contact
	float nb_classmates_std <- 5.0;//Stand deviation of the number of classmates with which an Individual will have close contact
	float nb_work_colleagues_mean <- 5.0; //Mean number of work colleagures with which an Individual will have close contact
	float nb_work_colleagues_std <- 3.0;//Stand deviation of the number of work colleagures with which an Individual will have close contact
	float proba_work_at_home <- 0.05; //probability to work at home;
	float proba_unemployed_M <- 0.03; // probability for a M individual to be unemployed.
	float proba_unemployed_F <-0.03; // probability for a F individual to be unemployed.
	
	
	 //building type that will be considered as home - for each type, the coefficient to apply to this type for this choice of working place
	 //weight of a working place = area * this coefficient
	map<string, float> possible_workplaces;
	
	// building type that will considered as school (ou university) - for each type, the min and max age to go to this type of school.
	map<string, list<int>> possible_schools; 

	
	//Acvitity parameters 
	string building_type_per_activity_parameters <- (last(parameters_folder_path)="/"?parameters_folder_path:parameters_folder_path+"/")
		+"Building type per activity type.csv"; //File for the parameters
	
	string choice_of_target_mode <- gravity among: ["random", "gravity","closest"]; // model used for the choice of building for an activity 
	int nb_candidates <- 4; // number of building considered for the choice of building for a particular activity
	float gravity_power <- 0.5;  // power used for the gravity model: weight_of_building <- area of the building / (distance to it)^gravity_power
	
	
	
	//Agenda paramaters
	list<int> non_working_days <- [7]; //list of non working days (1 = monday; 7 = sunday)
	int work_hours_begin_min <- 6; //beginning working hour: min value
	int work_hours_begin_max <- 8; //beginning working hour: max value 
	int work_hours_end_min <- 15; //ending working hour: min value
	int work_hours_end_max <- 18; //ending working hour: max value
	float schoolarship_rate <- 1.0; // The proportion of school agent
	int school_hours_begin_min <- 7; //beginning studying hour: min value
	int school_hours_begin_max <- 9; //beginning studying hour: max value
	int school_hours_end_min <- 15; //ending studying hour: min value
	int school_hours_end_max <- 18; //ending studying hour: max value
	int first_act_hour_non_working_min <- 7; //for non working day, min hour for the beginning of the first activity 
	int first_act_hour_non_working_max <- 10; //for non working day, max hour for the beginning of the first activity 
	int lunch_hours_min <- 11; //min hour for the begining of the lunch time
	int lunch_hours_max <- 13; //max hour for the begining of the lunch time
	int max_duration_lunch <- 2; // max duration (in hour) of the lunch time
	int max_duration_default <- 3; // default duration (in hour) of activities
	int min_age_for_evening_act <- 13; //min age of individual to have an activity after school
	float nb_activity_fellows_mean <- 3.0; 
	float nb_activity_fellows_std <- 2.0;

	int max_num_activity_for_non_working_day <- 4; //max number of activity for non working day
	int max_num_activity_for_unemployed <- 3; //max number of activity for a day for unployed individuals
	int max_num_activity_for_old_people <- 3; //max number of activity for a day for old people ([0,max_num_activity_for_old_people])
	float proba_activity_evening <- 0.7; //proba for people (except old ones) to have an activity after work
	float proba_lunch_outside_workplace <- 0.5; //proba to have lunch outside the working place (home or restaurant)
	float proba_lunch_at_home <- 0.5; // if lunch outside the working place, proba of having lunch at home
	
	float proba_work_outside <- 0.0; //proba for an individual to work outside the study area
	float proba_go_outside <- 0.0; //proba for an individual to do an activity outside the study area
	float proba_outside_contamination_per_hour <- 0.0; //proba per hour of being infected for Individual outside the study area 
	
	//Activity parameters
	float building_neighbors_dist <- 500 #m; //used by "visit to neighbors" activity (max distance of neighborhood).
	
	
	//for each category of age, and for each sex, the weight of the different activities
	map<list<int>,map<int,map<string,float>>> weight_activity_per_age_sex_class <- [
		 [0,10] :: 
		[0::[act_neighbor::1.0,act_friend::1.0, act_eating::0.5, act_shopping::0.5,act_leisure::1.0,act_outside::2.0,act_sport::1.0,act_other::0.1 ], 
		1::[act_neighbor::1.0,act_friend::1.0, act_eating::0.5, act_shopping::0.5,act_leisure::1.0,act_outside::2.0,act_sport::1.0,act_other::0.1 ]],
	
		[11,18] :: 
		[0::[act_neighbor::0.2,act_friend::0.5, act_eating::2.0, act_shopping::1.0,act_leisure::3.0,act_outside::2.0,act_sport::3.0,act_other::0.5 ], 
		1::[act_neighbor::0.2,act_friend::0.5, act_eating::2.0, act_shopping::1.0,act_leisure::3.0,act_outside::2.0,act_sport::1.0,act_other::0.5 ]],
	
		[19,60] :: 
		[0::[act_neighbor::1.0,act_friend::1.0, act_eating::1.0, act_shopping::1.0,act_leisure::1.0,act_outside::1.0,act_sport::1.0,act_other::1.0 ], 
		1::[act_neighbor::2.0,act_friend::2.0, act_eating::0.2, act_shopping::3.0,act_leisure::0.5,act_outside::1.0,act_sport::0.5,act_other::1.0 ]],
	
		[61,120] :: 
		[0::[act_neighbor::3.0,act_friend::2.0, act_eating::0.5, act_shopping::0.5,act_leisure::0.5,act_outside::2.0,act_sport::0.2,act_other::2.0 ], 
		1::[act_neighbor::3.0,act_friend::2.0, act_eating::0.1, act_shopping::1.0,act_leisure::0.2,act_outside::2.0,act_sport::0.1,act_other::2.0 ]]
	
	];
	
	//for each category of age, and for each sex, the weight of the different type of buildings
	map<list<int>,map<int,map<string,float>>> weight_bd_type_per_age_sex_class <- [
		[0,10] :: 
		[0::["playground"::5.0, "park"::3.0, "gamecenter"::2.0], 
		1::["playground"::5.0, "park"::3.0, "gamecenter"::3.0]],
	
		[11,18] :: 
		[0::["playground"::2.0, "park"::2.0, "gamecenter"::3.0], 
		1::["playground"::2.0, "park"::2.0, "gamecenter"::1.0, "karaoke"::3.0, "cinema"::3.0, "caphe-karaoke"::3.0]],
	
		[19,60] :: 
		[0::["playground"::0.5, "park"::2.0, "gamecenter"::1.0], 
		1::["playground"::5.0, "park"::3.0, "gamecenter"::3.0]],
	
		[61,120] :: 
		[0::["playground"::0.0, "park"::3.0, "gamecenter"::0.1, "place_of_worship"::2.0, "cinema"::2.0], 
		1::["playground"::0.0, "park"::3.0, "gamecenter"::0.0, "place_of_worship"::3.0,"cinema"::2.0]]
	
	];
	
	
	//Policy parameters
	list<string> meeting_relaxing_act <- [act_working,act_studying,act_eating,act_leisure,act_sport]; //fordidden activity when choosing "no meeting, no relaxing" policy
	int nb_days_apply_policy <- 0;
	
	// ---------------
	// PATH MANAGEMENT
	// ---------------
	
	/*
	 * Default way to initialize the data set redefining variables case_study_folder_name and datasets_folder_path
	 * relative to the location of the launched simulation
	 */
	string build_dataset_path(string relative_path <- experiment.project_path) {
		string the_path <- relative_path;
		string default <- the_path+"/"+DEFAULT_DATASETS_FOLDER_NAME+"/"+DEFAULT_CASE_STUDY_FOLDER_NAME+"/";
		if(datasets_folder_path=nil and case_study_folder_name=nil) {return default;}
		if(datasets_folder_path=nil){
			the_path <- the_path+DEFAULT_DATASETS_FOLDER_NAME+"/";
			the_path <- the_path + (folder_exists(the_path+case_study_folder_name) ? case_study_folder_name : DEFAULT_CASE_STUDY_FOLDER_NAME) + "/";
		} else {
			the_path <- (folder_exists(datasets_folder_path) ? datasets_folder_path : 
				(folder_exists(the_path+datasets_folder_path) ? the_path+datasets_folder_path : the_path+"/"+DEFAULT_DATASETS_FOLDER_NAME)
			) + "/";
			list<string> case_studies <- folder(the_path).contents; 
			if (case_studies contains case_study_folder_name) { the_path <- the_path+(last(case_study_folder_name)="/"?case_study_folder_name:case_study_folder_name+"/"); }
			else {
				list<string> relevantCS <- case_studies where (folder_exists(the_path+each) and 
					(list(folder(the_path+each).contents) one_matches (string(each) = "buildings.shp"))
				);
				the_path <- not(empty(relevantCS))?the_path+any(relevantCS)+"/":default;
			}
		}
		return the_path;
	}
	
}