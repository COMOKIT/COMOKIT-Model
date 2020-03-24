/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

global {
	float seed <- 0.5362681362380473; //
//	float seed <- 0.2955510396397566;
	file road_shapefile <- file("../includes/roads.shp");
	file building_shapefile <- file("../includes/buildings.shp");
	geometry shape <- envelope(building_shapefile);
	int max_exposed_period <- 30;
	list<string>
	schoolname <- ["Tieu hoc Mac Dinh Chi", "TrÆ°á»ng THPT ChÃ¢u VÄƒn LiÃªm", "THPT BC Pháº¡m Ngá»c Hiá»ƒn", "TrÆ°á»ng THCS ÄoÃ n Thá»‹ Äiá»ƒm", "NgÃ´ Quyá»n", "Máº§m non TÃ¢y ÄÃ´", "Trung TÃ¢m GiÃ¡o Dá»¥c ThÆ°á»ng XuyÃªn"];
	graph road_network;
	bool off_school<-true;
	int dead<-0;
	int nb_people<-500;
//	map<string, float> profiles <- ["poor"::0.3, "medium"::0.4, "standard"::0.2, "rich"::0.1]; //	map<string,float> profiles <- ["innovator"::0.0,"early_adopter"::0.1,"early_majority"::0.2,"late_majority"::0.3, "laggard"::0.5];
	init {
		create road from: road_shapefile;
		road_network <- as_edge_graph(road);
		create building from: building_shapefile {
			if (name in schoolname) {
				is_school <- true;
			}

		}

		list sch <- (building where (each.is_school)) sort (-each.shape.area);
		float total <- sum(sch collect each.shape.area);
		list idx <- sch collect (each.shape.area / total);
		create people number: nb_people {
			my_school <- sch[rnd_choice(idx)]; // any(building where (each.is_school));
			my_building <- any(building where (!each.is_school));
			location <- any_location_in(my_building);
			my_bound <- my_building.shape;
			//			masked <- flip(0.8) ? true : false;
		}

		ask (0.5*nb_people) among people {
			masked <- true;
		}

		ask 1 among (people) {
			exposed <- true;
		}

	}
	reflex stop_sim when:cycle>=1500{
		do pause;
	}
}

species road {

	aspect default {
		draw shape color: #gray empty: true;
	}

}

species virus_container {
	bool susceptible <- true;
	bool infected <- false;
	bool exposed <- false;
	bool recovered <- false;
}

species building parent: virus_container {
	bool is_school <- false;

	aspect default {
//		draw name color:#black;
		draw shape color: is_school ? #blue : #gray empty: true;
	}

}

//species obstacle parent: virus_container {
//}
species people parent: virus_container skills: [moving] {
	float spd <- 1.0;
	float size <- 2.0;
	building my_building <- nil;
	building my_school <- nil;
	people my_friend <- nil;
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
		ask ((people at_distance (size * 2)) where (each.susceptible and !each.recovered)) {
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
					my_friend <- any((people - self) where (each.state = "wander" and each.my_bound = my_bound));
					if (my_friend = nil) {
						state <- "wander";
					} else {
						my_target <- my_friend.location;
					}

				} else {
					if (!infected) {
						state <- "visiting";
						my_building <- any(building where (!each.is_school));
						my_bound <- my_building.shape;
						my_target <- any_location_in(my_building);
					}

				}

			}

		} else {
			if (flip(0.05)) {
				state <- "moving";
				my_friend <- any((people - self) where (each.state = "wander" and each.my_bound = my_bound));
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
		do goto target: my_target on: road_network speed: 10.0;
		if (location distance_to my_target < (size * 2)) {
			state <- "wander";
		}

	}

	reflex moving when: state = "moving" {
		do goto target: my_target speed: 10.0;
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

experiment sim {
//	parameter "OFF SCHOOL" var: off_school <- true category: "Education planning";
	init{
		create simulation{
			seed<-0.5362681362380473;
			off_school<-false;
		}
	}
	output {
//		 layout horizontal([0::6321,1::3679]) tabs:true editors: false;
 layout vertical([0::5000,1::5000]) tabs:true editors: false;
		display "d1" synchronized: false type:java2D {
			graphics "g"{
				draw "School shutdown:"+off_school at:{180,20} color:#black perspective:false;
			}
			species road refresh: false;
			species building;
			species people;
		}

		display "chart" {
			chart "sir" background: #white axes: #black {
				data "susceptible" value: length(people where (each.susceptible)) color: #green marker: false style: line;
				data "infected" value: length(people where (each.exposed or each.infected)) color: #red marker: false style: line;
				data "recovered" value: length(people where (each.recovered)) color: #blue marker: false style: line;
				data "dead" value: dead color: #black marker: false style: line;
			}

		}

	}

}