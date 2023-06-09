/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Buildings represent in COMOKIT spatial entities where Individuals gather 
* to undertake their Activities. They are provided with a viral load to
* enable environmental transmission. 
* 
* Author: Huynh Quang Nghi, Benoit Gaudou, Damien Philippon, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment
 
model CoVid19

import "Abstract Individual.gaml"  

global { 
	
	map<string,list<AbstractPlace>> build_buildings_per_function {
		list<string> all_places_functions <- remove_duplicates((agents of_generic_species AbstractPlace) accumulate(each.functions)); 
		if not("" in all_places_functions) {
			all_places_functions << "";
		}
		map<string,list<AbstractPlace>> places_per_activity <- all_places_functions as_map (each::[]);
	 	ask agents of_generic_species AbstractPlace {
	 		if empty(functions) {
	 			places_per_activity[""] << self;
	 		}else {
	 			loop fct over: functions {
					places_per_activity[fct] << self;
				} 
			}
		}
		loop v over: places_per_activity.values {
			v >> nil;
		}
		
		
		return places_per_activity;
	}
}

species AbstractPlace virtual: true {

	int id_int;
	//Viral load of the building
	map<virus,float> viral_load <- [original_strain::0.0];
	bool has_virus <- false;
	//Type of the building
	string type;
	//Usages of the building
	list<string> functions;
	bool allow_transmission -> {allow_transmission_building};
	bool has_ventilation <- false;

	int nb_contaminated;
	//Action to add viral load to the building
		//Action to add viral load to the building
	action add_viral_load(float value, virus v <- original_strain){
		if(allow_transmission_building)
		{
			viral_load[v] <- min(1.0,viral_load[v]+value);
			has_virus <- true;
		}
	}
	
	
	action decrease_viral_load(float val) {
		loop v over:viral_load.keys {
			viral_load[v] <- max(0.0,viral_load[v] - val);
		}
	}
	
	action outside_epidemiological_dynamic(AbstractIndividual indiv, float period_duration) {
		loop v over:proba_outside_contamination_per_hour.keys {
			if flip(proba_outside_contamination_per_hour[v] / #h * period_duration) { 
				ask indiv {
					infectious_contacts_with[myself] <- define_new_case(v); 
					if infectious_contacts_with[myself] {myself.nb_contaminated <- myself.nb_contaminated + 1;}
				}
			}
		}
	}
	
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load when: allow_transmission_building and has_virus{
		float start <- BENCHMARK ? machine_time : 0.0;
		float viral_decrease <- basic_viral_decrease;
		if has_ventilation {viral_decrease <- viral_decrease + ventilation_viral_decrease;}
		do decrease_viral_load(viral_decrease/nb_step_for_one_day);
		has_virus <- viral_load.values one_matches (each > 0);
		if BENCHMARK {bench["Building.update_viral_load"] <- bench["Building.update_viral_load"] + machine_time - start; }
	}
}