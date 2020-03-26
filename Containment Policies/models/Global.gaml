/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Global

import "species/Building.gaml"
import "species/Boundary.gaml"
import "species/River.gaml"
import "species/Road.gaml"
import "species/Individual.gaml"
import "species/Hospital.gaml"
import "species/Activity.gaml"
import "species/Authority.gaml"
import "species/Activity.gaml"
import "Constants.gaml"
import "Parameters.gaml"

global {
		geometry shape <- envelope(shp_buildings);

	init {
		do create_activities;
		
		
		create River from: river_shapefile;
		create Boundary from: commune_shapefile;
		create Road from: shp_roads;
		road_network <- as_edge_graph(Road);
		list<float> tmp<-building_types collect (1/length(building_types));
		create Building from: shp_buildings {
			type_activity<-building_types[rnd_choice(tmp)];
		}
		ask Building{			
			//father
			create Individual {
				last_activity<-a_home[0];
				ageCategory <- 23 + rnd(30);
				sex <- 0;
				home <- myself;
				office <- any(Building - home);
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}
			//mother
			create Individual {
				last_activity<-a_home[0];
				ageCategory <- 23 + rnd(30);
				sex <- 1;
				home <- myself;
				office <- any(Building - home);
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}
			//children
			create Individual number: rnd(3) {
				last_activity<-a_home[0];
				ageCategory <- rnd(22);
				sex <- rnd(1);
				home <- myself;
				school <-  any(Building where(each.type_activity=t_school) - home);
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}
		}
	
		ask (N_grandfather * length(Building)) among Building {
			create Individual {
				last_activity<-a_home[0];
				ageCategory <- 55 + rnd(50);
				sex <- 0;
				home <- myself;
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}

		}

		ask (M_grandmother * length(Building)) among Building {
			create Individual {
				last_activity<-a_home[0];
				ageCategory <- 50 + rnd(50);
				sex <- 1;
				home <- myself;
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}

		}

		ask Individual where ((each.ageCategory < 55 and each.sex = 0) or (each.ageCategory < 50 and each.sex = 1)) {
			if (ageCategory < 23) {
				agenda_week[7+rnd(2)] <- a_school[0];
			} else {
				agenda_week[6+rnd(2)] <- a_work[0];
			}
			agenda_week[15+rnd(3)] <- a_home[0];
			agenda_week[19+rnd(3)] <- any(Activities);
			agenda_week[(23+rnd(3)) mod 24] <- a_home[0];
		}

		ask 2 among Individual {
			incubation_time <- rnd(max_incubation_time);
			status <- exposed;
		}

	}

	reflex stop_sim when: cycle >= 1500 {
		do pause;
	}

}