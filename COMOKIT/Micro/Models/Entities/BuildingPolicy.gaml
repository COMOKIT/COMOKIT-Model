/**
* * This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Build policies for hospital model 
* Author: dongh
* Tags: 
*/


model BuildingPolicy

import "Building Spatial Entities.gaml"

import "BuildingActivity.gaml"

import "BuildingIndividual.gaml"


global{
	action define_policies{
		loop i over: BuildingPolicy.subspecies{
			create i;
		}
	}
}

species BuildingPolicy virtual: true{
//	map<string, int> state_of_activities; 
	
	action apply virtual: true;
	
	bool is_allowed(BuildingIndividual p, BuildingActivity a) virtual: true;
}

species PolicyNONE parent: BuildingPolicy{
	
	action apply{
		// nothing here
	}
	
	bool is_allowed(BuildingIndividual p, BuildingActivity a){
		return true;
	}
}

species PolicyDetection parent: BuildingPolicy{
	action apply{
		// nothing here
	}
	
	bool is_allowed(BuildingIndividual p, BuildingActivity a){
		return true;
	}
}

species PolicyLockDownAll parent: BuildingPolicy{
	action apply{
		// nothing here
	}
	
	bool is_allowed(BuildingIndividual p, BuildingActivity a){
		return true;
	}
}

species PolicyLockDownPartly parent: BuildingPolicy{
	action apply{
		// nothing here
	}
	
	bool is_allowed(BuildingIndividual p, BuildingActivity a){
		return true;
	}
}


