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
	list<Building> shops ;	
	list<Building> markets ;	
	list<Building> supermarkets ;
	list<Building> bookstores ;
	list<Building> cinemas ;
	list<Building> game_centers ;
	list<Building> karaokes;
	list<Building> restaurants;
	list<Building> coffeeshops;
	list<Building> building_outside_commune;
	list<Building> playgrounds;
	list<Building> hospitals;
	list<Building> supply_points;
	list<Building> farms;
	
	action global_init {
		do create_activities;
		if (shp_river != nil) {
			create River from: shp_river;
		}

		if (shp_commune != nil) {
			create Boundary from: shp_commune;
		}

		if (shp_roads != nil) {
			create Road from: shp_roads;
		}

		road_network <- as_edge_graph(Road);
		list<float> tmp <- building_types collect (1 / length(building_types));
		if (shp_buildings != nil) {
			create Building from: shp_buildings with: [type_activity::string(read("type"))]{
				if(type_activity = "") {
					type_activity <- "home";
				}
			}
		}
		list<Building> homes <- Building where (each.type_activity = "home");
		list<Building> schools <- Building where (each.type_activity = t_school);
		shops <- Building where (each.type_activity = t_shop);	
		markets <- Building where (each.type_activity = t_market) ;	
		supermarkets <- Building where (each.type_activity = t_supermarket);
		bookstores <-Building where (each.type_activity = t_bookstore) ;
		cinemas <- Building where (each.type_activity = t_cinema) ;
		game_centers <- Building where (each.type_activity = t_gamecenter) ;
		karaokes <- Building where (each.type_activity = t_karaoke) ;
		restaurants <- Building where (each.type_activity = t_restaurant);
		coffeeshops <- Building where (each.type_activity = t_coffeeshop);
		farms <- Building where (each.type_activity = t_farm);
		building_outside_commune <- Building where !(each overlaps world.shape);
		playgrounds <- Building where (each.type_activity = t_playground);
		hospitals <- Building where (each.type_activity = t_hospital);
		supply_points <- Building where (each.type_activity = t_supplypoint) ;
		ask homes {
		//father
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- 23 + rnd(30);
				sex <- 0;
				status <- "S";
				home <- myself;
				office <- any(Building - home);
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}
			//mother
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- 23 + rnd(30);
				sex <- 1;
				status <- "S";
				home <- myself;
				office <- any(Building - home);
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}
			//children
			create Individual number: rnd(3) {
				last_activity <- a_home[0];
				ageCategory <- rnd(22);
				status <- "S";
				sex <- rnd(1);
				home <- myself;
				school <- any(schools - home);
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}

		}

		ask (N_grandfather * length(Building)) among homes {
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- 55 + rnd(50);
				sex <- 0;
				home <- myself;
				location <- (home.location);
				status <- susceptible;
				bound <- home.shape;
			}

		}

		ask (M_grandmother * length(Building)) among homes {
			create Individual {
				last_activity <- a_home[0];
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
				agenda_week[7 + rnd(2)] <- a_school[0];
			} else {
				agenda_week[6 + rnd(2)] <- a_work[0];
			}

			agenda_week[15 + rnd(3)] <- a_home[0];
			agenda_week[19 + rnd(3)] <- any(Activities);
			agenda_week[(23 + rnd(3)) mod 24] <- a_home[0];
		}

		ask 2 among Individual {
			do defineNewCase;
		}


	}

}