/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Parameters

global {
	float seed <- 0.5362681362380473; //
//	float seed <- 0.2955510396397566;
	file river_shapefile <- file("../includes/kenhrach_region.shp");
	file commune_shapefile <- file("../includes/ranhbinhdai_region.shp");
	file road_shapefile <- file("../includes/roads_osm.shp");
	file building_shapefile <- file("../includes/nha_ThuaDuc_region.shp");
	geometry shape <- envelope(building_shapefile);
	int max_exposed_period <- 30;
	graph road_network;
	bool off_school<-true;
	int dead<-0;
	int nb_people<-500;
	float motor_spd<-50.0;
//	map<string, float> profiles <- ["poor"::0.3, "medium"::0.4, "standard"::0.2, "rich"::0.1]; //	map<string,float> profiles <- ["innovator"::0.0,"early_adopter"::0.1,"early_majority"::0.2,"late_majority"::0.3, "laggard"::0.5];

}