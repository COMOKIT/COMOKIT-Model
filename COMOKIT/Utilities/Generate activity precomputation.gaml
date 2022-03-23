/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 2.0, July 2021. See http://comokit.org for support and updates
* 
* This model allows to generate files that can then be directly used for COMOKIT on the population, their agendas 
* and especially the activity precomputation that allows to benefit from the activity precomputation mode 
* (see models in Expermiments/Use of Activity precomputation). 
* In particular this model builds 3 types of files: 
*  - shapefile of individuals
*  - agenda file : agenda for each individual
*  - activity precomputation file : computes num_weeks types for each individual (with num_weeks a parameter) 
* 
* Author: Patrick Taillandier
* Tags: covid19,epidemiology, precomputation
******************************************************************/


model Generateactivityprecomputation


import "../Experiments/Abstract Experiment.gaml"
import "../Model/Global.gaml" 



global {
	//number of typical weeks to generate for the agents
	int num_weeks <- 2;
	
	//define here the policies for which to generate the precomputation file.	
	action generate_activity_files {
		float tolerance <- 0.05;
		ask Authority {
			do die;
		}

		create Authority {
			policy <- with_tolerance(create_lockdown_policy_except([act_home]), tolerance);
			ask policy {
				do apply;
				politic_is_active <- is_active();
			}

		}

		do save_activity_precomputation(dataset_path + precomputation_folder + "activity_lockdown_precomputation");
		ask Authority {
			do die;
		}

		create Authority {
			policy <- create_no_containment_policy();
			ask policy {
				do apply;
				politic_is_active <- is_active();
			}

		}

		do save_activity_precomputation(dataset_path + precomputation_folder + "activity_without_policy_precomputation");
	}
	
	geometry shape <- envelope(file_exists(shp_boundary_path) ?shape_file(shp_boundary_path) : shape_file(shp_buildings_path) );
	
	
	action after_init {
		write "number of buildings: " + length(Building);
		do generate_activity_files;
		do save_other_data;
	}
	
	
	action save_other_data {
		int ii<- 0;
		 ask all_buildings { 
		 	string functions_str <- "";
			if not empty(functions) {
				loop fct over: functions {
					functions_str <- functions_str +"," + fct; 
				}
			}
			string save_bd <-""+ ii+"," +  location.x + "," + location.y+functions_str; 
			save save_bd to: dataset_path + precomputation_folder +file_building_precomputation_path +"/"  +world.to_bd_id(self) + ".data" type: text ;
			ii <- ii + 1;
				
		} 
		//save "" type: text to: file_agenda_precomputation_path;
			
		ask individual_species {
			string to_save <- string (int(self)) + "!!";
			loop d over: agenda_week { 
				string day <- "";
				loop h over: d.keys {
					string act <- string(h) +"@@"+(d[h].key).name;
					loop ind over: d[h].value {
						act <- act + "," + int(ind);
					}
					day <- day +act + "$$";
				}
				to_save <- to_save +  day +"&&" ;
			}
			to_save <- to_save + "%%" + world.to_targets_id(building_targets);
			save to_save type: text to: dataset_path + precomputation_folder + file_agenda_precomputation_path + "/" + id_int + ".data" rewrite: true;
		}
	} 
	
	string to_targets_id(map<Activity, map<string,list<Building>>> building_targets) {
		if building_targets = nil or empty(building_targets){
			return "";
		}
		string ids <-"";
		loop act over: building_targets.keys {
			map<string,list<Building>> bds <- building_targets[act];
			string act_id <- act.name + "!!";
			loop t over: bds.keys {
				string for_type <-  t + "@@";
				loop b over: bds[t] {
					for_type <- for_type + to_bd_id(b) + ",,";
				}
				act_id <- act_id + for_type + "&&";
			}
			ids <- ids + act_id + "$$";
		}
		return ids;
	}
	
	action save_activity_precomputation(string path_file) {
			//save "" type: text to: path_file;
			ask all_individuals {
				buildings_concerned <- [];
			}
			do precompute_activities;
			int ii <- 0;
			ask all_buildings { 
				
				//bool need_to_save <- false;
				string to_save <- world.to_bd_id(self) + "|" ;
				loop w from: 0 to: length(entities_inside) - 1 {
					loop d from: 0 to: 6{
						loop h from: 0 to: 23 {
						list<list<Individual>> g <- entities_inside[w][d][h];
						if not empty(g accumulate each) {
							string g_str <- "";
							loop inds over: g {
									string gp <- "";
									loop e over: inds {
										gp <- gp + e.id_int+",";
									}
									if (gp != "") {
										//need_to_save <- true;
										g_str <- g_str + "$" + gp  ;
									}
									
								}
									
								to_save <- to_save + w + ";" + d + ";" + h + ";" + g_str + "&";
									
							}
						}
					}
				}
				//if (need_to_save) {
				//write sample(path_file +"/" + world.to_bd_id(self) +".data");
				save to_save type: text rewrite: true to: path_file +"/" + file_building_precomputation_path+"/" +world.to_bd_id(self) +".data";
				//}
			}	
			 
					
		ask individual_species {
			string path_of_file <- path_file  +"/"+ file_population_precomputation_path +"/" +id_int + ".data" ;
			string save_ind <-""+ id_int+"," +  location.x + "," + location.y+","+age+","+sex+"," +is_unemployed + ","+ factor_contact_rate_wearing_mask+ ","+proba_wearing_mask+ ","+vax_willingness+ ","+ free_rider+ ","+world.to_bd_id(home) +"," + world.to_bds_id(buildings_concerned);
			save save_ind to: path_of_file type: text ;
			string index_bd <- "";
			string index_group <- "";
			loop w from: 0 to: length(index_building_agenda) - 1 {
				loop d from: 0 to: 6 {
					loop h from: 0 to: 23 {
						index_bd <- index_bd + world.to_bd_id(index_building_agenda[w][d][h])+ ",";
						index_group <- index_group + index_group_in_building_agenda[w][d][h]+ ",";
					}
				}
			}
			index_bd <- index_bd copy_between (0, length(index_bd) - 1);
			index_group <- index_group copy_between (0, length(index_group) - 1);
			save index_bd to:path_of_file rewrite: false type: text ;
			save index_group to:path_of_file rewrite: false type: text ;
		}
	}
	
	
}

experiment "Precompute activities" parent: "Abstract Experiment"  {
	action _init_ {
		create simulation with: (use_activity_precomputation:false, num_infected_init: 0, nb_weeks_ref: num_weeks);
	}
}
