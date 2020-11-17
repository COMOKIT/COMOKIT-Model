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

species Building schedules:shuffle(Building where (each.building_schedule)) {
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
	
	// attribute that tells if the building needs to be schedul
	bool building_schedule <- allow_transmission_building and viral_load > 0.0 ? true : false; 
	
	//---------//
	// ACTIONS //
	
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
	
	//----------//
	// REFLEXES //
	
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load when: allow_transmission_building {
		float start <- BENCHMARK ? machine_time : 0.0;
		viral_load <- max(0.0,viral_load - basic_viral_decrease/nb_step_for_one_day);
		building_schedule <- viral_load > 0 ? true : false;
		if BENCHMARK {bench["Building.update_viral_load"] <- bench["Building.update_viral_load"] + machine_time - start; }
	}
	
	/*
	 * Replace the infectious spreading by susceptible getting infected with building based monitoring of the process <br/>
	 * WARNING : alternative transmission process
	 */
	reflex infect_occupants when: BUILDING_TRANSMISSION_STRATEGY {
		float start <- machine_time;
		// List of susceptible and infectious agents
		list<Individual> agent_infectious <- individuals where (each.is_infectious);
		list<Individual> agent_susceptibles <- individuals where (each.state = susceptible);
		if empty(agent_infectious) or empty(agent_susceptibles) {
			building_schedule <- false;
		} else {
			if INVERSE_PROBABILITY {
				loop i over:agent_infectious {
					// probability of an interaction with i to lead to an infection
					float i_proba <- i.contact_rate * i.viral_factor * 
						(i.is_wearing_mask ? i.factor_contact_rate_wearing_mask : 1) *
						(i.is_asymptomatic ? i.factor_contact_rate_asymptomatic : 1);
					
					// Close interactions
					list<Individual> close_susceptibles <- agent_susceptibles where (remove_duplicates(i.relatives+i.activity_fellows) contains each);
					
					// Probability that none of the close interactions lead to an infection
					float i_inverse_close <- (1 - i_proba) ^ length(close_susceptibles); 
					loop while:not(flip(i_inverse_close)) and not(empty(close_susceptibles)) {
						ask any(close_susceptibles) {
							close_susceptibles >- self;
							agent_susceptibles >- self;
							do define_new_case;
							infected_by <- i;
						}
						i.number_of_infected_individuals <- i.number_of_infected_individuals + 1;
					}
					
					// loose interactions
					float i_inverse_other <- (1 - i_proba * (i.is_at_home ? reduction_coeff_all_buildings_inhabitants : reduction_coeff_all_buildings_individuals)) 
						^ (length(agent_susceptibles) - length(close_susceptibles));
					loop while:not(flip(i_inverse_other)) and not(empty(agent_susceptibles)) {
						ask any(agent_susceptibles) {
							agent_susceptibles >- self;
							do define_new_case;
							infected_by <- i;
						}
						i.number_of_infected_individuals <- i.number_of_infected_individuals + 1; 
					}
				}
			} else {
				// Computed factor of infectious, with mask and asymptomatic reduction factors
				map<Individual,list<float>> infectious_individuals <- agent_infectious as_map (each::
					[each.contact_rate,each.viral_factor,
						(each.is_wearing_mask ? each.factor_contact_rate_wearing_mask : 1.0),
						(each.is_asymptomatic ? each.factor_contact_rate_asymptomatic : 1)
					]
				);
				
				// Probability for a susceptible to be infected
				list<float> probas <- [];
				loop i over:infectious_individuals.keys {
					probas <+ infectious_individuals[i][0] * infectious_individuals[i][1] * infectious_individuals[i][2] * infectious_individuals[i][3];
				}
				
				// Infection process
				loop i over: agent_susceptibles {
					
					int iter <- 0;
					loop while:iter<length(agent_infectious) {
						// TODO : understand why it is possible to manipulate list<Individual> but not direct reference to an Individual
						list<Individual> infectious_one <- [agent_infectious[iter]];
						
						float relationshipfactor <- (i.relatives+i.activity_fellows) contains first(infectious_one) ? 1 :
							(i.is_at_home ? reduction_coeff_all_buildings_inhabitants : reduction_coeff_all_buildings_individuals);
						
						if flip(probas[iter]*relationshipfactor) {
							ask i {
								// TODO : understand why it turns the model impossible to launch
								/*ask infectious_one {do infect_someone(i);} */
								/*do infected_by_someone(first(infectious_one));*/
								do define_new_case;
								infected_by <- first(infectious_one);
							} 
							first(infectious_one).number_of_infected_individuals <- first(infectious_one).number_of_infected_individuals + 1; 
							iter <- length(agent_infectious);
						} else {
							iter <- iter+1;
						}
						
					}
					
				}
			}
		}
		bench["Building.infect_occupants"] <- bench["Building.infect_occupants"] + machine_time - start; 
	}
	
	//---------------//
	// VISUALIZATION //

	aspect default {
		draw shape color: #gray empty: true;
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
	
}