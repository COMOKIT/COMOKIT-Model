/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/

@no_experiment

model Species_Building 

species Building {

	float chargeVirale;
	string type_activity;
	list<Building> neighbors;
	
	
	list<Building> get_neighbors {
		if empty(neighbors) {
			neighbors <- Building at_distance 500#m;
			if empty(neighbors) {
				neighbors << Building closest_to self;
			}
		}
		return neighbors;
	}
	reflex updateChargeVirale{
		
	}

	aspect default {
//		draw name color:#black;
		draw shape color: #gray empty: true;
	}

}