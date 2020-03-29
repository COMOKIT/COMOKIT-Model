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

	action global_init {
		write "global init";
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
				switch type_activity {
					match "" {type_activity <- "home";}
					match "store" {type_activity <- "shop";}
					match "caphe" {type_activity <- "coffeeshop";}
					match "caphe-karaoke" {type_activity <- "coffeeshop";}
					match "lake" {do die;}
				}
			}
		}
		
		do create_activities;
		
		list<Building> homes <- Building where (each.type_activity in [t_home,t_hotel]);
		map<Building, float> schools <- (Building where (each.type_activity = t_school)) as_map (each:: each.shape.area);
		map<Building, float> universities <- Building where (each.type_activity = t_university) as_map (each:: each.shape.area);
		if empty(universities) {universities <-schools ;}
		list<Building> offices <- Building where (each.type_activity = t_office);
		list<Building> industries <- Building where (each.type_activity = t_industry);
		list<Building> admins <- Building where (each.type_activity = t_admin);
		list<Building> others <- Building - offices - admins - industries;
		map<Building,float> working_places <- (admins + offices) as_map (each::each.shape.area * 4) + (industries) as_map (each::each.shape.area * 2)+ others as_map (each::each.shape.area) ; 
		
		ask homes {
		//father
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- rnd(23,53);
				sex <- 0;
				status <- "S";
				home <- myself;
				office <- working_places.keys[rnd_choice(working_places.values)];
				location <- (home.location);
				status <- susceptible;
				bound <- home;
			} 
			//mother
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- 23 + rnd(30);
				sex <- 1;
				status <- "S";
				home <- myself;
				office <- working_places.keys[rnd_choice(working_places.values)];
				location <- (home.location);
				status <- susceptible;
				bound <- home;
			}
			//children
			create Individual number: rnd(3) {
				last_activity <- a_home[0];
				ageCategory <- rnd(22);
				status <- "S";
				sex <- rnd(1);
				home <- myself;
				school <- (ageCategory <=  18) ? any(schools.keys[rnd_choice(schools.values)]) : any(schools.keys[rnd_choice(universities.values)]);
				location <- (home.location);
				status <- susceptible;
				bound <- home;
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
				bound <- home;
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
				bound <- home;
			}

		}
		list<Activity> possible_activities <- Activities.values where ((each.type_of_building = nil) or (each.type_of_building in buildings_per_activity.keys));
		possible_activities <- possible_activities - a_school - a_work - a_home;
		ask Individual where ((each.ageCategory < 55 and each.sex = 0) or (each.ageCategory < 50 and each.sex = 1)) {
			if (ageCategory < 23) {
				agenda_week[7 + rnd(2)] <- a_school[0];
			} else {
				agenda_week[6 + rnd(2)] <- a_work[0];
			}

			agenda_week[15 + rnd(3)] <- a_home[0];
			agenda_week[19 + rnd(3)] <- any(possible_activities);
			agenda_week[(23 + rnd(3)) mod 24] <- a_home[0];
		}

		ask 2 among Individual {
			do defineNewCase;
		}
		
		total_number_individual <- length(Individual);

	}

}