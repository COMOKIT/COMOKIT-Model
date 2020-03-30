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

	float viralLoad <- 0.0;
	string type_activity;
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
			viralLoad <- min(1.0,viralLoad+value);
		}
	}
	reflex updateViralLoad when: transmission_building{
		viralLoad <- max(0.0,viralLoad - viralLoadDecrease);
	}

	aspect default {
//		draw name color:#black;
		draw shape color: #gray empty: true;
	}

}

species outside parent: Building ;