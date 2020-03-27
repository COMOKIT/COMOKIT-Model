/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/


@no_experiment

model Species_Building
import "Building.gaml"

species Hospital parent:Building {

	aspect default {
		draw shape+10 color: #black;
	}

}