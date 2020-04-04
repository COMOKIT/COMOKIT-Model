/***
* Name: Provinces
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model RiskEstimate

global {
//	shape_file provinces_shp_file <- shape_file("../includes/gadm36_VNM_shp/gadm36_VNM_1.shp");
//	shape_file provinces_shp_file <- shape_file("../includes/gadm36_VNM_shp/gadm36_VNM_2.shp");
	shape_file provinces_shp_file <- shape_file("../includes/gadm36_VNM_shp/gadm36_VNM_3.shp");
	file pop_csv_file <- csv_file("../includes/VNM.27.16_1.csv");
	geometry shape <- envelope(provinces_shp_file);

	// xac dinh moi buoc bang 15 phut
	float step <- 15 #minute;

	//thoi gian khoi dau mo hinh
	date starting_date <- date([2020, 3, 10, 0, 0]);

	// thoi gian virus ton tai va gay nguy hiem o khu vuc benh nhan di qua (tinh theo gio)
	int v_time_life <- 24;
	bool do_init <- false;
	bool do_retrieve_satellite <- false;

	init {
		if (do_init) {
			if (do_retrieve_satellite) {
				do load_image();
			}

			do initialisation;
		} else {
		}

	}

	action initialisation {
		create Province from: provinces_shp_file with: [h::0.1, N::500, I::1.0];
		ask Province {
		//							write NAME_2;
		//							write GID_2;
			neighbours <- Province where (each touches self);
			//					if (GID_1 != "VNM.27_1") {
			//						do die;
			//							}		
		}

				matrix data <- matrix(pop_csv_file.contents);
				loop i from: 1 to: data.rows - 1 {
					Province p <- first(Province where (each.VARNAME_3 = data[0, i]) );
					ask p {
						N <- int(data[1, i]);
						I <- float(data[2, i]);
						S <- N - I;
						rgb null <- mycolor;
					}
		
				}
	}

	image_file static_map_request;

	//define the path to the output folder
	string output_path <- "../includes";

	action load_image {
//		point top_left <- CRS_transform({0, 0}, "EPSG:4326").location;
//		point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
//		int size_x <- 1000;
//		int size_y <- 1000;
//		string
//		rest_link <- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea=" + bottom_right.y + "," + top_left.x + "," + top_left.y + "," + bottom_right.x + "&mapSize=" + int(size_x) + "," + int(size_y) + "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln";
//		static_map_request <- image_file(rest_link);
//		write "Satellite image retrieved";
//		ask cell {
//			color <- rgb((static_map_request) at {grid_x, size_y - (grid_y + 1)});
//		}
//
//		save cell to: output_path + "/satellite.png" type: image;
//		string
//		rest_link2 <- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea=" + bottom_right.y + "," + top_left.x + "," + top_left.y + "," + bottom_right.x + "&mmd=1&mapSize=" + int(size_x) + "," + int(size_y) + "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln";
//		file f <- json_file(rest_link2);
//		list<string> v <- string(f.contents) split_with ",";
//		int ind <- 0;
//		loop i from: 0 to: length(v) - 1 {
//			if ("bbox" in v[i]) {
//				ind <- i;
//				break;
//			}
//
//		}
//
//		float long_min <- float(v[ind] replace ("'bbox'::[", ""));
//		float long_max <- float(v[ind + 2] replace (" ", ""));
//		float lat_min <- float(v[ind + 1] replace (" ", ""));
//		float lat_max <- float(v[ind + 3] replace ("]", ""));
//		point pt1 <- to_GAMA_CRS({lat_min, long_max}, "EPSG:4326").location;
//		point pt2 <- to_GAMA_CRS({lat_max, long_min}, "EPSG:4326").location;
//		pt1 <- CRS_transform(pt1, "EPSG:3857").location;
//		pt2 <- CRS_transform(pt2, "EPSG:3857").location;
//		float width <- abs(pt1.x - pt2.x) / size_x;
//		float height <- abs(pt1.y - pt2.y) / size_y;
//		string info <- "" + width + "\n0.0\n0.0\n" + height + "\n" + min(pt1.x, pt2.x) + "\n" + min(pt1.y, pt2.y);
//		save info to: output_path + "/satellite.pgw";
//		write "Satellite image saved with the right meta-data";
	}

}

//grid cell width: 1000 height: 1000 use_individual_shapes: false use_regular_agents: false use_neighbors_cache: false;

species Province {
	float t;
	int N;
	float S <- N - I;
	float E <- 0.0;
	float I;
	float R <- 0.0;
	float h;
	float beta <- 0.4;
	float gamma <- 0.01;
	float sigma <- 0.05;
	float mu <- 0.01;
	string NAME_1;
	string NAME_2;
	string NAME_3;
	string GID_1;
	string GID_2;
	string GID_3;
	string VARNAME_1;
	string VARNAME_2;
	string VARNAME_3;
	bool infected<-false;
	rgb mycolor -> {hsb(0, (I > 25 ? 0.1 : 0) + (I > 25 ? 25 : I) / 29, 1)};
	//	rgb mycolor -> {hsb(0, I/N, 1)};

	// must be followed with exact order S, E, I, R, t  and N,beta,gamma,sigma,mu
	equation eqSEIR type: SEIR vars: [S, E, I, R, t] params: [N, beta, gamma, sigma, mu];
	list<Province> neighbours <- [];

	reflex solving when:infected {
		solve eqSEIR method: "rk4" step_size: h;
	}

	reflex transmission {
		Province candi <- any(neighbours);
		if (candi != nil) {
			int r <- rnd(2);
			switch r {
				match 0 {
					if (N > 1) and (S > 1) {
						N <- N - 1;
						candi.N <- candi.N + 1;
						S <- S - 1;
						candi.S <- candi.S + 1;
					}

				}

				match 1 {
					if (N > 1) and (E > 1) {
						N <- N - 1;
						candi.N <- candi.N + 1;
						E <- E - 1;
						candi.E <- candi.E + 1;
					}

				}

			}

		}

	}

	aspect default {
		draw shape color: mycolor empty: false border: #black;
		if (#zoom > 1.1) {
			draw NAME_3 at: location color: #black;
		}

	}

}

experiment Pandemic2020 type: gui {

	action _init_ {
	/* 
		 * Ha noi 		VNM.27_1
		 * Long Bien	VNM.27.16_1
		 */
//		 string id<-"VNM.27_1";
		string id <- "VNM.27.16_1";
		string filepath <- "../includes/gadm36_VNM_shp/generated/" + id + ".shp";
		if (!file_exists(filepath)) {
			write "generate sub_shp";
			create simulation {
				create Province from: provinces_shp_file;
				save (Province where (each.GID_2 = id)) to: filepath type: "shp" attributes:
				["ID"::int(self), "NAME_1"::NAME_1, "GID_1"::GID_1, "NAME_2"::NAME_2, "GID_2"::GID_2, "NAME_3"::NAME_3, "GID_3"::GID_3, "VARNAME_1"::VARNAME_1, "VARNAME_2"::VARNAME_2, "VARNAME_3"::VARNAME_3];
				do die;
			}

		}

		create simulation with: [do_init::true,do_retrieve_satellite::false, provinces_shp_file::shape_file(filepath)];
	}

	output {
		layout horizontal([0::5000, 1::5000]) tabs: true editors: false;
		display "provinces"  {
			image file: "../includes/satellite.png" refresh: false;
			species Province transparency:0.5;
		}

		display "Statistic" {
			chart 'SEIR' type: series {
				data "S" value: sum(Province collect each.S) color: #green;
				data "E" value: sum(Province collect each.E) color: #yellow;
				data "I" value: sum(Province collect each.I) color: #red;
				data "R" value: sum(Province collect each.R) color: #blue;
			}

		}

	}

}