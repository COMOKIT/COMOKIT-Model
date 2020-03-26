/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Species_Politics
import "Politics.gaml"

species Spatialized_Politics parent:Politics{
	geometry application_area;
	aspect default {
		draw shape+10 color: #black;
	}

}