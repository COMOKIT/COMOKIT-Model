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

import "Individual.gaml"

global {
	
	// TODO : turn it into parameters, more generaly it may require to smoothly init building attribute
	// from shape_file not using only OSM standard (might be the internal standard though), but relying also on custom bindings
	// i.e. make it possible to say : the feature "type" in my shapefile is "typo" and "school" are "kindergarden"
	string type_shp_attribute <- "type";
	string flat_shp_attribute <- "flats";
	
	
	map<string,list<Building>> build_buildings_per_function {
		list<string> all_building_functions <- remove_duplicates(Building accumulate(each.functions)); 
		if not("" in all_building_functions) {
			all_building_functions << "";
		}
		map<string,list<Building>> buildings_per_activity <- all_building_functions as_map (each::[]);
	 	ask Building {
	 		if empty(functions) {
	 			buildings_per_activity[""] << self;
	 		}else {
	 			loop fct over: functions {
					buildings_per_activity[fct] << self;
				} 
			}
		}
		loop v over: buildings_per_activity.values {
			v >> nil;
		}
		
		
		return buildings_per_activity;
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
	
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load when: allow_transmission_building and has_virus{
		float start <- BENCHMARK ? machine_time : 0.0;
		do decrease_viral_load(basic_viral_decrease/nb_step_for_one_day);
		has_virus <- viral_load.values one_matches (each > 0);
		if BENCHMARK {bench["Building.update_viral_load"] <- bench["Building.update_viral_load"] + machine_time - start; }
	}
}

species Building parent: AbstractPlace {
	int id;
	int index_bd;
	string zone_id;

	string fcts;
	//Building surrounding
	list<Building> neighbors;
	//Individuals present in the building
	list<Individual> individuals;
	//Number of households in the building
	int nb_households;
	 list<int> individuals_id;
	bool need_reinit <- false;
	list<list<list<list<list<Individual>>>>> entities_inside;
	list<list<list<list<list<int>>>>> entities_inside_int;
	list<Individual> indiviudals;
	int nb_currents  update: use_activity_precomputation and udpate_for_display and precomputation_loaded and not empty(entities_inside_int)?  length(entities_inside_int[current_week][current_day][current_hour] accumulate each) : 0;
	bool has_virus <- false;
	bool precomputation_loaded <- false;
	list<Individual> individuals_concerned;
	init {
		if (fcts != nil) {
			functions <- fcts split_with "$" ;
		}else {
			if ((shape get "type") != nil){
				functions << string(shape get "type") ; 
			} else {
				functions << "";
			}
			
		}
	
	}
	
	action compute_individuals_str{
		individuals_id <- entities_inside_int[current_week][current_day][current_hour] accumulate each;
		need_reinit <- true;
	}
	
	//Action to return the neighbouring buildings
	list<Building> get_neighbors {
		if empty(neighbors) {
			neighbors <- Building at_distance building_neighbors_dist;
			if empty(neighbors) {
				neighbors << Building closest_to self;
			}
		}
		return neighbors;
	}

	action compute_individuals{
		individuals <- entities_inside[current_week][current_day][current_hour] accumulate each;
		need_reinit <- true;
	}

	reflex reinit_individuals when: need_reinit  {
		individuals <- [];
		need_reinit <- false;
	}
	
	//Reflex to update disease cycle
	reflex transmission_building when: allow_transmission_building and use_activity_precomputation and has_virus {
		float start <- BENCHMARK ? machine_time : 0.0;
		if empty(individuals_id) {do compute_individuals_str;}
		list<int> inds <- copy(individuals_id where (individuals_precomputation[each] = nil));
		loop v over: viral_load.keys {
			float vl <- viral_load[v];
			loop id_ind over:inds  {
				if(flip(vl*successful_contact_rate_building)) {
					if not bot_abstract_individual_precomputation.is_immune(id_ind, v) {
						AbstractIndividual ind <- world.load_individual(id_ind);
						ask ind {do define_new_case(v);} 
					}
				}	
			}
		}
		if BENCHMARK {bench["Building.transmission_building"] <- bench["Building.transmission_building"] + machine_time - start;}
	}

	reflex reinit_individuals when: need_reinit  {
		individuals_id <- [];
		need_reinit <- false;
	}
	aspect default {
		draw shape color: #gray; //wireframe: true;
	}

}

/*
 * The species that represent outside of boundary dynamic : what agent do when the go outside
 * of the studied area, how they can be infected and what are their activities
 */
species outside parent: Building {
	
	string type <- "Outside";
	int nb_contaminated;
	
	bool is_active <- true; 	
	/*
	 * The action that will be called to mimic epidemic outside of the studied area
	 */
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
	
	reflex transmission_building{}
	
	//Reflex to trigger infection when outside of the commune
	reflex transmission_outside when: use_activity_precomputation and is_active and not empty(entities_inside_int){
		float start <- BENCHMARK ? machine_time : 0.0;
		if empty(individuals_id) {do compute_individuals_str;}
		list<int> inds <- copy(individuals_id where (individuals_precomputation[each] = nil));
		loop v over: proba_outside_contamination_per_hour.keys {
			float proba <- proba_outside_contamination_per_hour[v];
			loop id_ind over:inds  {
				if flip(proba) {
					if not bot_abstract_individual_precomputation.is_immune(id_ind, v) {
						AbstractIndividual ind <- world.load_individual(id_ind);
						ask ind {do define_new_case(v);} 
					}
				}	
			}
		}
		if BENCHMARK {bench["Building.transmission_outside"] <- bench["Building.transmission_outside"] + machine_time - start;}
	}
	reflex remove_if_not_necessary {}
}