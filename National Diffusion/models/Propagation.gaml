/***
* Name: Provinces
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Provinces

global {
	float step <- 1 #day;
	date starting_date <- date([2020, 3, 1, 0, 0]);
	shape_file provinces_shp_file <- shape_file("../includes/gadm36_VNM_shp/gadm36_VNM_1.shp");
	file pop_csv_file <- csv_file("../includes/VNpop.csv");
	geometry shape <- envelope(provinces_shp_file);
	float max_I -> {Province max_of each.I};
	font default <- font("Helvetica", 20, #bold);
	font info <- font("Helvetica", 18, #bold);
	rgb text_color <- world.color.brighter.brighter;
	rgb background <- world.color.darker.darker;

	init {
		create Province from: provinces_shp_file with: [h::10000, N::500, I::1.0];
		ask Province {
			neighbours <- Province where (each touches self);
		}

		matrix data <- matrix(pop_csv_file.contents);
		loop i from: 1 to: data.rows - 1 {
			Province p <- first(Province where (each.VARNAME_1 = data[0, i]));
			ask p {
				N <- int(data[1, i]);
				I <- float(data[2, i]);
				S <- N - I;
				rgb null <- mycolor;
			}

		}

	}

}

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
	string VARNAME_1;
	rgb mycolor -> {hsb(0, I / max_I, 1)};
	//	rgb mycolor -> {hsb(0, I/N, 1)};

	// must be followed with exact order S, E, I, R, t  and N,beta,gamma,sigma,mu
	equation eqSEIR {
		diff(S, t) = (mu * N - beta * S * I / N - mu * S)/step;
		diff(E, t) = (beta * S * I / N - mu * E - sigma * E)/step;
		diff(I, t) = (sigma * E - mu * I - gamma * I)/step;
		diff(R, t) = (gamma * I - mu * R)/step;
	}

	list<Province> neighbours <- [];

	reflex solving {
		t<-t/step;
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
		draw shape color: mycolor border: #black;
	}

}

experiment Pandemic2020 type: gui autorun:true{
	output {
		layout horizontal([0::5000, 1::5000]) tabs: true editors: false;
		//		layout horizontal([0::5000, 1::5000]) tabs: true editors: false;
		display "provinces" synchronized: true {
			image file: "../includes/satellite_VNM_1.png" refresh: false;
						overlay position: {100, 0} size: {220 #px, 50 #px} transparency: 0.7 {
							draw (""+current_date) font: default at: {20 #px, 10 #px} anchor: #top_left color: text_color;
						}
			species Province transparency: 0.1;
		}

		display "Statistic" {
			chart 'SEIR' type: series {
//				data "S" value: sum(Province collect each.S) color: #green;
				data "E" value: sum(Province collect each.E) color: #yellow;
				data "I" value: sum(Province collect each.I) color: #red;
				data "R" value: sum(Province collect each.R) color: #blue;
			}

		}

	}

}