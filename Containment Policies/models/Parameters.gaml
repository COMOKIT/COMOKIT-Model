/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Parameters

import "species/Authority.gaml"



global {
//	float seed <- 0.2955510396397566;
	file river_shapefile <- file("../data/Ben Tre/kenhrach_region.shp");
	file commune_shapefile <- file("../data/Ben Tre/ranhbinhdai_region.shp");
//	file shp_roads <- file("../data/Ben Tre/roads_osm.shp");
//	file shp_buildings <- file("../data/Ben Tre/nha_ThuaDuc_region.shp");
	file shp_roads <- file("../data/Vinh Phuc/roads.shp");
	file shp_buildings <- file("../data/Vinh Phuc/buildings.shp");

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
	
	
	Authority authority;
	
//	init {
//		write "Creating Activities";
//		do create_activities;
//	}
	
}