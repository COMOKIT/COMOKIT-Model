/**
* Name: anymodellevel
* Based on the internal skeleton template. 
* Author: admin_ptaillandie
* Tags: 
*/
@no_experiment
model anymodellevel

import "../Entities/Virus.gaml"

import "../Entities/Virus.gaml"


import "Parameters.gaml"

import "Entities/Spatial Unit.gaml"

import "Entities/Group.gaml"  


global {
	
	float step <- 1#h;
	date starting_date <- date([2022,2,14]);
	date ending_date <- date([2022,8,14]);
	
	list<string> evol_state_order <- [HOSPITALISATION, SYMPTOMATIC, PRESYMPTOMATIC, ASYMPTOMATIC,LATENT];
	//The viral agent that infect this biological entity
	virus viral_agent;
	
	
	//['Annexe','staying at home','working','shopping','charging_station','other activity','parking','Agricole','leisure and sport','school','grave_yard','detached','terrace','shelter','eating','social_facility','motocross','greenhouse','First necessity shoping','bicycle_parking','lavoir','post_box','fire_station','bunker','ruins','toilets','fort','fuel','roof','greengrocer','veterinary','cinema','kindergarten','service','public','parking_space','free_flying','health related activity','wayside_shrine','collapsed','funeral_directors','cycling','fountain','recycling','multi','bench','doityourself','semidetached_house','wine','laundry','parking_entrance','car_parts','office','hut','atm','barn','musical_instrument','bell','civic','drinking_water','hangar','monastery','gas','garden_centre','carport','archaeological_site','shed','soccer;basketball','newsagent','community_centre','jewelry','sports','university','farm','supermarket;convenience','cheese','sailing','convenience;gas','computer','farm_auxiliary','architect','dojo','telephone','handball','warehouse','wayside_cross','vacant','waste_basket','storage_tank','reception_desk','cowshed','crematorium']
	
	init { 
		
		do init_epidemiological_parameters;
		do init_sars_cov_2;
		viral_agent <- viruses first_with (each.name = variant);
		create SpatialUnit from: shape_file(shp_boundary_path)  {
			area_types <- [];// ["home"::shape.area / 10.0,"working_place"::shape.area / 10.0];
			list<string> types <- string(shape get ("types")) split_with "$";
			loop t over: types {
				list<string> k_v <- t split_with "::";
				if (length(k_v) > 1) {
					
					area_types[k_v[0]] <- float(k_v[1]);
				
				}
			}
			list<string> categories <- string(shape get ("categories")) split_with "$";
			loop c over: categories {
				if c != nil and c != "" {
					list<string> k_v <- c split_with "::";
					if length(k_v) > 1 {
						list<string> id_c <- k_v[0] split_with "%";
						create compartment {
							create group_individuals with: (
								num_suceptibles:float(k_v[1]),
									sex:int(id_c[1]),
									age:int(id_c[0]),
									occupation:id_c[2],
									my_compartment:self
								) {
									myself.group <- self;
								}
								myself.compartments_inhabitants << self;
						}		
					}
				}
			}
		}
		
		list<string> dt <- SpatialUnit accumulate (each.area_types.keys);
		write remove_duplicates(dt);
		ask group_individuals {
			//write sample(num_suceptibles);
		//	num_suceptibles <- round(1500000 / length(group_individuals));
			do initialise_disease;
		}
		write "area created: " + length(SpatialUnit) +" " + length(compartment);
		ask SpatialUnit {
			ask compartments_inhabitants {
				loop d from: 0 to: 6 {
					list<map<SpatialUnit,map<string,float>>> act_d <- [];
					loop h from: 0 to: 23 {
						map<SpatialUnit,map<string,float>> act_h <- [];
						int nb_people_home <- round(((h < 8) or (h > 18)) ? 0.9 : 0.2 * group.num_suceptibles);
						act_h[myself] <- ["staying at home":: nb_people_home];
						int other_people <- group.num_suceptibles - nb_people_home;
						act_h[one_of(SpatialUnit)] <- ["working":: other_people];
						
						act_d << act_h;
					}
					agenda << act_d;
				}
			}
			
			
			nb_individuals <- compartments_inhabitants sum_of each.group.num_suceptibles;
		}
		
		ask one_of(SpatialUnit) {
			ask one_of(compartments_inhabitants) {
				group.evol_states[SUSCEPTIBLE] <- group.evol_states[SUSCEPTIBLE] - nb_init_infected;
				group.evol_states[LATENT] <- group.evol_states[LATENT] + nb_init_infected;
			}
			
		}
		ask SpatialUnit {
			do update_color;
		}
	}
	
	reflex main_dynamic {
		ask SpatialUnit {
			do reset_pop;
		}
		ask SpatialUnit {
			do define_activity;
		}
		ask SpatialUnit {
			do infect_others;
		}
		if every(#day) {
			ask group_individuals {
				do evolution_state;
			}
		}
		ask SpatialUnit {
			do update_color;
		}
		
	}
	
	reflex end when: starting_date >= ending_date {
		do pause;
	}
	
	int rate_to_num(int num_tot, float rate) {
		float val_p <- num_tot * rate;
		int num <- int(val_p);
		if (val_p > num) {num <- min(num_tot, num + (flip(val_p - num) ? 1 : 0)) ;}	
		return num;
	}
}



