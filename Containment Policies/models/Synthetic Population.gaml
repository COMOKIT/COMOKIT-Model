/***
* Name: SyntheticPopulation
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

@no_experiment
model SyntheticPopulation

import "species/Building.gaml"
import "Parameters.gaml"


global {
	action create_population_from_file(map<Building,float> working_places,map<list<int>,map<Building,float>> schools, list<Building> homes) {}
	
	action create_population(map<Building,float> working_places,map<list<int>,map<Building,float>> schools, list<Building> homes, 
		int min_student_age, int max_student_age
	) {
		ask homes {
			//father
			create Individual {
				age <- rnd(max_student_age + 1,retirement_age);
				sex <- 0;
				home <- myself;
			} 
			//mother
			create Individual {
				age <- rnd(max_student_age + 1,retirement_age);
				sex <- 1;
				home <- myself;
			}
			//children
			create Individual number: rnd(3) {
				last_activity <-first(staying_home);
				age <- rnd(0,max_student_age);
				sex <- rnd(1);
				home <- myself;
			}

		}
		ask (N_grandfather * length(Building)) among homes {
			create Individual {
				age <- rnd(retirement_age + 1, max_age);
				sex <- 0;
				home <- myself;
			}
		}

		ask (M_grandmother * length(Building)) among homes {
			create Individual {
				age <- rnd(retirement_age + 1, max_age);
				sex <- 1;
				home <- myself;
				
			}
		}		
	}
}

