/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Parameters




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
	float building_neighbors_dist <- 500 #m; //used by visit to neighbors activity
	
}