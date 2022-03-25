/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Declares the species and its sub-species representing the activities
* undertaken by Individuals. Associated actions are also declared in this file.
* 
* Author: Benoit Gaudou, Huynh Quang Nghi, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19 



global {
	// A map of all possible activities
	map<string, AbstractActivity> Activities;
	
	list<string> activities_to_remove;
	
}
species AbstractActivity virtual: true {
	list<string> types_of_building <- [];
}
