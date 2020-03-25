/**
* Name: clean_road_network
* Author: Patrick Taillandier
* Description: shows how GAMA can help to clean network data before using it to make agents move on it
* Tags: gis, shapefile, graph, clean
*/
model clean_road_network

global {
//Shapefile of the roads
//	file gate_shapefile <- file("../includes/roads.shp");
	file road_shapefile <- file("../includes/roads1.shp");
//	bool transform <- true;
//	file road_shapefile <- file("../includes/roads_tmp.shp");
//	file road_shapefile <- file("../includes/CTURoads2.shp");
	bool transform <- false;

	//Shape of the environment
//	file building_shapefile <- file("../includes/CTUBuildings3.shp");
//	file bound_shapefile <- file("../includes/CTUBound.shp");
	geometry shape <- envelope(road_shapefile);

	//clean or not the data
	bool clean_data <- true parameter: true;

	//tolerance for reconnecting nodes
	float tolerance <- 0.5 parameter: true;

	//if true, split the lines at their intersection
	bool split_lines <- true parameter: true;
	//if true, keep only the main connected components of the network
	bool reduce_to_main_connected_components <- false parameter: true;
	string legend <- not clean_data ?
	"Raw data" : ("Clean data : tolerance: " + tolerance + "; split_lines: " + split_lines + " ; reduce_to_main_connected_components:" + reduce_to_main_connected_components);
	list<list<point>> connected_components;
	list<rgb> colors;

	list<rgb> road_color <- [#green, #red, #blue];
	init {
		
//		create building from: building_shapefile with:[owner::read("building")];
//		create gate from: gate_shapefile;
//		ask building overlapping geometry(bound_shapefile.contents){
//			if(owner!="KTX"){
//				owner<-"CTU";				
//				}
//		}
	//clean data, with the given options
		list<geometry> clean_lines <- clean_data ? clean_network(road_shapefile.contents, tolerance, split_lines, reduce_to_main_connected_components) : road_shapefile.contents;

		//create road from the clean lines
		create road from: clean_lines;
//		ask road{
//			if (DIRECTION=0){
////				DIRECTION<-0;
//				TYPE<-"main";
//			}
//		}
//		list<road> reversed<-[road[170],road[30],road[171],road[68],road[44],road[84],road[83],road[140],road[66],road[119],road[151],road[166],road[75],road[175]];
//		ask reversed{
//			shape <- polyline(reverse(shape.points));
//		}
//			gate[0].TYPE <- "1";
//			point p1 <- gate[0].location;
//			point p2 <- road[3].shape.points closest_to p1;
//			create road {
//				shape <- line(p1, p2);
//				DIRECTION <- 2;
//			}
//
//			gate[3].TYPE <- "1";
//			p1 <- gate[3].location;
//			p2 <- road[169].shape.points closest_to p1;
//			create road {
//				shape <- line(p1, p2);
//				DIRECTION <- 2;
//			}
		
		if (transform) {
			float toler <- 5.0;
			ask road {
				point so <- first(self.shape.points);
				road rr1 <- ((road - self) closest_to so);
				write rr1;
				geometry r1 <- rr1.shape;
				point p1 <- r1.points closest_to self;
				write p1 distance_to so;
				if (p1 distance_to so < toler) {
					list g1 <- r1 split_at p1;
					rr1.shape<-g1[0];
					create road from: geometry(g1[1]);
//					ask rr1 {
//						do die;
//					}

					shape.points[0] <- p1;
					s1 <- circle(5) at_location p1;
				}

				so <- last(self.shape.points);
				road rr2 <- ((road - self) closest_to so);
				geometry r2 <- rr2.shape;
				point p2 <- r2.points closest_to self;
				if (p2 distance_to so < toler) {
					list g2 <- r2 split_at p2;
					rr2.shape<-g2[0];
					create road from: geometry(g2[1]);
//					ask rr2 {
//						do die;
//					}

					shape.points[length(shape.points) - 1] <- p2;
					s2 <- circle(5) at_location p2;
				}

			}

		}
//		ask road overlapping geometry(bound_shapefile.contents){
//			OWNER<-"CTU";
//		}
		//build a network from the road agents
		graph road_network_clean <- as_edge_graph(road);
		//computed the connected components of the graph (for visualization purpose)
		connected_components <- list<list<point>>(connected_components_of(road_network_clean));
		loop times: length(connected_components) {
			colors << rnd_color(255);
		}

	}

	reflex ss {
//		save building to: "../includes/CTUBuildings3.shp" type: shp attributes: ["owner"::owner];
//			save road to: "../includes/CTURoads2_tmp.shp" type: shp attributes: ["NAME"::name, "LANES"::LANES, "TYPE"::TYPE, "DIRECTION"::DIRECTION];
		save road to: "../includes/roads.shp" type: shp attributes: ["NAME"::name, "LANES"::LANES, "TYPE"::TYPE, "DIRECTION"::DIRECTION, "OWNER"::OWNER];
	}

}

species gate {
	string NAME;
	string TYPE;
	int DIRECTION;

	aspect default {
		draw square(10) empty: true color: #black;
	}

}
	//Species to represent the buildings
species building {
	string owner; 
	//	reflex time_off when: flip(0.0005) {
	//		create people number: capacity {
	//			location <- any_location_in(one_of(road where (each.NAME != "3 Tháng 2")));
	//			target <- any_location_in(one_of(road where (each.NAME = "3 Tháng 2")));
	//			purpose <- "go home";
	//		}
	//
	//	}
	aspect default {
		draw shape empty:true color: #black;
	}

}
//Species to represent the roads
species road {
//	string name<-"";
	geometry s1 <- nil;
	geometry s2 <- nil;
	int DIRECTION;
	int LANES <- 4;
	string TYPE <- "";
	string OWNER<-"";
//	init{
//		 DIRECTION<-2;
//	}

	aspect default {
		draw shape + 5 empty: false color:road_color[DIRECTION];
		if (s1 != nil) {
			draw s1;
		}

		if (s2 != nil) {
			draw s2;
		}

	}

}

experiment clean_network type: gui {
//	init {
//		create clean_road_network_model with:[clean_data::false]; 
//		create clean_road_network_model with:[split_lines::false,reduce_to_main_connected_components::false]; 
//		create clean_road_network_model with:[split_lines::true,reduce_to_main_connected_components::false]; 
//	}
	output {
		display network type: opengl {
		//			 overlay position: { 10, 100 } size: { 1000 #px, 60 #px } background: # black transparency: 0.5 border: #black rounded: true
		//            {
		//				draw legend color: #white font: font("SansSerif", 20, #bold) at: {40#px, 40#px, 1 };
		//			}
			graphics "connected components" {
//				draw geometry(bound_shapefile.contents);
				loop i from: 0 to: length(connected_components) - 1 {
					loop j from: 0 to: length(connected_components[i]) - 1 {
						draw circle(12) color: colors[i] at: connected_components[i][j];
					}

				}

			}

			species building refresh: false;
			species road;
		}

	}

}
