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

import "../Parameters.gaml"

import "../Synthetic Population.gaml"


import "Individual.gaml"

global {
	
	Outside the_outside;
	
	// TODO : turn it into parameters, more generaly it may require to smoothly init building attribute
	// from shape_file not using only OSM standard (might be the internal standard though), but relying also on custom bindings
	// i.e. make it possible to say : the feature "type" in my shapefile is "typo" and "school" are "kindergarden"
	string type_shp_attribute <- "type";
	string flat_shp_attribute <- "flats";
	
	
	
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
species Outside parent: Building {
	
	string type <- "Outside";
	
	bool is_active <- true; 	
	/*
	 * The action that will be called to mimic epidemic outside of the studied area
	 */
	
	
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