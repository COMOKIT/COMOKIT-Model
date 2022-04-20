/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Example of experiments with COMOKIT Building.
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/
model CoVid19

import "HospitalActivity.gaml"  

import "HospitalIndividual.gaml"

import "Hospital Spatial Entities.gaml"


import "../Experiments/Abstract Experiment.gaml"

global {
	
	
	list<Room> available_rooms;
	

}

 

experiment hospital_no_intervention type: gui parent: "Abstract Experiment"{
	
	action _init_
	{   
		create simulation with: [
			//init_all_ages_proportion_wearing_mask::0.6,
			//init_all_ages_factor_contact_rate_wearing_mask:: 0.8,
			//ventilation_proba::0.7

		];
	}
}
