/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Parameters

import "Constants.gaml"

global {
	
	
	string dataset <- "../../data/Vinh Phuc/"; // default
	
	file shp_river <- file_exists(dataset+"river.shp") ? shape_file(dataset+"river.shp"):nil;
	file shp_commune <- file_exists(dataset+"commune.shp") ? shape_file(dataset+"commune.shp"):nil;
	file shp_roads <- file_exists(dataset+"roads.shp") ? shape_file(dataset+"roads.shp"):nil;
	file shp_buildings <- file_exists(dataset+"buildings.shp") ? shape_file(dataset+"buildings.shp"):nil;

	graph road_network;
	float step<-1#h;
	
	float N_grandfather<-0.2;
	float M_grandmother<-0.3;
	
	int num_infected_init <- 2; //number of infected individuals at the initialization of the simulation
	

	//Epidemiological parameters
	bool transmission_human <- true;
	bool transmission_building <- false;
	float R0 <- 2.5;
	float contact_distance <- 2#m;
	float successful_contact_rate_human <- R0 * 1/(14.69973*24);
	float successful_contact_rate_building <- R0 * 1/(14.69973*24);
	float factor_contact_rate_asymptomatic <- 0.55;
	float proportion_asymptomatic <- 0.3;
	float proportion_dead_symptomatic <- 0.01;
	float proportion_symptomatic_using_mask <- 0.2;
	float basic_viral_release <- 3.0;
	float viralLoadDecrease <- 0.33/24;
	
	//Testing parameter
	float probability_true_positive <- 0.89;
	float probability_true_negative <- 0.92;
	
	//Mask parameters
	float factor_contact_rate_wearing_mask <- 0.5; //Assumed
	float proportion_wearing_mask <- 0.0;
	
	//Agenda paramaters
	int max_num_activity_for_old_people <- 3; //max number of activity for old people ([0,max_num_activity_for_old_people])
	float proba_activity_evening <- 0.7; //proba for people (except old ones) to have an activity after work
	float proba_lunch_outside_workplace <- 0.5; //proba to have lunch outside the working place (home or restaurant)
	float proba_lunch_at_home <- 0.5; // if lunch outside the working place, proba of having lunch at home
	
	float proba_go_outside <- 0.0; //proba for an individual to do an activity outside the study area
	float proba_outside_contamination_per_hour <- 0.0; //proba per hour of being infected for Individual outside the study area 
	
	//Activity parameters
	float building_neighbors_dist <- 500 #m; //used by "visit to neighbors" activity (max distance of neighborhood).
	
	int retirement_age <- 55;
	int max_age <- 90;
	list<list<int>> work_hours <- [[6,8], [15,18]];
	list<list<int>> school_hours <- [[7,9], [15,18]];
	list<int> first_act_old_hours <- [7,10];
	
	list<int> lunch_hours <- [11,13];
	int max_duration_lunch <- 2;
	int max_duration_default <- 3;
	int min_age_for_evening_act <- 13;

	
	list<string> possible_homes <- ["", "home", "hostel"];
	
	map<string, float> possible_workplaces <-  ["office"::3.0, "admin"::2.0, "industry"::1.0, ""::0.5,"home"::0.5,"store"::1.0, "shop"::1.0,"bookstore"::1.0,
		"gamecenter"::1.0, "restaurant"::1.0,"coffeeshop"::1.0,"caphe"::1.0, "caphe-karaoke"::1.0,"farm"::0.1, "repairshop"::1.0,"hostel"::1.0
	];
	map<list<int>,string> possible_schools <- [[3,18]::"school", [19,23]::"university"];
	
	
	map<string, list<string>> activities <- ["shopping"::["shop","market","supermarket", "store"], act_eating::["restaurant","coffeeshop", "caphe"],
	"leisure"::["gamecenter", "karaoke", "cinema", "caphe-karaoke"], "outside activity"::["playground", "park"], "sport"::["sport"],
	 "other activity"::["admin","meeting", "supplypoint","bookstore", "place_of_worship"]];
	
	list<string> meeting_relaxing_act <- [act_working, act_studying,act_eating,"leisure","sport"];
}