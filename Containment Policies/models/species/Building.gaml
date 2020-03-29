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
	list<Building> neigbors;
	
	reflex updateChargeVirale{
		
	}

	aspect default {
//		draw name color:#black;
		draw shape color: #gray empty: true;
	}

}