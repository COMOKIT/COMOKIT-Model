/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi, Benoit Gaudou, Damien Philippon, Patrick Taillandier
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Individual.gaml"

global {
	
	// TODO : turn it into parameters, more generaly it may require to smoothly init building attribute
	// from shape_file not using only OSM standard (might be the internal standard though), but relying also on custom bindings
	// i.e. make it possible to say : the feature "type" in my shapefile is "typo" and "school" are "kindergarden"
	string type_shp_attribute <- "type";
	string flat_shp_attribute <- "flats";
	
}

species Building {

	float viral_load <- 0.0;
	string type;
	list<Building> neighbors;
	list<Individual> individuals;
	int nb_households;
	
	list<Building> get_neighbors {
		if empty(neighbors) {
			neighbors <- Building at_distance building_neighbors_dist;
			if empty(neighbors) {
				neighbors << Building closest_to self;
			}
		}
		return neighbors;
	}
	
	action addViralLoad(float value){
		if(transmission_building)
		{
			viral_load <- min(1.0,viral_load+value);
		}
	}
	reflex updateViralLoad when: transmission_building{
		viral_load <- max(0.0,viral_load - basic_viral_decrease/nb_step_for_one_day);
	}

	aspect default {
//		draw name color:#black;
		draw shape color: #gray empty: true;
	}

}

species outside parent: Building ;