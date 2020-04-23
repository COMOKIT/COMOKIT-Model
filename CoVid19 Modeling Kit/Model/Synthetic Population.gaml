/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19 </br>
* Author: Benoit Gaudou, Kevin Chapuis </br>
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Entities/Building.gaml"
import "Parameters.gaml"

/*
 * All functions to initialize demographic attribute of the agent. It feature two type of initialization:
 * - use a file with #create_population_from_file to create a synthetic population from given attributes
 * - use the default algorithm provided in the toolkit: see #create_population for more info
 */
global {
	
	/*
	 * Uses the provided population.csv (in Datasets folder) to initialize the population of agent with. The required
	 * arguments are: </br>
	 * - age COMOKIT variable : age_var in Parameters.gaml </br>
	 * - sex COMOKIT variable : gender_var in Parameters.gaml </br>
	 * - household_id COMOKIT variable : householdIF in Parameters.gaml </p>
	 * 
	 * It might also require to define a way to convert values; e.g. gender can be coded using integers, so you will have to
	 * translate encoding into the proper variable, i.e. 0 for male and 1 for female in for COMOKIT. You can do so using,
	 * age_map and gender_map in Parameters.gaml </p>
	 * 
	 * The algorithm also bound agent with working places, schools and homes using related methods in Global.gaml #assign_school_working_place </p>
	 */
	action create_population_from_file(map<Building,float> working_places,map<list<int>,list<Building>> schools, list<Building> homes
	) {
		
		map<string,list<Individual>> households <- [];
		
		create Individual from:csv_population number: (number_of_individual <= 0 ? length(csv_population) : number_of_individual)
		with:[
			age::convert_age(get(age_var)),
			sex::convert_gender(get(gender_var)),
			household_id::string(get(householdID)) replace("\"","")
		]{
			if households contains_key household_id { households[household_id] <+ self; }
			else { households[household_id] <- [self]; }
		}
		
		list<Building> avlb_homes <- copy(homes);
		
		loop hhid over:households.keys { 
			Building homeplace <- any(avlb_homes); // Uniform distribution | should we take HH size vs size of the building ?
			ask households[hhid] { 
				relatives <- households[hhid] - self;
				home <- homeplace;
			}
			avlb_homes >- homeplace;
			if empty(avlb_homes) { avlb_homes <- copy(homes); } // Again, uniform even if some homeplace already have more people than others
		}
		
	}
	
	/*
	 * The default algorithm to create a population of agent from simple rules. </p>
	 * 
	 * The <b> arguments </b> includes: </br> 
	 * - min_student_age :: minimum age for lone individual </br>
	 * - max_student_age :: age that makes the separation between adults and children </p>
	 * 
	 * The <b> parameter </b> to adjust the process: </br>
	 * - nb_households :: the number of household per building (can be set using feature 'flat' from the shapefile of buildings) </br>
	 * - proba_active_family :: the probability to build a father+mother classical household rather than a lonely individual </br>
	 * - retirement_age :: the age that makes the separation between active and retired adults (will have a great impact on the agenda) </br>
	 * - number_children_max, number_children_mean, number_children_std :: assign a given number of children between 0 and max using gaussian mean and std </br>
	 * - proba_grandfather, proba_grandmother :: assign grand mother/father to the household
	 * </p>
	 */
	action create_population(map<Building,float> working_places,map<list<int>,list<Building>> schools, list<Building> homes, 
		int min_student_age, int max_student_age
	) {
		list<list<Individual>> households;
		
		ask homes {
			loop times: nb_households {
				list<Individual> household;
				if flip(proba_active_family) {
				//father
					create Individual {
						age <- rnd(max_student_age + 1,retirement_age);
						sex <- 0;
						home <- myself;
						household << self;
					} 
					//mother
					create Individual {
						age <- rnd(max_student_age + 1,retirement_age);
						sex <- 1;
						home <- myself;
						household << self;
					
					}
					//children
					int number <- min(number_children_max, round(gauss(number_children_mean,number_children_std)));
					if (number > 0) {
						create Individual number: number {
							//last_activity <-first(staying_home);
							age <- rnd(0,max_student_age);
							sex <- rnd(1);
							home <- myself;
							household << self;
						}
					}
					if (flip(proba_grandfather)) {
						create Individual {
							age <- rnd(retirement_age + 1, max_age);
							sex <- 0;
							home <- myself;
							household << self;
						}
					}	
					if (flip(proba_grandmother)) {
						create Individual {
							age <- rnd(retirement_age + 1, max_age);
							sex <- 1;
							home <- myself;
							household << self;
						}
					}
				} else {
					create Individual {
						age <- rnd(min_student_age + 1,max_age);
						sex <- rnd(1);
						home <- myself;
						household << self;
					} 
				}
				
				ask household {
					relatives <- household - self;
				}  
				households << household;
			}
		}	
	}
	
	// Convert SP encoded age into gama model specification (float)
	float convert_age(string input){ 
		input <- input replace("\"","");
		return (age_map=nil or empty(age_map)) ? int(input) : age_map[input];
	}
	
	// Convert SP encoded gender into gama model specification (0=men, 1=women)
	int convert_gender(string input){ 
		input <- input replace("\"","");
		return (gender_map=nil or empty(gender_map)) ? int(input) : gender_map[input]; 
	}
	
}

