/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/

@no_experiment

model Species_Building 
import "../Parameters.gaml"
import "Individual.gaml"


species Building {

	float viral_load <- 0.0;
	string type;
	list<Building> neighbors;
	list<Individual> individuals;
	
	
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
		viral_load <- max(0.0,viral_load - viral_load_decrease);
	}

	aspect default {
//		draw name color:#black;
		draw shape color: #gray empty: true;
	}

}

species outside parent: Building ;