/**
* Name: Area
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

@no_experiment

model SpatialUnit

import "../Global.gaml"
 

species SpatialUnit {
	list<compartment> compartments_inhabitants ;
	map<string, list<group_individuals_simple>> current_groups;
	map<string,float> area_types;
	rgb color;
	int nb_individuals;
	int nb_infected;
	string id;
	
	action reset_pop {
		loop type_gps over: current_groups.values {
			ask type_gps {do die;}
		}
		current_groups <- []; 
	}
	
	action define_activity {
		ask compartments_inhabitants{
			do carry_out_activities;
		}
	}
	
	action infect_others { 
		loop type over: current_groups.keys {
			list<group_individuals_simple> groups <- current_groups[type];
			float infected_factor <- groups sum_of each.infection_val();
			if (infected_factor > 0) {
				ask groups {
					float rate_infection <-infected_factor / myself.area_types[type] * contact_rate;
					int nb_su <- evol_states[SUSCEPTIBLE];
					int nb_new_infected <- min(my_compartment.group.evol_states[SUSCEPTIBLE][0], world.rate_to_num(nb_su,rate_infection));
					my_compartment.group.evol_states[SUSCEPTIBLE][0] <- my_compartment.group.evol_states[SUSCEPTIBLE][0] - nb_new_infected;
					my_compartment.group.evol_states[LATENT][0] <- my_compartment.group.evol_states[LATENT][0]+ nb_new_infected;
					
				}
			}
		}
	}
	
	action update_color {
		ask compartments_inhabitants {
			group.num_infected <- sum(group.evol_states[LATENT]) + sum(group.evol_states[PRESYMPTOMATIC]) + sum(group.evol_states[ASYMPTOMATIC]) + sum(group.evol_states[SYMPTOMATIC]) + sum(group.evol_states[HOSPITALISATION]) + sum(group.evol_states[ICU]);
			group.num_suceptibles <- (group.evol_states[SUSCEPTIBLE][0]);	
		}
		nb_infected <- compartments_inhabitants sum_of (each.group.num_infected);
		float val <- nb_individuals = 0 ? -1 : (nb_infected / nb_individuals);
		if val = -1 {color <- #white;} else {color <- rgb(255 * val, 255 * (1 - val), 0);}
	}
	aspect default {
		draw shape color: color border: #black;
	}
}