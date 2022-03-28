/**
* Name: Functions
* Based on the internal empty template. 
* Author: Patrick Taillandier
* Tags: 
*/


model Functions

import "../../Core/Models/Constants.gaml"

global {
	map<string, list<string>> init_building_type_parameters_fct(string building_type_per_activity_parameters, 	map<string, float> possible_workplaces, map<string, list<int>> possible_schools, int school_age ,int active_age) {
		map<string, list<string>> activities <- [];
		file csv_parameters <- csv_file(building_type_per_activity_parameters,",",true);
		matrix data <- matrix(csv_parameters);
		// Modifiers can be weights, age range, or anything else
		list<string> available_modifiers <- [WEIGHT,RANGE];
		map<string,string> activity_modifiers;
		//Loading the different rows number for the parameters in the file
		loop i from: 0 to: data.rows-1{
			string activity_type <- data[0,i];
			bool modifier <- available_modifiers contains activity_type;
			list<string> bd_type;
			loop j from: 1 to: data.columns - 1 {
				if (data[j,i] != nil) {	 
					if modifier {
						activity_modifiers[data[j,i-1]] <- data[j,i]; 
					} else {
						if data[j,i] != nil or data[j,i] != "" {bd_type << data[j,i];}
					}
				}
			}
			if not(modifier) { activities[activity_type] <- bd_type; }
		}
		
		if activities contains_key act_studying {
			loop acts over:activities[act_studying] where not(possible_schools contains_key each) {
				pair age_range <- activity_modifiers contains_key acts ? 
					pair(split_with(activity_modifiers[acts],SPLIT)) : pair(school_age::active_age); 
				possible_schools[acts] <- [int(age_range.key),int(age_range.value)];
			}
			//remove key: act_studying from:activities;
		}
		
		if activities contains_key act_working {
			loop actw over:activities[act_working] where not(possible_workplaces contains_key each) { 
				possible_workplaces[actw] <- activity_modifiers contains_key actw ? 
					float(activity_modifiers[actw]) : 1.0;
			}
			//remove key: act_working from:activities;
		}
		activities[act_friend] <- activities[act_home];
		return activities;
	}
}