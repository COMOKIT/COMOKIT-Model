/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Species_Activity
import "Building.gaml"

species Activity {
	string type;
	Building place;
	aspect default {
		draw shape+10 color: #black;
	}

}