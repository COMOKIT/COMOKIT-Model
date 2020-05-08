/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Huynh Quang Nghi, Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/


@no_experiment

model CoVid19

import "Building.gaml"

global{
	int number_hospital <- 1;
	int capacity_hospitalisation_per_hospital <- 10000;
	int capacity_ICU_per_hospital <- 1000;
	
	//Action to create a hospital TO CHANGE WHEN DATA ARE AVAILABLE
	action create_hospital{
		create Hospital number:number_hospital{
			capacity_hospitalisation <- capacity_hospitalisation_per_hospital;
			capacity_ICU <- capacity_ICU_per_hospital;
		}
	}
}
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