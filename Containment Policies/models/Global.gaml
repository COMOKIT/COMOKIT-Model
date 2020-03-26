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
		create Building from: shp_buildings {
			//father
			create Individual {
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
				ageCategory <- rnd(22);
				sex <- rnd(1);
				home <- myself;
				school <- any(Building - home);
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}

		}
	
		ask (N_grandfather * length(Building)) among Building {
			create Individual {
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
				agenda_week[8] <- a_school[0];
			} else {
				agenda_week[8] <- a_work[0];
			}
			agenda_week[17] <- a_home[0];
		}

		ask 2 among Individual {
			incubation_time <- rnd(max_incubation_time);
			status <- exposed;
		}
		
		// Create an authority 
		create Authority;

	}

	reflex stop_sim when: cycle >= 1500 {
		do pause;
	}

}