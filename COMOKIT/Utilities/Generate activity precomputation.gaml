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
		ask Authority {do die;}
		create Authority {
			policy <- with_tolerance(create_lockdown_policy_except([act_home]),tolerance);
			ask policy {
				do apply;
				politic_is_active <- is_active();
			}
		}
		do save_activity_precomputation(dataset_path+ precomputation_folder + "activity_lockdown_precomputation.data");	
		
		ask Authority {do die;}
		create Authority {
			policy <- create_no_containment_policy();
			ask policy {
				do apply;
				politic_is_active <- is_active();
			}
		}
		
		do save_activity_precomputation(dataset_path+ precomputation_folder + "activity_without_policy_precomputation.data");
	
		
	}
	
	geometry shape <- envelope(shp_buildings);
	
	
	action after_init {
		do generate_activity_files;
		do save_other_data;
	}
	
	action save_other_data {
		save individual_species to: file_population_precomputation_path type: shp attributes:["age"::age,
								"sex"::sex,
								"is_unempl"::is_unemployed,
								"id"::individual_id,
								"h_id"::household_id,
								"home_id"::world.to_bd_id(home),
								"school_id"::world.to_bd_id(school),
								"wp_id"::world.to_bd_id(working_place),
								"rel_id":: world.to_inds_id(relatives),
								"friends_id":: world.to_inds_id(friends),
								"col_id":: world.to_inds_id(colleagues)
								];
		 
		save "" type: text to: file_agenda_precomputation_path;
		
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
			save to_save type: text to: file_agenda_precomputation_path rewrite: false;
		}
	} 
	
	action save_activity_precomputation(string path_file) {
			save "" type: text to: path_file;
			do precompute_activities;
			ask all_buildings { 
				bool need_to_save <- false;
				string to_save <- world.to_bd_id(self) + "|" ;
				loop w from: 0 to: length(entities_inside) - 1 {
					loop d from: 0 to: 6{
						loop h from: 0 to: 23 {
						list<list<BiologicalEntity>> g <- entities_inside[w][d][h];
						if not empty(g accumulate each) {
							string g_str <- "";
							loop inds over: g {
									string gp <- "";
									loop e over: inds {
										gp <- gp + int(e)+",";
									}
									if (gp != "") {
										need_to_save <- true;
										g_str <- g_str + "$" + gp  ;
									}
									
								}
									
								to_save <- to_save + w + ";" + d + ";" + h + ";" + g_str + "&";
									
							}
						}
					}
				}
				
				if (need_to_save) {
					save to_save type: text rewrite: false to: path_file;
				}
			}	
	}
	
	string to_inds_id(list<Individual> inds) {
		if inds = nil or empty(inds){
			return "";
		}
		string ids <-"";
		loop i over: inds {
			ids <- ids + int(i) + ",";
		}
		return ids;
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
}

experiment "Precompute activities" parent: "Abstract Experiment"  {
	action _init_ {
		create simulation with: (use_activity_precomputation:false, load_activity_precomputation_from_file: false, num_infected_init: 0, nb_weeks_ref: num_weeks);
	}
}
