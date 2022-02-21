/**
* Name: Group
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


@no_experiment
model Group

import "../Global.gaml" 


species group_individuals {
	compartment my_compartment; 
	int num_suceptibles;
	int num_infected<- 0;
	
	int age;
	int sex; 
	string occupation;
	map<string,list<int>> evol_states;
	int latent_period;
	int presymptomatic_period;
	int infectious_period;
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
		
		factor_contact_rate_asymptomatic <- viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_factor_asymptomatic);
		contact_rate <- viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_successful_contact_rate_human) * density_ref_contact;
		latent_period<- 3;//max(1,round(viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_incubation_period_asymptomatic) / 24));
		presymptomatic_period<- 2;// max(1,round(viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_serial_interval) / 24));
		infectious_period<-  5;//max(1,round(viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_infectious_period_symptomatic) / 24));
		
		rate_symptomatic<- 1.0 - viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_asymptomatic);
		rate_hospitalisation<- viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_hospitalisation);
		rate_icu<- viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_icu);
		rate_dead<- viral_agent.get_value_for_epidemiological_aspect(proto_entity,epidemiological_proportion_death_symptomatic);
		
		ask proto_entity {
			do die;
		}
		evol_states[SUSCEPTIBLE] <- [num_suceptibles];
		evol_states[HOSPITALISATION] <- [0.0];
		evol_states[DEAD] <- [0.0];
		evol_states[ICU] <- [0.0];
		evol_states[REMOVED] <- [0.0];
		evol_states[LATENT] <- [];
		loop times: latent_period {
			evol_states[LATENT]<<0.0; 
		}
		evol_states[PRESYMPTOMATIC] <- [];
		
		loop times: presymptomatic_period {
			evol_states[PRESYMPTOMATIC]<<0.0; 
		}
		evol_states[ASYMPTOMATIC] <- [];
		evol_states[SYMPTOMATIC] <- [];
		
		loop times: infectious_period {
			evol_states[ASYMPTOMATIC]<<0.0; 
			evol_states[SYMPTOMATIC]<<0.0; 
		}
	}
	
	action evolution_state {
		loop s over: evol_state_order {
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
					match LATENT {
						int nb_symptomatics <- world.rate_to_num(val,rate_symptomatic);
						int nb_asymptomatics <- val - nb_symptomatics;
						evol_states[PRESYMPTOMATIC][0] <- nb_symptomatics;
						evol_states[ASYMPTOMATIC][0] <- nb_asymptomatics;
					}
					match PRESYMPTOMATIC {
						evol_states[SYMPTOMATIC][0] <- val;
					}
					match ASYMPTOMATIC {
						evol_states[REMOVED][0] <- evol_states[REMOVED][0]  + val;
					}
					match SYMPTOMATIC {
						int nb_hospitalisation <- world.rate_to_num(val,rate_hospitalisation);
						int nb_icu <- world.rate_to_num(val,rate_icu);
						int nb_dead <- world.rate_to_num(val,rate_dead);
						
						int nb_removed <- val - nb_hospitalisation - nb_dead - nb_icu;
						evol_states[HOSPITALISATION][0] <- nb_hospitalisation;
						evol_states[DEAD][0] <- nb_dead;
						evol_states[REMOVED][0] <-  evol_states[REMOVED][0]  + val;
					}
				}
			}
			
		}
	}
	
}

species group_individuals_simple {
	compartment my_compartment;
	map<string,int> evol_states;
	float mask_ratio;
	float factor_contact_rate_asymptomatic;
	
	float contact_rate;
	float infection_val {
		float factor_mask <- (factor_contact_rate_wearing_mask * ( 2 - mask_ratio));
		return (evol_states[SYMPTOMATIC] + (evol_states[ASYMPTOMATIC] + evol_states[PRESYMPTOMATIC]) * factor_contact_rate_asymptomatic * factor_mask);
	}
}

species compartment {
	group_individuals group;
	list<list<map<SpatialUnit,map<string,float>>>> agenda;
	
	
	
	group_individuals_simple create_group (float coeff_susceptible, float coeff_infected){
		create group_individuals_simple with:(my_compartment:self, factor_contact_rate_asymptomatic: group.factor_contact_rate_asymptomatic,contact_rate:group.contact_rate) returns: ca {
			loop s over: myself.group.evol_states.keys {
				evol_states[s] <- sum(myself.group.evol_states[s]);
			}
		}
		return first(ca);
	}
	action carry_out_activities {
		map<SpatialUnit,map<string,float>> agenda_hour <- agenda[current_date.day_of_week - 1][current_date.hour];
		if agenda_hour != nil {
			loop a over: agenda_hour.keys {
				loop bd_type over: agenda_hour[a].keys{
					float coeff <- agenda_hour[a][bd_type];
					group_individuals_simple gp <- create_group(coeff,coeff);
					if not (bd_type in a.current_groups.keys) {
						a.current_groups[bd_type] <- [];
					}
					a.current_groups[bd_type]<< gp; 
				} 
			}  
		}
	}
}