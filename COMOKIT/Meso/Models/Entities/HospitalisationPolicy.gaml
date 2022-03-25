/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* All the base policies provided with COMOKIT. Most of their combinations
* are indeed declared in the actions of the Authority agent.
* 
* Author: Alexis Drogoul, Benoit Gaudou, Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19

import "../../../Core/Models/Entities/Policy.gaml"

import "../Global.gaml"


global {
	/*
	 * To define a policy with ICU, hospitalisation and a given minimum number of test per day
	 */
	AbstractPolicy create_hospitalisation_policy(bool allow_ICU, bool allow_hospitalisation, int nb_tests, species<Hospital> h_species <- Hospital){
		create HospitalisationPolicy returns: result{
			is_allowing_ICU <- allow_ICU;
			is_allowing_hospitalisation <- allow_hospitalisation;
			nb_minimum_tests <- nb_tests;
			hospital_species <- h_species;
		}
		return (first(result));
	}
} 
/**
 * The policy used to use hospitals for cure  */
species HospitalisationPolicy parent: AbstractPolicy{
	//Allowing ICU admission or not (example, Lao PDR does not have ICU capacity)
	bool is_allowing_ICU;
	//Allowing hospitalisation or not (example, not wanting symptomatic people that are not in the need of ICU to maintain other services)
	bool is_allowing_hospitalisation;
	//Minimum number of tests needed to be negative to discharge an individual
	int nb_minimum_tests;
	
	species<Hospital> hospital_species <- Hospital;
	container<Hospital> hospitals -> {container<Hospital>(hospital_species.population+(hospital_species.subspecies accumulate each.population))};
	
	//Remove an individual from ICU
	action remove_individual_from_ICU(Individual an_individual, Hospital a_hospital){
		remove an_individual from:a_hospital.ICU_individuals;
		a_hospital.capacity_ICU <- a_hospital.capacity_ICU+1;
		an_individual.is_ICU <- false;
	}
	
	//Remove an individual from being hospitalised (but could be later added in ICU)
	action remove_individual_from_hospitalised(Individual an_individual, Hospital a_hospital){
		remove an_individual from:a_hospital.hospitalised_individuals;
		a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation+1;
		an_individual.is_hospitalised <- false;
	}
	
	//Adding an individual to ICU
	action add_individual_to_ICU (Individual an_individual, Hospital a_hospital){
		add an_individual to: a_hospital.ICU_individuals;
		a_hospital.capacity_ICU <- a_hospital.capacity_ICU-1;
		an_individual.is_ICU <- true;
		ask an_individual{
			do enter_building(a_hospital);
		}
	}
	
	//Adding an individual to hospitalised individuals
	action add_individual_to_hospitalised (Individual an_individual, Hospital a_hospital){
		a_hospital.hospitalised_individuals << an_individual;
		a_hospital.capacity_hospitalisation <- a_hospital.capacity_hospitalisation-1;
		an_individual.is_hospitalised <- true;
		ask an_individual{
			do enter_building(a_hospital); 
		}
	}
	
	//Try to find a place for the individual according to its clinical status
	action try_add_individual_to_hospital(Individual an_individual){
		if(an_individual.clinical_status=need_hospitalisation){
			list<Hospital> possible_hospitals <- (hospitals where(each.capacity_hospitalisation>0));
			if(length(possible_hospitals)>0){
				do add_individual_to_hospitalised(an_individual,one_of(possible_hospitals));
			}else{
				//Send the individual back home when no place is available
				ask an_individual{
					do enter_building(self.home);
				}
			}
		}else{
			list<Hospital> possible_hospitals <- (hospitals where(each.capacity_ICU>0));
			if(length(possible_hospitals)>0){
				do add_individual_to_ICU(an_individual,one_of(possible_hospitals));
			}else{
				//send the individual back home when no place is available, could be changed to sending him to "normal" hospitalisation beds
				ask an_individual{
					do enter_building(self.home);
				}
			}
		}
	}
	
	//Update the individuals in hospital
	action update_individuals_in_hospital{
		loop a_hospital over: hospitals {
			
			//REMOVE DEAD PEOPLE
			loop an_individual over: a_hospital.hospitalised_individuals where(each.clinical_status=dead){
				do remove_individual_from_hospitalised(an_individual, a_hospital);
			}
			loop an_individual over: a_hospital.ICU_individuals where(each.clinical_status=dead){
				do remove_individual_from_ICU(an_individual, a_hospital);
			}
			
			//REMOVE RECOVERED PEOPLE FROM HOSPITALISED
			loop an_individual over: a_hospital.hospitalised_individuals where((each.state!=symptomatic) and (cycle-each.last_test>nb_step_for_one_day) and (each.number_negative_tests<nb_minimum_tests)){
				ask an_individual{
					do test_individual;
				}
				//If the individual has been tested negative enough times, discharge it
				if(an_individual.report_status=tested_negative){
					an_individual.number_negative_tests <- an_individual.number_negative_tests +1;
					if(an_individual.number_negative_tests>=nb_minimum_tests){
						do remove_individual_from_hospitalised(an_individual, a_hospital);
						if(an_individual.state=removed){
							an_individual.clinical_status <- recovered;
							ask an_individual{
								do enter_building(self.home);
							}
						}
					}
				}else{
					an_individual.number_negative_tests <- 0;
				}
			}
			
			//REMOVE ICU PEOPLE THAT JUST NEED HOSPITALISATION
			loop an_individual over: a_hospital.ICU_individuals where(each.clinical_status=need_hospitalisation){
				do remove_individual_from_ICU(an_individual,a_hospital);
				if(a_hospital.capacity_hospitalisation>0){
					do add_individual_to_hospitalised(an_individual,a_hospital);
				}else{
					do try_add_individual_to_hospital(an_individual);
				}
			}
			
			//ADD HOSPITALISED PEOPLE THAT NOW NEED ICU
			loop an_individual over: a_hospital.hospitalised_individuals where(each.clinical_status=need_ICU){
				do remove_individual_from_hospitalised(an_individual, a_hospital);
				if(a_hospital.capacity_ICU>0){
					do add_individual_to_ICU(an_individual,a_hospital);
				}else{
					do try_add_individual_to_hospital(an_individual);
				}
			}
		}
	}
	//Apply the policy
	action apply{
		//Updating individuals in the hospitals
		do update_individuals_in_hospital;
		if(is_allowing_hospitalisation){
			//ADD PEOPLE NEEDING ICU OR HOSPITALISATION NOT PRESENT YET
			loop an_individual over: all_individuals where((each.clinical_status=need_hospitalisation) and (each.is_hospitalised=false)){
				do try_add_individual_to_hospital(Individual(an_individual));
			}
		}
		if(is_allowing_ICU){
			loop an_individual over: all_individuals where((each.clinical_status=need_ICU) and (each.is_ICU=false)){
				do try_add_individual_to_hospital(Individual(an_individual));
			}
		}
		
	}
	//Preventing moving anywhere for people hospitalised
	bool is_allowed (Individual i, Activity activity){
		return not(i.is_ICU or i.is_hospitalised);
	}
	
	//@TODO  : TO IMPLEMENT
	float allowed(int source_area, int target_area, string activity_str, string building_type) {
		return 1.0;
	}
}