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
	

	//Epidemiological parameters
	float R0 <- 2.5;
	float contact_distance <- 2#m;
	float successful_contact_rate <- R0 * 1/(14.69973*24);
	float factor_contact_rate_asymptomatic <- 0.55;
	float proportion_asymptomatic <- 0.3;
	float proportion_dead_symptomatic <- 0.01;
	float proportion_symptomatic_using_mask <- 0.2;
	
	//Testing parameter
	float probability_true_positive <- 0.89;
	float probability_true_negative <- 0.92;
	
	//Mask parameters
	float factor_contact_rate_wearing_mask <- 0.5; //Assumed
	float proportion_wearing_mask <- 0.0;
	
	//Agenda paramaters
	float proba_activity_night <- 0.7;
	float proba_lunch_outside <- 0.5;
	float proba_lunch_at_home <- 0.5;
}