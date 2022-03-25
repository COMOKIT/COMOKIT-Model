/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* The main species of COMOKIT: a Biological Entity that can perform 
* Activities in Buildings.
* Individuals maintain networks of family members, friends and colleagues
* In addition to the attributes and states inherited from its parent, 
* this species provides actions so that its agents can be tested, hospitalized, 
* infected, can infect others, wear masks, and so on.
* 
* Author: Huynh Quang Nghi, Patrick Taillandier, Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/


@no_experiment

model CoVid19 

import "../Global.gaml" 
 
global {
	list<Building> buildings_concerned;
	list<list<list<int>>> index_group_in_building_agenda;
	list<list<list<Building>>> index_building_agenda;
	
}

species Abstract_individual_precomputation parent: BiologicalEntity schedules:[] {
	bool is_immune(int id, virus infectious_agent) {
		float t <- machine_time;
		map history <-agents_history[id];
		if (history != nil) {
			immunity <-history["immunity"];
			return  activate_immunity(infectious_agent);
		}
		return false;
	}
}

species Individual parent: AbstractIndividual schedules: use_activity_precomputation ? shuffle(Individual) : shuffle(Individual where ((each.clinical_status != dead))){
	//#############################################################
	//Agenda and activities attributes
	//#############################################################
	list<map<int, pair<Activity,list<Individual>>>> agenda_week;
	list<Individual> activity_fellows;
	map<Activity, map<string,list<Building>>> building_targets;
	Building current_place;
	
	//Bool to consider if the individual is at home
	bool is_at_home <- true;
	//Home building of the individual
	Building home;
	//School building of the individual (if student)
	Building school;
	//Working place of the individual (if working)
	Building working_place;
	//Friends (i.e. possibility of leisure activities together) of the individual
	list<Individual> friends;
	//Colleagues (i.e. same working place) of the individual
	list<Individual> colleagues;
	
	// Allows to track who infect who 
	action infect_someone_from_id(int succesful_contact_id) { 
		if not bot_abstract_individual_precomputation.is_immune(succesful_contact_id, viral_agent) {
			AbstractIndividual contact <- world.load_individual(succesful_contact_id);
			contact.location <- location;
			contact.current_place <- current_place;
			do infect_someone(contact);
		}
		
	}
	
	//Action to call to define a new case, obtaining different time to key events
	bool define_new_case(virus infectious_agent)
	{
		if use_activity_precomputation {
			is_active <- true;
         
		} 
			if use_activity_precomputation or (not activate_immunity(infectious_agent)) {
				
				//Add the new case to the total number of infected (not mandatorily known)
				total_number_of_infected <- total_number_of_infected +1;
				
				//Add the infection to the infections having been caused in the building
				
				if current_place != nil {
					loop fct over: current_place.functions  {
						if(building_infections.keys contains(fct))
						{
							building_infections[fct] <- building_infections[fct] +1;
						}
					}
				}
				//Add the infection to the infections of the same age
				if(total_incidence_age.keys contains(self.age))
				{
					total_incidence_age[self.age] <- total_incidence_age[self.age] +1;
				}
				else
				{
					add 1 to: total_incidence_age at: self.age;
				}
				
				// Add the activity done while being infected
				infected_when <- last_activity; 
				// Infected by
				viral_agent <- infectious_agent;
				// Start history of the infetion
				infection_history[infectious_agent] <- map(current_date::INFECTED); 
				 
				do initialise_disease;
				
				return true;
			}
			
			return false;
			
		
	}
	
	
	action other_initialisation_action {
		if (use_activity_precomputation) {
			individuals_precomputation[id_int] <- self;
		}
	}
	
	//Initialiase social network of the agents (colleagues, friends)
	action initialise_social_network(map<AbstractPlace,list<Individual>> working_places, 
			map<AbstractPlace,map<int,list<Individual>>> schools, map<int,list<Individual>> ind_per_age_cat) {
		int nb_friends <- max(0,round(gauss(nb_friends_mean,nb_friends_std)));
		loop i over: ind_per_age_cat.keys {
			if age < i {
				friends <- nb_friends among ind_per_age_cat[i]; 
				friends <- friends - self;
				break;
			}
		}

		if (working_place != nil) {
			int nb_colleagues <-int(gauss(nb_work_colleagues_mean,nb_work_colleagues_std));
			if nb_colleagues > 1 {
				colleagues <- nb_colleagues among working_places[working_place];
				colleagues >> self;
			}
		} 
		if (school != nil) {
			int nb_classmates <- int(gauss(nb_classmates_mean,nb_classmates_std));
			if nb_classmates > 1 {
				//colleagues <- nb_classmates among ((schools[school] where ((each.age >= (age -1)) and (each.age <= (age + 1))))- self);
				colleagues <- nb_classmates among schools[school][age];
				colleagues >> self;
			}
		}
	}
	
	//Action to call when entering a new building to update the list of individuals of the buildings
	action enter_building(Building b) {
		if (current_place != nil ){
			current_place.individuals >> self;
		}	
		current_place <- b;
		is_at_home <- current_place = home;
		current_place.individuals << self;
		location <- any_location_in(current_place);
	}
	
	//#############################################################
	//Reflexes
	//#############################################################
	
	//Reflex to trigger infection when outside of the commune
	reflex become_infected_outside when: is_outside and (state = susceptible) and 
			not use_activity_precomputation {
		float start <- BENCHMARK ? machine_time : 0.0;
		ask Outside {do outside_epidemiological_dynamic(myself, step);}
		if BENCHMARK {bench["Individual.become_infected_outside"] <- bench["Individual.become_infected_outside"] + machine_time - start;}
	}
	
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: not is_outside and is_infectious
	{
		float start <- BENCHMARK ? machine_time : 0.0;
		//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		if (use_activity_precomputation) {
			current_place <- is_activity_allowed ? index_building_agenda[current_week][current_day][current_hour] : home;
			is_at_home <- current_place = home;
			if udpate_for_display {
				location <- any_location_in(current_place);
			}
			do update_wear_mask();
			
		}
	
		float reduction_factor <- viral_factor;
		
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic;
		}
		if(is_wearing_mask)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_wearing_mask;
		}
		
		//Performing environmental contamination
		if(current_place!=nil)and(allow_transmission_building)
		{
			ask current_place
			{
				do add_viral_load(reduction_factor*myself.basic_viral_release, myself.viral_agent);
			}
		}
		
		//Perform human to human transmission
		if allow_transmission_human {
			float proba <- contact_rate*reduction_factor;
					
			if (use_activity_precomputation) {
				list<list<int>> others <- current_place.entities_inside_int[current_week][current_day][current_hour];
				
				if empty(current_place.individuals_id) {
					ask current_place {do compute_individuals_str;}
				}
				
		
				int index;
				if (is_at_home ) {
					index <- index_home;
				} else {
					index <-  index_group_in_building_agenda[current_week][current_day][current_hour];
				}
				//list<Individual> all_ag <- others accumulate each;
				if (index < length(others)) {
					list<int> inds <- others[index];
					if not empty(inds) {
						inds <- copy((is_at_home ? inds : (nb_max_fellow among inds)) where (flip(proba) and (individuals_precomputation[each] = nil)));
						loop ag over: inds {
							do infect_someone_from_id(ag);
						}	
					}
				}
				if (not is_at_home or current_place.nb_households > 1) {
					float proba_actual <- proba * reduction_coeff_all_buildings_individuals;
					list<int> inds <- copy(current_place.individuals_id where ( flip (proba_actual)  and (individuals_precomputation[each] = nil)));
					loop ag over:inds  {
						do infect_someone_from_id(ag);
						
					}
				}
				
		
					
			} else { 
				//If the Individual is at home, perform transmission on the household level with a higher factor
				if (is_at_home) {
					list<Individual> inds <-list<Individual>(copy(relatives where (Individual(each).is_at_home and flip(proba) and (each.state = susceptible))));
					loop succesful_contact over:inds {
						do infect_someone(succesful_contact);
					}
					if (current_place.nb_households > 1) {
						proba <- proba * reduction_coeff_all_buildings_individuals;
						inds <-  copy(current_place.individuals where (flip(proba) and (each.state = susceptible)));
						loop succesful_contact over: inds 
				 		{
				 			do infect_someone(succesful_contact);
				 		}
					}
					
				}
				else {
					//Perform transmission with people doing the activity explicitly with the Individual
					list<Individual> fellows <- activity_fellows where (flip(proba) and (each.state = susceptible));
					if (species(last_activity) != Activity) {
						fellows <- fellows where (each.current_place = current_place); 
					}
					
					loop succesful_contact over: fellows { do infect_someone(succesful_contact); }
					
					//Perform slightly reduced transmission with people not being involved in the activity but still being present
					proba <- proba * reduction_coeff_all_buildings_individuals;
					list<Individual> inds <- copy(current_place.individuals where (flip(proba) and (each.state = susceptible)));
						
					loop succesful_contact over: inds
			 		{
						do infect_someone(succesful_contact);
			 		}
			 	}	
			 }
		}
		if BENCHMARK {bench["Individual.infect_others"] <- bench["Individual.infect_others"] + machine_time - start;}
	}
	
	//Reflex to execute the agenda	
	reflex execute_agenda when:  clinical_status!=dead{
		float start <- BENCHMARK ? machine_time : 0.0;
		pair<Activity,list<Individual>> act <- agenda_week[current_day][current_hour];
		if (act.key != nil) {
			if use_activity_precomputation {
				is_activity_allowed<- Authority[0].allows(self, act.key);
				nb_max_fellow <- Authority[0].limitGroupActivity(self, act.key) - 1;
			}
			else if (Authority[0].allows(self, act.key)) {
				int nb_fellows <- Authority[0].limitGroupActivity(self, act.key) - 1;
					if (nb_fellows > 0) {
					activity_fellows <-nb_fellows among act.value;
				} else {
					activity_fellows <- [];
				}
					
				map<Building,list<Individual>> bds_ind <-  act.key.find_target(self);
				if not empty(bds_ind) {
					Building bd <- any(bds_ind.keys);
					list<Individual> inds <- bds_ind[bd];
					activity_fellows <- activity_fellows + inds;
					last_activity <- act.key;
					do enter_building(bd);
					is_outside <- current_place = the_outside;
				} else {
					activity_fellows <- [];
				}
			}
		}
		if BENCHMARK {bench["Individual.execute_agenda"] <- bench["Individual.execute_agenda"] + machine_time - start;}
	}
	
	//Remove recoevred agent (no specific behavior anymore)
	reflex become_inactive when:use_activity_precomputation and(state = removed){
		is_active <- false;
	}

	//Reflex to update disease cycle
	reflex update_epidemiology when:not use_activity_precomputation and (state!=removed) {
		float start <- BENCHMARK ? machine_time : 0.0;
		if(allow_transmission_building and (not is_infected)and(self.current_place!=nil))
		{
			loop v over: current_place.viral_load.keys {
				if(flip(current_place.viral_load[v]*successful_contact_rate_building))
				{
					infectious_contacts_with[current_place] <- define_new_case(v);
				}	
			}
		}
		do update_wear_mask();
		if BENCHMARK {bench["Individual.update_epidemiology"] <- bench["Individual.update_epidemiology"] + machine_time - start;}
	}
	
	//#############################################################
	//Visualization
	//#############################################################
	
	aspect default {
		if not is_outside and is_active{
			draw shape color: state = latent ? #pink : ((state = symptomatic)or(state=asymptomatic)or(state=presymptomatic)? #red : #green);
		}
	}
}