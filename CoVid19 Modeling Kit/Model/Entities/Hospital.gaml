/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi
* Tags: covid19,epidemiology
***/


@no_experiment

model CoVid19

import "Building.gaml"

species Hospital parent:Building {

	aspect default {
		draw shape+10 color: #black;
	}

}