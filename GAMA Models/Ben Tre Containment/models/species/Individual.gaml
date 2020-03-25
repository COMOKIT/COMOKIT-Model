/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Species_Individual
import "../Parameters.gaml"
import "Building.gaml"

species virus_container {
	bool susceptible <- true;
	bool infected <- false;
	bool exposed <- false;
	bool recovered <- false;
}

//species obstacle parent: virus_container {
//}
species Individual parent: virus_container skills: [moving] {
	float spd <- 1.0;
	float size <- 5.0;
	Building my_building <- nil;
	Building my_school <- nil;
	Individual my_friend <- nil;
	geometry my_bound;
	point my_target <- nil;
	string state <- "wander";
	//	bool moving <- false;
	//	bool visiting <- false;
	//	bool making_conversation <- false;
	bool masked <- false;
	bool at_school <- false;
	int exposed_period <- 14;
	int infected_period <- 14;
	int cnt <- 0;
	geometry shape <- circle(size);

	reflex epidemic when:state!="visiting"{
		if (exposed) {
			cnt <- cnt + 1;
			if (cnt >= exposed_period * 20) {
				cnt <- 0;
				exposed <- false;
				infected <- true;
			}

		}

		if (infected) {
			cnt <- cnt + 1;
			if (cnt >= infected_period * 20) {
				if(flip(0.98)){					
					cnt <- 0;
					exposed <- false;
					infected <- false;
					recovered <- true;
				}else{
					dead<-dead+1;
					do die;
				}
			}

		}

	}

	reflex spreading_virus when: (exposed or infected) and (state != "visiting") {
		ask ((Individual at_distance (size * 2)) where (each.susceptible and !each.recovered)) {
			exposed <- (masked) ? (flip(0.01) ? true : false) : (flip(0.5) ? true : false);
			if (exposed) {
				susceptible <- false;
				exposed_period <- rnd(max_exposed_period);
				infected_period <- 1 + rnd(10);
			}

		}

	}

	reflex living when: state = "wander" {
		do wander speed: spd bounds: my_bound;
		if (off_school) {
			if (flip(0.005)) {
				if (flip(0.01)) {
					state <- "moving";
					my_friend <- any((Individual - self) where (each.state = "wander" and each.my_bound = my_bound));
					if (my_friend = nil) {
						state <- "wander";
					} else {
						my_target <- my_friend.location;
					}

				} else {
					if (!infected) {
						state <- "visiting";
						my_building <- any(Building where (!each.is_school));
						my_bound <- my_building.shape;
						my_target <- any_location_in(my_building);
					}

				}

			}

		} else {
			if (flip(0.05)) {
				state <- "moving";
				my_friend <- any((Individual - self) where (each.state = "wander" and each.my_bound = my_bound));
				if (my_friend = nil) {
					state <- "wander";
				} else {
					my_target <- my_friend.location;
				}

			} else {
				if (at_school) {
					if (flip(0.0005)) {
						state <- "visiting";
						my_bound <- my_building.shape;
						my_target <- any_location_in(my_building);
					}

				} else {
					if (flip(0.05)) {
						state <- "visiting";
						my_bound <- my_school.shape;
						my_target <- any_location_in(my_school);
					}

				}

			}

		}

	}

	reflex visit when: state = "visiting" {
		do goto target: my_target on: road_network speed: motor_spd;
		if (location distance_to my_target < (size * 2)) {
			state <- "wander";
		}

	}

	reflex moving when: state = "moving" {
		do goto target: my_target speed: motor_spd;
		if (location distance_to my_target < (size * 2)) {
			state <- "wander";
		}

	}

	aspect default {
	//		if (state = "visiting" or state = "moving") {
	//			draw line([location, my_target]) color: #gray;
	//		}
		draw shape color: exposed ? #pink : (infected ? #red : #green);
	}

}