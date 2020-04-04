/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Parameters

import "Constants.gaml"

global {
	
	 
	//GIS data
	string dataset <- "../../data/Ben Tre/"; // default
	//string dataset <- "../../data/Vinh Phuc/"; // default
	//string dataset <- "../../data/Castanet Tolosan/"; // default
	
	file shp_commune <- file_exists(dataset+"commune.shp") ? shape_file(dataset+"commune.shp"):nil;
	file shp_buildings <- file_exists(dataset+"buildings.shp") ? shape_file(dataset+"buildings.shp"):nil;

	//Population data
	csv_file csv_population <- file_exists(dataset+"population.csv") ? csv_file(dataset+"population.csv",separator,header):nil;

	//simulation step
	float step<-1#h;
	date starting_date <- date([2020,3,1]);
	
	int num_infected_init <- 2; //number of infected individuals at the initialization of the simulation
	int num_recovered_init <- 0;

	//Epidemiological parameters
	float nb_step_for_one_day <- #day/step; //Used to define the different period used in the model
	bool load_epidemiological_parameter_from_file <- false; //Allowing parameters being loaded from a csv file 
	string epidemiological_parameters <- "../../data/parameters/Epidemiological_parameters.csv"; //File for the parameters
	file csv_parameters <- file_exists(epidemiological_parameters)?csv_file(epidemiological_parameters):nil;
	bool transmission_human <- true; //Allowing human to human transmission
	bool transmission_building <- true; //Allowing environment contamination and infection
	float successful_contact_rate_human <- 2.5 * 1/(14.69973);//Contact rate for human to human transmission derivated from the R0 and the mean infectious period
	float successful_contact_rate_building <- 2.5 * 1/(14.69973*nb_step_for_one_day);//Contact rate for environment to human transmission derivated from the R0 and the mean infectious period
	float reduction_contact_rate_asymptomatic <- 0.55; //Factor of the reduction for successful contact rate for  human to human transmission for asymptomatic individual
	float proportion_asymptomatic <- 0.3; //Proportion of asymptomatic infections
	float proportion_dead_symptomatic <- 0.01; //Proportion of symptomatic infections dying
	float basic_viral_release <- 3.0; //Viral load released in the environment by infectious individual
	float basic_viral_decrease <- 0.33; //Value to decrement the viral load in the environment
	float probability_true_positive <- 0.89; //Probability of successfully identifying an infected
	float probability_true_negative <- 0.92; //Probability of successfully identifying a non infected
	float proportion_wearing_mask <- 0.0; //Proportion of people wearing a mask
	float reduction_contact_rate_wearing_mask <- 0.5; //Factor of reduction for successful contact rate of an infectious individual wearing mask
	string distribution_type_incubation <- "Lognormal"; //Type of distribution of the incubation period; Among normal, lognormal, weibull, gamma
	float parameter_1_incubation <- 1.57; //First parameter of the incubation period distribution
	float parameter_2_incubation <- 0.65; //Second parameter of the incubation period distribution
	string distribution_type_serial_interval <- "Normal"; //Type of distribution of the serial interval
	float parameter_1_serial_interval <- 3.96;//First parameter of the serial interval distribution
	float parameter_2_serial_interval <- 3.75;//Second parameter of the serial interval distribution
	string distribution_type_onset_to_recovery <- "Lognormal";//Type of distribution of the time from onset to recovery
	float parameter_1_onset_to_recovery <- 3.034953;//First parameter of the time from onset to recovery distribution
	float parameter_2_onset_to_recovery <- 0.34;//Second parameter of the time from onset to recovery distribution
	float proportion_hospitalization <- 0.2; //Proportion of symptomatic cases hospitalized
	float proportion_icu <- 0.1; //Proportion of symptomatic cases going through ICU
	list<string> force_parameters;
	
	//Synthetic population parameters
	string separator <- ";";
	bool header <- true; // If there is a header or not (must be true for now)
	string age_var <- "AGE"; // The variable name for "age" Individual attribute
	map<string,float> age_map;  // The mapping of value for gama to translate, if nill then direct cast to int (Default behavior in Synthetic Population.gaml)
	string gender_var <- "SEX"; // The variable name for "sex" Individual attribute
	map<string,int> gender_map <- ["1"::0,"2"::1]; // The mapping of value for gama to translate, if nill then cast to int
	string householdID <- "parentId"; // The variable for household identification
	
	//Population parameter
	float N_grandfather<-0.2; //rate of grandfathers (individual with age > retirement_age) - num of grandfathers = N_grandfather * num of possible homes
	float M_grandmother<-0.3; //rate of grandmothers (individual with age > retirement_age) - num of grandmothers = M_grandmother * num of possible homes
	int retirement_age <- 55; //an individual older than (retirement_age + 1) are not working anymore
	int max_age <- 100; //max age of individual
	
	list<string> possible_homes <- remove_duplicates(OSM_home + ["", "home", "hostel"]);  //building type that will be considered as home
	
	 //building type that will be considered as home - for each type, the coefficient to apply to this type for this choice of working place
	 //weight of a working place = area * this coefficient
	map<string, float> possible_workplaces <- (OSM_work_place as_map (each::2.0)) + map(["office"::3.0, "admin"::2.0, "industry"::1.0, ""::0.5,"home"::0.5,"store"::1.0, "shop"::1.0,"bookstore"::1.0,
		"gamecenter"::1.0, "restaurant"::1.0,"coffeeshop"::1.0,"caphe"::1.0, "caphe-karaoke"::1.0,"farm"::0.1, "repairshop"::1.0,"hostel"::1.0
	]);
	
	// building type that will considered as school (ou university) - for each type, the min and max age to go to this type of school.
	map<list<int>,string> possible_schools <- (dataset = "../../data/Ben Tre/") ? [[3,18]::"school"]: [[3,18]::"school", [19,23]::"university"]; 
	
	
	//Agenda paramaters
	list<int> non_working_days <- [7]; //list of non working days (1 = monday; 7 = sunday)
	list<list<int>> work_hours <- [[6,8], [15,18]]; //working hours: [[interval for beginning work],[interval for ending work]]
	list<list<int>> school_hours <- [[7,9], [15,18]]; //studying hours: [[interval for beginning study],[interval for ending study]]
	list<int> first_act_old_hours <- [7,10]; //for old people, interval for the beginning of the first activity 
	list<int> lunch_hours <- [11,13]; //interval for the begining of the lunch time
	int max_duration_lunch <- 2; // max duration (in hour) of the lunch time
	int max_duration_default <- 3; // default duration (in hour) of activities
	int min_age_for_evening_act <- 13; //min age of individual to have an activity after school
	
	int max_num_activity_for_non_working_day <- 4; //max number of activity for non working day
	int max_num_activity_for_old_people <- 3; //max number of activity for old people ([0,max_num_activity_for_old_people])
	float proba_activity_evening <- 0.7; //proba for people (except old ones) to have an activity after work
	float proba_lunch_outside_workplace <- 0.5; //proba to have lunch outside the working place (home or restaurant)
	float proba_lunch_at_home <- 0.5; // if lunch outside the working place, proba of having lunch at home
	
	float proba_go_outside <- 0.0; //proba for an individual to do an activity outside the study area
	float proba_outside_contamination_per_hour <- 0.0; //proba per hour of being infected for Individual outside the study area 
	
	//Activity parameters
	float building_neighbors_dist <- 500 #m; //used by "visit to neighbors" activity (max distance of neighborhood).
	
	//list of activities, and for each activity type, the list of possible building type
	map<string, list<string>> activities <- [
		act_shopping::remove_duplicates(OSM_shop + ["shop","market","supermarket", "store"]), 
		act_eating::remove_duplicates(OSM_eat + ["restaurant","coffeeshop", "caphe"]),
		act_leisure::remove_duplicates(OSM_leisure + ["gamecenter", "karaoke", "cinema", "caphe-karaoke"]), 
		act_outside::remove_duplicates(OSM_shop + ["playground", "park"]), 
		act_sport::remove_duplicates(OSM_sport + ["sport"]),
	 	act_other::remove_duplicates(OSM_other_activity + ["admin","meeting", "supplypoint","bookstore", "place_of_worship"])
	 ];
	
	//Policy parameters
	list<string> meeting_relaxing_act <- [act_working, act_studying,act_eating,act_leisure,act_sport]; //fordidden activity when choosing "no meeting, no relaxing" policy
	int nb_days_apply_policy <- 0;
}