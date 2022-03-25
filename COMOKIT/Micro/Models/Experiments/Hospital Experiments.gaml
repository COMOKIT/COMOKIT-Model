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

import "Base Experiment.gaml"

experiment main type: gui parent: AbstractExperiment{
	
	action _init_
	{   
		create simulation with: [
			num_people_per_room:: 20, 
			distance_people::2.0#m, 
			separator_proba::0.0,
			init_all_ages_proportion_wearing_mask::0.6,
			init_all_ages_factor_contact_rate_wearing_mask:: 0.8,
			ventilation_proba::0.7

		];
	}
}

//experiment NoIntervention type: gui parent: AbstractExperiment{
//	string scenario<-"school day";
//	
//	action _init_
//	{   
//		create simulation with: [num_people_per_room:: 20, density_scenario::"num_people_room",distance_people::2.0#m, 
//		agenda_scenario::scenario, separator_proba::0.0,
//		init_all_ages_proportion_wearing_mask::0.0,init_all_ages_factor_contact_rate_wearing_mask:: 0.0, ventilation_proba::0.0
//		];
//	}
//}

//experiment UsingMask type: gui parent: AbstractExperiment{
//	string scenario<-"school day";
//	
//	action _init_
//	{   
//		create simulation with: [num_people_per_room:: 20, density_scenario::"num_people_room",distance_people::2.0#m, 
//		building_dataset_path:: "../../Datasets/LFAY/",agenda_scenario::scenario, separator_proba::0.0,
//		init_all_ages_proportion_wearing_mask::1.0,init_all_ages_factor_contact_rate_wearing_mask:: 1.0,ventilation_proba::0.0];
//	}
//}
//
//experiment UsingSeparator type: gui parent: AbstractExperiment{
//	string scenario<-"school day";
//	
//	action _init_
//	{   
//		create simulation with: [num_people_per_room:: 20, density_scenario::"num_people_room",distance_people::2.0#m, 
//		building_dataset_path:: "../../Datasets/LFAY/",agenda_scenario::scenario, separator_proba::1.0,
//		init_all_ages_proportion_wearing_mask::0.0,init_all_ages_factor_contact_rate_wearing_mask:: 0.0, ventilation_proba::0.0];
//	}
//}
//
//experiment UsingVentilation type: gui parent: AbstractExperiment{
//	string scenario<-"school day";
//	
//	action _init_
//	{   
//		create simulation with: [num_people_per_room:: 20, density_scenario::"num_people_room",distance_people::2.0#m, 
//		building_dataset_path:: "../../Datasets/LFAY/",agenda_scenario::scenario,  separator_proba::0.0,
//		init_all_ages_proportion_wearing_mask::0.0,init_all_ages_factor_contact_rate_wearing_mask:: 0.0, ventilation_proba::1.0];
//	}
//}
//
//experiment UsingQueue type: gui parent: AbstractExperiment{
//	string scenario<-"school day";
//	
//	action _init_
//	{   
//		create simulation with: [num_people_per_room:: 20, density_scenario::"num_people_room",distance_people::2.0#m, 
//		building_dataset_path:: "../../Datasets/LFAY/",agenda_scenario::scenario,  separator_proba::0.0,
//		init_all_ages_proportion_wearing_mask::0.0,init_all_ages_factor_contact_rate_wearing_mask:: 0.0, ventilation_proba::0.0, queueing::true];
//	}
//}
//
//
//experiment UsingSanitation type: gui parent: AbstractExperiment{
//	string scenario<-"school day";
//	
//	action _init_
//	{   
//		create simulation with: [num_people_per_room:: 20, density_scenario::"num_people_room",distance_people::2.0#m, 
//		building_dataset_path:: "../../Datasets/LFAY/",agenda_scenario::scenario,  separator_proba::0.0,
//		init_all_ages_proportion_wearing_mask::0.0,init_all_ages_factor_contact_rate_wearing_mask:: 0.0, ventilation_proba::0.0, queueing::false, use_sanitation::true, queueing::true];
//	}
//}
