/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Species_Building
import "Individual.gaml" 

species Building parent:Individual {

	bool is_school <- false;

	aspect default {
//		draw name color:#black;
		draw shape color: is_school ? #blue : #gray empty: true;
	}

}