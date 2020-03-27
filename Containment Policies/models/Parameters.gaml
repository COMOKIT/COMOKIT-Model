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
	float transmission_rate<-0.5;
	float max_incubation_time<-360.0;//15 * 24h
	float max_recovery_time<-360.0;
	float max_hospitalization_time<-360.0;
	
	float proba_free_rider;
	
	float alpha<-0.5;
	float epsilon<-0.5;
	float sigma<-0.5;
	float delta<-0.9;
	
	float R0<-2.0;
	
	float N_grandfather<-0.2;
	float M_grandmother<-0.3;
	

	
	
}