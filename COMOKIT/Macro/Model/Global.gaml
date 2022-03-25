/**
* Name: anymodellevel
* Based on the internal skeleton template. 
* Author: admin_ptaillandie
* Tags: 
*/
@no_experiment
model anymodellevel

import "../../Core/Models/Entities/Virus.gaml"

import "Functions.gaml"




import "Parameters.gaml"

import "Entities/Spatial Unit.gaml"

import "Entities/Group.gaml"  


global { 
	
	geometry shape <-envelope(shape_file(shp_boundary_path));
	list<string> evol_state_order <- [SYMPTOMATIC, PRESYMPTOMATIC, ASYMPTOMATIC,LATENT_SYMPTOMATIC, LATENT_ASYMPTOMATIC];
	//The viral agent that infect this biological entity
	virus viral_agent;
	
	map<string,SpatialUnit> spatial_unit_per_code;
	map<string,compartment> compartment_per_code;
	
	action init_simulation { 
		do init_epidemiological_parameters;
		do init_sars_cov_2;
		viral_agent <- viruses first_with (each.name = variant);
		do create_spatial_unit;
		
		list<string> dt <- SpatialUnit accumulate (each.area_types.keys);
		ask group_individuals {
			do initialise_disease;
		}
		write "area created: " + length(SpatialUnit) +" " + length(compartment);
		if test_mode {
			do load_default_agenda;	
		} else {
			do load_agenda;
		}
		write sample(Activities);
		write "agenda loaded";
		ask SpatialUnit {
			nb_individuals <- compartments_inhabitants sum_of each.group.num_individuals;
		}
		
		loop times: nb_init_infected {
			ask one_of(SpatialUnit) {
				ask one_of(compartments_inhabitants) {
					do new_case(1); 
				}
			}
		}
		ask SpatialUnit {
			do update_color;
		}
	}
	
	action load_default_agenda {
		list<SpatialUnit> offices_sa <- (SpatialUnit where ("office" in each.area_types.keys));
		list<SpatialUnit> schools_sa <- (SpatialUnit where ("school" in each.area_types.keys));
		ask SpatialUnit {
			ask compartments_inhabitants {
				loop d from: 0 to: 6 {
					list<map<SpatialUnit,map<string,map<string,float>>>> act_d <- [];
					loop h from: 0 to: 23 {
						map<SpatialUnit,map<string,map<string,float>>> act_h <- [];
						float people_home_rate <- ((h < 8) or (h > 18)) ? 0.9 : 0.2 ;
						act_h[myself] <- [act_home:: ["home"::people_home_rate]];
						float other_people <- 1.0 - people_home_rate;
						if group.age > 18 {
							loop sp over: 2 among offices_sa {
								act_h[sp] <- [act_working::["office" :: (other_people/2)]];
							}
						} else {
							loop sp over: 2 among schools_sa {
								act_h[sp] <- [act_studying::["school" :: (other_people/2)]];
							}
						
						}
						act_d << act_h;
					}
					agenda << act_d;
				}
			}
		}	
		
		Activities <- [act_studying::nil, act_working::nil];
	}
	
	action load_agenda {
		list<string> activity_list;
		list<string> bd_type_list;
		ask SpatialUnit {
			ask compartments_inhabitants {
				loop d from: 0 to: 6 {
					list<map<SpatialUnit,map<string,map<string,float>>>> act_d <- [];
					loop h from: 0 to: 23 {
						act_d << [];
					}
					agenda << act_d;
				}
			}				
								
			string path_name <- agenda_path + id + ".data";
				bool activity_line_done <- false;
				bool bd_type_line_done <- false;
				loop line over:  file(path_name){
					if not activity_line_done {
						if empty(activity_list) {
							list<string> act_l <- line split_with "$$";
							activity_list <- act_l copy_between (1, length(act_l));
						}
						activity_line_done <- true;
					}
					else if not bd_type_line_done {
						if empty(bd_type_list) {
							list<string> bd_l <- line split_with "$$";
							bd_type_list <- bd_l copy_between (1, length(bd_l));
						}
						bd_type_line_done <- true;
					}
					else {
						list<string> ll <- line split_with (",");
							compartment comp <- compartment_per_code[ll[0]];
						if (comp != nil) {
							int d <- int(ll[1]);
							int h <- int(ll[2]);
										
							string agenda_str <- ll[3];
							
							ask comp {
								list<map<SpatialUnit,map<string,map<string,float>>>> act_d <- agenda[d];
								map<SpatialUnit,map<string, map<string,float>>> act_h <- act_d[h];
								loop agenda_str_z over: agenda_str split_with "%"  {
									map<string, map<string,float>> act_z <- [];
									list<string> tmp3 <- agenda_str_z split_with "@";
									SpatialUnit sp <- spatial_unit_per_code[tmp3[0]];
												
									if sp != nil {
										loop agenda_str_act over: tmp3[1] split_with "$"  {
											map<string,float> act_l <- [];
											list<string> tmp4 <- agenda_str_act split_with "+";
											if length(tmp4) > 1 {
												loop agenda_str_ty over: tmp4[1] split_with "="  {
													list<string> tmp5 <- agenda_str_ty split_with ":";
													act_l[bd_type_list[int(tmp5[0])]] <- float(tmp5[1]);
												}
												act_z[activity_list[int(tmp4[0])]] <- act_l;
											}
											act_h[sp] <- act_z;
										}
									}
								}
							}
						}
					}
			}
		}
		activity_list >> act_home;
		write sample(activity_list);
		Activities <-[];
		loop act over: activity_list {
			Activities[act] <- nil;
		}
	}
	action create_spatial_unit {
		activities <- init_building_type_parameters_fct(building_type_per_activity_parameters, possible_workplaces,possible_schools, school_age ,active_age) ;
	
		create SpatialUnit from: shape_file(shp_boundary_path) {
			spatial_unit_per_code[id] <- self;
			id_int <- int(id);
		}
		matrix mat <- matrix(csv_file(csv_boundary_path,",", true));
		loop i from: 0 to: mat.rows -1 {
			SpatialUnit s_unit <- spatial_unit_per_code[string(mat[0,i])];
		 	ask s_unit {
			 	area_types <- [];
				list<string> types <- string(mat[2,i]) split_with "$";
				loop t over: types {
					list<string> k_v <- t split_with "::";
					if (length(k_v) > 1) {
						
						area_types[k_v[0]] <- float(k_v[1]);
					
					}
				}
				
				loop t over: area_types.keys inter activities[act_home] {
					home_types_rates[t] <- area_types[t] ;
				}
				float sum_area <- sum(home_types_rates.values) ;
				loop t over: home_types_rates.keys{
					home_types_rates[t] <- home_types_rates[t] / sum_area ;
				}
				list<string> categories <- string(mat[1,i]) split_with "$";
				loop c over: categories {
					if c != nil and c != "" {
						list<string> k_v <- c split_with "::";
						if length(k_v) > 1 {
							list<string> id_int_str <- k_v[0] split_with "&&";
							int id_ <- int(id_int_str[0]);
							list<string> id_c <- id_int_str[1] split_with "%";
							create compartment {
								id <- id_;
								homeplace <- myself;
								area_id <- int(myself.id);
								create group_individuals with: (
									num_individuals:float(k_v[1]),
										sex:int(id_c[1]),
										age:int(id_c[0]),
										occupation:id_c[2],
										my_compartment:self
									) {
										myself.group <- self;
										num_susceptibles <- num_individuals;
									}
									myself.compartments_inhabitants << self;
							}		
						}
					}
				}
			}
		}
		compartment_per_code <- compartment as_map (each.id:: each);
	}
	
	reflex main_dynamic {
		
		float t <- machine_time;
		
		ask SpatialUnit {
			do reset_pop;
		}
		
		ask SpatialUnit {
			do define_activity;
		}
		
		ask SpatialUnit {
			do infect_others;
		}
		
		if every(#day) and cycle > 1{
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
		float t <- machine_time;
		//rate <- min(max(rate,0.0),1.0);
		float val_p <- num_tot * rate;
		int num <- int(val_p);
		if (val_p > num) {num <- min(num_tot, num + (flip(val_p - num) ? 1 : 0)) ;}	
		return num;
	}
}



