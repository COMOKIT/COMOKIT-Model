/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Huynh Quang Nghi, Damien Philippon
* Tags: covid19,epidemiology
***/


@no_experiment

model CoVid19

import "Building.gaml"

species Hospital parent:Building {
	//Number of places for hospitalisation
	int capacity_hospitalisation; //NOT ICU
	//Number of places for ICU
	int capacity_ICU;
	
	list<Individual> hospitalised_individuals;
	list<Individual> ICU_individuals;
	
	aspect default {
		draw shape+10 color: #black;
	}

}