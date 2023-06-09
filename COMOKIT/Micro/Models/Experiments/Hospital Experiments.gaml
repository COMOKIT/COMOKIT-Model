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

import "../Hospital/HospitalActivity.gaml"

import "../Hospital/HospitalIndividual.gaml"

import "../Hospital/Hospital Spatial Entities.gaml" 


import "Abstract Experiment.gaml"
 
global {
	string dataset_path <- "../Datasets/Danang Hospital/";
	
	list<Room> available_rooms;
	map<string,rgb> room_type_color <- [ROOM::#lightblue,DOCTOR_ROOM::#yellow, HEAD_DOCTOR_ROOM::#gold, NURSE_ROOM::#orange,MEETING_ROOM::#cyan,ADMISSION_ROOM::#violet, HALL::#gray, INJECT::#magenta , MEDICINE::#pink, MINOPERATION::#brown ];
	

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
	
	output {
		display hospital_map parent: map_global{}
		display map_1_floor type: opengl background: #black {
			camera #default dynamic: true target: selected_bd = nil ? world : selected_bd distance: distance_camera ;
			species Building ;
			species Room ;
			species Elevator ;
			species Wall;
			//species Bed;
			species Doctor;
			species Intern;
			species Nurse;
			species Caregiver;
			species Staff;
			species Inpatient;
			species Outpatient;
			
		}
		display evolution_chart parent:states_evolution_chart{}
		
	}
}
