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
	outside the_outside;
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
		
		create outside;
		the_outside <- first(outside);
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
				home <- myself;
				office <- flip(proba_go_outside) ? the_outside :working_places.keys[rnd_choice(working_places.values)];
			} 
			//mother
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- 23 + rnd(30);
				sex <- 1;
				home <- myself;
				office <- flip(proba_go_outside) ? the_outside :working_places.keys[rnd_choice(working_places.values)];
			}
			//children
			create Individual number: rnd(3) {
				last_activity <- a_home[0];
				ageCategory <- rnd(22);
				sex <- rnd(1);
				home <- myself;
				if (ageCategory <=  18) {
					school <- (empty(schools) or flip(proba_go_outside)) ? the_outside :any(schools.keys[rnd_choice(schools.values)]) ;
				} else {
					school <- (empty(universities) or flip(proba_go_outside)) ? the_outside : any(schools.keys[rnd_choice(universities.values)]);
				}
			}

		}

		ask (N_grandfather * length(Building)) among homes {
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- 55 + rnd(50);
				sex <- 0;
				home <- myself;
			}

		}

		ask (M_grandmother * length(Building)) among homes {
			create Individual {
				last_activity <- a_home[0];
				ageCategory <- 50 + rnd(50);
				sex <- 1;
				home <- myself;
				
			}
		}
		ask Individual {
			location <- (home.location);
			status <- susceptible;
			bound <- home;
		}
		//list<Activity> possible_activities <- Activities.values where ((each.type_of_building = nil) or (each.type_of_building in buildings_per_activity.keys));
		list<Activity> possible_activities <- Activities.values - a_school - a_work - a_home;
		ask Individual where ((each.ageCategory < 55 and each.sex = 0) or (each.ageCategory < 50 and each.sex = 1)) {
			int current_hour;
			if (ageCategory < 23) {
				current_hour <- rnd(7,9);
				agenda_week[current_hour] <- a_school[0];
			}
			 else {
				current_hour <- rnd(6,8);
				agenda_week[current_hour] <- a_work[0];
			}
			if (flip(proba_lunch_outside_workplace)) {
				
				current_hour <- rnd(11,13);
				if (not flip(proba_lunch_at_home) and (possible_activities first_with (each.type_of_building = t_restaurant)) != nil) {
					agenda_week[current_hour] <- possible_activities first_with (each.type_of_building = t_restaurant);
				} else {
					agenda_week[current_hour] <- a_home[0];
				}
				current_hour <- current_hour + rnd(1,2);
				if (ageCategory < 23) {
					agenda_week[current_hour] <- a_school[0];
				} else {
					agenda_week[current_hour] <- a_work[0];
				}
			}
			current_hour <- rnd(15,18);
			agenda_week[current_hour] <- a_home[0];
			current_hour <- current_hour + rnd(1,3);
			if (ageCategory > 12) and flip(proba_activity_night) {
				agenda_week[current_hour] <- any(possible_activities);
				current_hour <- (current_hour + rnd(1,3)) mod 24;
			}
			agenda_week[current_hour] <- a_home[0];
		}
		ask Individual where empty(each.agenda_week) {
			int num_activity <- rnd(0,max_num_activity_for_old_people);
			int current_hour <- rnd(7,9);
			loop times: num_activity {
				agenda_week[current_hour] <- any(possible_activities);
				current_hour <- (current_hour + rnd(1,4)) mod 24;
				agenda_week[current_hour] <- a_home[0];
				current_hour <- (current_hour + rnd(1,4)) mod 24;
			}
		
		}

		ask num_infected_init among Individual {
			do defineNewCase;
		}
		
		total_number_individual <- length(Individual);

	}

}