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
	
}

species Building {
	//Viral load of the building
	float viral_load <- 0.0;
	//Type of the building
	string type;
	//Building surrounding
	list<Building> neighbors;
	//Individuals present in the building
	list<Individual> individuals;
	//Number of households in the building
	int nb_households;
	 
	bool need_reinit <- false;
	list<list<list<list<list<Individual>>>>> entities_inside;
	list<Individual> indiviudals;
	int nb_currents  update: use_activity_precomputation and udpate_for_display ?  length(entities_inside[current_week][current_day][current_hour] accumulate each) : 0;
	
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
	
	//Action to add viral load to the building
	action add_viral_load(float value){
		if(allow_transmission_building)
		{
			viral_load <- min(1.0,viral_load+value);
		}
	}
	
	action compute_individuals{
		individuals <- entities_inside[current_week][current_day][current_hour] accumulate each;
		need_reinit <- true;
		
	}
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load when: allow_transmission_building{
		float start <- BENCHMARK ? machine_time : 0.0;
		viral_load <- max(0.0,viral_load - basic_viral_decrease/nb_step_for_one_day);
		if BENCHMARK {bench["Building.update_viral_load"] <- bench["Building.update_viral_load"] + machine_time - start; }
	}
	
	reflex reinit_individuals when: need_reinit  {
		individuals <- [];
		need_reinit <- false;
	}
	
	
	//Reflex to update disease cycle
	reflex transmission_building when: allow_transmission_building and use_activity_precomputation and viral_load > 0{
		float start <- BENCHMARK ? machine_time : 0.0;
		ask individuals {
			if(flip(current_place.viral_load*successful_contact_rate_building))
			{
				infected_by <- myself;
				do define_new_case();
			}
		}
		if BENCHMARK {bench["Building.transmission_building"] <- bench["Building.transmission_building"] + machine_time - start;}
	}
	
	
	aspect default {
		draw shape color: #gray wireframe: true;
	}

}

/*
 * The species that represent outside of boundary dynamic : what agent do when the go outside
 * of the studied area, how they can be infected and what are their activities
 */
species outside parent: Building {
	
	string type <- "Outside";
	int nb_contaminated;
	
	/*
	 * The action that will be called to mimic epidemic outside of the studied area
	 */
	action outside_epidemiological_dynamic(Individual indiv) {
		if flip(proba_outside_contamination_per_hour) { 
			ask indiv {
				do define_new_case;
				infected_by <- myself; 
				myself.nb_contaminated <- myself.nb_contaminated + 1;
			}
		}
	}
	
	//Reflex to trigger infection when outside of the commune
	reflex transmission_outside when: use_activity_precomputation{
		float start <- BENCHMARK ? machine_time : 0.0;
		loop i over: entities_inside[current_week][current_day][current_hour] accumulate each {
			do outside_epidemiological_dynamic(i);	
		}
		if BENCHMARK {bench["Building.transmission_outside"] <- bench["Building.transmission_outside"] + machine_time - start;}
	}
	
}