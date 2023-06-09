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
	map<string, list<list>> current_groups;
	map<string,float> area_types;
	rgb color;
	int nb_individuals;
	int nb_infected;
	string id;
	int id_int;
	map<string, float> home_types_rates;
	action reset_pop {
		current_groups <- [];
		loop type over: area_types.keys {
			current_groups[type] <- [];
		}
	}
	
	action define_activity {
		ask compartments_inhabitants{
			do carry_out_activities;
		}
	} 
	
	action infect_others { 
		loop type over: current_groups.keys {
			list<list> groups <- current_groups[type];
			if not empty(groups) {
				float infected_factor <- groups sum_of float(each[2]);
				if (infected_factor > 0) {
					loop group over: groups {
						int nb_s <- int(group[1]);
						float rate_infection <-infected_factor / area_types[type] * float(group[3]) * float(group[5]) * ((type in building_type_infection_factor.keys) ? building_type_infection_factor[type] : 1.0);
						compartment my_compartment <-compartment(group[0]);
						int nb_new_infected <- world.rate_to_num(int(group[1]),rate_infection);
						
						ask my_compartment {do new_case(nb_new_infected);} 
						
					}
				}
			}
		}
	}
	
	action update_color {
		
		nb_infected <- compartments_inhabitants sum_of (each.group.num_asymptomatic + each.group.num_symptomatic + each.group.num_latent_asymptomatics + each.group.num_latent_symptomatics );
		float val <- nb_individuals = 0 ? -1 : (nb_infected / nb_individuals);
		if val = -1 {color <- #white;} else {color <- rgb(255 * val, 255 * (1 - val), 0);}
	}
	aspect default {
		draw shape color: color border: #black;
	}
}