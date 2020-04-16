/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Benoit Gaudou, Kevin Chapuis
* Tags: covid19,epidemiology
***/

@no_experiment

model CoVid19

import "Entities/Building.gaml"
import "Parameters.gaml"


global {
	
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

