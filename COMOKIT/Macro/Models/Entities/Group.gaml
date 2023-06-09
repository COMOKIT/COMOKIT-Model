/**
* Name: Group
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


@no_experiment
model Group

import "../../../Core/Models/Entities/Authority.gaml"

import "../Global.gaml"  
 

species group_individuals { 
	compartment my_compartment; 
	int num_individuals;  
	int age;
	int sex; 
	string occupation;
	map<string,list<int>> evol_states;
	
	int num_susceptibles;
	int num_symptomatic;
	int num_asymptomatic;
	int num_latent_asymptomatics;
	int num_latent_symptomatics;
	int num_recovered;
	int num_dead;
	int num_icu;
	int num_hospitalisation;
	int num_immune;
	int num_isolated_infected;
	int num_isolated_non_infected;
	
	float immunity_evasion_rate;
	int latent_period_asymptomatic;
	int latent_period_symptomatic;
	int presymptomatic_period;
	int hospitalisation_period;
	int icu_period;
	int infectious_period_symptomatic;
	int infectious_period_asymptomatic; 
	float rate_symptomatic;
	float rate_hospitalisation;
	float rate_dead;
	float rate_icu;
	float factor_contact_rate_asymptomatic;
	float contact_rate;
	

	
	//Initialise epidemiological parameters according to the age of the Entity
	action initialise_disease {
		// Virus dependant 
		BiologicalEntity proto_entity;
		create BiologicalEntity with:(age :age) {
			proto_entity <- self;
		}
		
		list<float> list_factor_contact_rate_asymptomatic;
		list<float> list_contact_rate;
		list<float> list_latent_period_asymptomatique;
		list<float> list_latent_period_symptomatique;
		list<float> list_presymptomatic_period;
		list<float> list_infectious_period_symptomatic;
		list<float> list_infectious_period_asymptomatic;
		
		list<float> list_rate_symptomatic;
		list<float> list_rate_hospitalisation;
		list<float> list_rate_icu;
		list<float> list_rate_dead;
		list<float> list_period_hospitalisation;
		list<float> list_period_icu;
		
		list<float> list_immunity_evasion;
		 
		loop times: num_replication_parameters {
			list_factor_contact_rate_asymptomatic << viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_factor_asymptomatic);
			list_contact_rate << viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_successful_contact_rate_human) * density_ref_contact;
			
			list_latent_period_asymptomatique<< viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_incubation_period_asymptomatic);
			list_latent_period_symptomatique<< viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_incubation_period_symptomatic);
			list_presymptomatic_period<<viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_serial_interval);
			list_infectious_period_asymptomatic << viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_infectious_period_asymptomatic );
			list_infectious_period_symptomatic << viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_infectious_period_symptomatic );
		
			list_rate_symptomatic<< 1.0 - viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_asymptomatic);
			list_rate_hospitalisation<< viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_hospitalisation);
			list_rate_icu<< viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_icu);
			list_rate_dead<< viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_death_symptomatic);
			list_period_hospitalisation << viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_stay_Hospital);
			list_period_icu << viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_stay_ICU);
			list_immunity_evasion << viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_immune_evasion);
		}
		
		factor_contact_rate_asymptomatic <- mean(list_factor_contact_rate_asymptomatic);
		contact_rate <- mean(list_contact_rate);
		latent_period_asymptomatic<- max(1,round(mean(list_latent_period_asymptomatique) / nb_step_for_one_day));
		latent_period_symptomatic<- max(1,round(mean(list_latent_period_symptomatique) / nb_step_for_one_day));
		presymptomatic_period<- max(1,round(mean(list_presymptomatic_period)/nb_step_for_one_day));
		infectious_period_symptomatic <- max(1,round(mean(list_infectious_period_symptomatic)/ nb_step_for_one_day));
		infectious_period_asymptomatic <- max(1,round(mean(list_infectious_period_asymptomatic)/ nb_step_for_one_day));
		rate_symptomatic<-mean(list_rate_symptomatic);
		rate_hospitalisation<- mean(list_rate_hospitalisation);
		rate_icu<- mean(list_rate_icu);
		rate_dead<- mean(list_rate_dead);
		hospitalisation_period <- max(1,round(mean(list_period_hospitalisation)));
		icu_period <- max(1,round(mean(list_period_icu)));
		immunity_evasion_rate <- mean(list_immunity_evasion);
		
		ask proto_entity {
			do die;
		}
		evol_states[SUSCEPTIBLE] <- [num_individuals];
		evol_states[DEAD] <- [0.0];
		evol_states[REMOVED] <- [0.0];
		evol_states[LATENT_SYMPTOMATIC] <- [];
		evol_states[LATENT_ASYMPTOMATIC] <- [];
		evol_states[ICU] <- [];
		evol_states[HOSPITALISATION] <- [];
		
		loop times: latent_period_symptomatic {
			evol_states[LATENT_SYMPTOMATIC]<<0.0; 
		}
		loop times: latent_period_asymptomatic {
			evol_states[LATENT_ASYMPTOMATIC]<<0.0; 
		}
		evol_states[PRESYMPTOMATIC] <- [];
		
		loop times: presymptomatic_period {
			evol_states[PRESYMPTOMATIC]<<0.0; 
		}
		evol_states[ASYMPTOMATIC] <- [];
		evol_states[SYMPTOMATIC] <- [];
		
		loop times: infectious_period_symptomatic {
			evol_states[SYMPTOMATIC]<<0.0; 
		}
		loop times: infectious_period_asymptomatic {
			evol_states[ASYMPTOMATIC]<<0.0; 
		}
		
		loop times: icu_period {
			evol_states[ICU] << 0.0;
		}
		
		loop times: hospitalisation_period {
			evol_states[HOSPITALISATION] << 0.0;
		}
		
		
	}
	
	
	
	action evolution_state {
		list<string> states <- copy(evol_state_order);
		if (num_symptomatic = 0) {states>> SYMPTOMATIC;}
		if (num_asymptomatic = 0) {states>> ASYMPTOMATIC;}
		if (num_icu = 0) {states>> ICU;}
		if (num_hospitalisation = 0) {states>> HOSPITALISATION;}
	
		//if (num_latent_asymptomatics = 0) {states>> LATENT_ASYMPTOMATIC; states >> PRESYMPTOMATIC;}
		if (num_latent_symptomatics = 0) {states>> LATENT_SYMPTOMATIC;}
		if not empty(states) {
			loop s over: states {
				list<int> day_s <- evol_states[s];
				if  length(day_s) > 1 {
					loop i from: 0 to: length(day_s) - 2  {
						int index <- length(day_s) - (i+1);
						day_s[index] <- day_s[index] + day_s[index-1];
						day_s[index - 1] <- 0;
					}
				}
				int val <- day_s[length(day_s) - 1] ;
				if val > 0 {
					day_s[length(day_s) - 1] <- 0;
					switch s {
						match LATENT_SYMPTOMATIC {
							evol_states[PRESYMPTOMATIC][0] <- val;
							num_asymptomatic <-num_asymptomatic + val;
							num_latent_symptomatics <- num_latent_symptomatics - val;
						}
						match LATENT_ASYMPTOMATIC {
							evol_states[ASYMPTOMATIC][0] <- val;
							num_asymptomatic <-num_asymptomatic + val;
							num_latent_asymptomatics <- num_latent_asymptomatics - val;
						}
						match PRESYMPTOMATIC {
							evol_states[SYMPTOMATIC][0] <- val;
							num_asymptomatic <-num_asymptomatic - val;
							num_symptomatic <-num_symptomatic + val;
						}
						match ASYMPTOMATIC {
							if allow_reinfection {
								evol_states[SUSCEPTIBLE][0] <- evol_states[SUSCEPTIBLE][0]  + val;
								num_susceptibles<- num_susceptibles + val ;
								num_immune <- num_immune + val;
							} else {
								evol_states[REMOVED][0] <- evol_states[REMOVED][0]  + val;
								num_recovered <- num_recovered + val ;
							
							}
							num_asymptomatic <-num_asymptomatic - val;
							
						}
						match SYMPTOMATIC {
							num_symptomatic <-num_symptomatic - val;
							int nb_hospitalisation <- world.rate_to_num(val,rate_hospitalisation);
							int nb_re <- val -nb_hospitalisation;
							int nb_icu <- min(nb_re, world.rate_to_num(val,rate_icu));
							nb_re <- nb_re - nb_icu;
							int nb_dead <- min (nb_re, world.rate_to_num(val,rate_dead));
							if nb_icu > hospital_icu_capacity {
								nb_dead <- nb_dead + nb_icu - hospital_icu_capacity;
								nb_icu <- hospital_icu_capacity;
							}
							hospital_icu_capacity<- hospital_icu_capacity - nb_icu;
							
							int nb_removed <- nb_re - nb_dead;
							
							evol_states[HOSPITALISATION][0] <- evol_states[HOSPITALISATION][0] + nb_hospitalisation;	
							evol_states[ICU][0] <- evol_states[ICU][0] + nb_icu;
							evol_states[DEAD][0] <- evol_states[DEAD][0] + nb_dead;
							
							if allow_reinfection {
								evol_states[SUSCEPTIBLE][0] <- evol_states[SUSCEPTIBLE][0]  + nb_removed;
								num_immune <- num_immune + nb_removed;
								num_susceptibles<- num_susceptibles + nb_removed ;
							} else {
								evol_states[REMOVED][0] <-  evol_states[REMOVED][0]  + nb_removed;
								num_recovered <- num_recovered + nb_removed;
							}
							num_dead <- num_dead + nb_dead;
							
						}
						match ICU {
							num_icu <- num_icu - val;
							if allow_reinfection {
								evol_states[SUSCEPTIBLE][0] <- evol_states[SUSCEPTIBLE][0]  + val;
								num_immune <- num_immune + val;
								num_susceptibles<- num_susceptibles + val ;
							} else {
								evol_states[REMOVED][0] <- evol_states[REMOVED][0] + val ;
								num_recovered <- num_recovered + val;
							}
							hospital_icu_capacity<- hospital_icu_capacity + val;
							
						}
						match HOSPITALISATION {
							num_hospitalisation <- num_hospitalisation - val;
							if allow_reinfection {
								evol_states[SUSCEPTIBLE][0] <- evol_states[SUSCEPTIBLE][0]  + val;
								num_susceptibles<- num_susceptibles + val ;
								num_immune <- num_immune + val;
							} else {
								evol_states[REMOVED][0] <- evol_states[REMOVED][0] + val ;
								num_recovered <- num_recovered + val;
							}
							
						}
					}
				}
			}
			
		}
	}
	
}

species compartment {
	
	int id;
	group_individuals group;
	list<list<map<SpatialUnit,map<string,map<string,float>>>>> agenda;
	int area_id;
	SpatialUnit homeplace;
	
	int num_individuals {
		int nb <- 0;
		loop o over: group.evol_states.values {
			nb <- nb + sum(o);
		}
		return nb;
	}
	
	list create_group (float coeff_susceptible, float coeff_infected){
		int num_symptomatic <- world.rate_to_num(group.num_symptomatic,coeff_infected );
		int num_asymptomatic <- world.rate_to_num(group.num_asymptomatic,coeff_infected );
		int num_susceptibles <- world.rate_to_num(group.num_susceptibles,coeff_susceptible );
		float immune_rate <- 1.0 - (group.num_immune / group.num_individuals * group.immunity_evasion_rate);
		int nb_individuals <- (num_symptomatic + num_asymptomatic + num_susceptibles);
		if (nb_individuals) = 0 {return [];}
		float factor_mask <- (factor_contact_rate_wearing_mask * ( 2 - mask_ratio));
		float infection_factor <-  (num_symptomatic + (num_asymptomatic * group.factor_contact_rate_asymptomatic)) * factor_mask;
		list group_ <- [self,num_susceptibles,infection_factor,group.contact_rate, group.rate_symptomatic,immune_rate,nb_individuals];
		return group_;
	}
	
	action carry_out_activities {
		map<SpatialUnit,map<string,map<string,float>>> agenda_hour <- agenda[current_date.day_of_week - 1][current_date.hour];
		if agenda_hour != nil {
			float tot <- 0.0;
			loop a over: agenda_hour.keys {
				map<string,map<string,float>> ag_act <- agenda_hour[a];
				loop activity_type over: ag_act.keys{
					map<string,float> bd_act <- ag_act[activity_type];
					int numAllowed <- 0;
					int numTot;
					tot<- tot + sum(bd_act.values);
					loop bd_type over: bd_act.keys{
						float coeff <-bd_act[bd_type];
						float tested_susceptible <- 0.0;//num_tested_;
						float tested_infected;
						
						list<float> allow_rate <- Authority[0].allows_rate (area_id, a.id_int, activity_type, bd_type, tested_susceptible, tested_infected);
						if (sum(allow_rate) < 2.0) {
							loop type_h over: homeplace.home_types_rates.keys {
								list gp <- create_group(homeplace.home_types_rates[type_h] * coeff*(1.0 - allow_rate[0]),coeff*(1.0 - allow_rate[1]));
								if not empty(gp){
									homeplace.current_groups[type_h]<< gp; 
									numTot<- numTot + int(last(gp));
								}
							}
						}
						if sum(allow_rate) > 0.0 {
							list gp <- create_group(coeff*allow_rate[0],coeff*allow_rate[1]);
							if not empty(gp){
								numAllowed <- numAllowed + int(last(gp));
								numTot<- numTot + int(last(gp));
								a.current_groups[bd_type]<< gp; 
							}
						}
					}
					ask Authority {
						do update_monitor_rate(activity_type,numTot,numAllowed );
					}
						 
				}
			}  
		}
	}
	
	action new_case(int num_new_cases){ 
		
		num_new_cases <- min(num_new_cases, group.evol_states[SUSCEPTIBLE][0] );
		group.num_susceptibles <-group.num_susceptibles - num_new_cases;
		group.evol_states[SUSCEPTIBLE][0] <- group.evol_states[SUSCEPTIBLE][0] - num_new_cases;
		int nb_symptomatics <- world.rate_to_num(num_new_cases,group.rate_symptomatic);
		group.num_latent_symptomatics <- group.num_latent_symptomatics + nb_symptomatics;
		int nb_asymptomatics <- num_new_cases - nb_symptomatics;
		group.num_latent_asymptomatics <- group.num_latent_asymptomatics + nb_asymptomatics;
		group.evol_states[LATENT_SYMPTOMATIC][0] <- group.evol_states[LATENT_SYMPTOMATIC][0] + nb_symptomatics;
		group.evol_states[LATENT_ASYMPTOMATIC][0] <- group.evol_states[LATENT_ASYMPTOMATIC][0] + nb_asymptomatics;
		
	}
}