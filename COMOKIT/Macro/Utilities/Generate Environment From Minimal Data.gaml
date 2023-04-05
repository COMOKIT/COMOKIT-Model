/**
* Name: testdata
* Based on the internal skeleton template. 
* Author: admin_ptaillandie
* Tags: 
*/

model generateEnv

global {
	
	
	shape_file adm_shape_file <- shape_file("../Datasets/Lang Son/adm2.shp");

	csv_file population_csv_file <- csv_file("../Datasets/Lang Son/population_district.csv", ",", true);

	csv_file pyramid_Age_csv_file <- csv_file("../Datasets/Lang Son/Viet Nam - Pyramid Age - 2019.csv");

	geometry shape <- envelope(adm_shape_file);
	string admin_1_att <- "VARNAME_1";
	string admin_2_att <- "VARNAME_2";
	
	
	list<list<int>> age_cat <- [[0,19],[20,44],[45,54],[55,64],[64,74],[75,84],[85,120] ];
	
	
	
	bool consider_sex_for_group <- false;
	bool consider_occupation_for_group <- false;
	
	
	init {
		save "province,district,population" to: "population_district.csv" format: "text";
		create boundary from: adm_shape_file with: (admin1:get(admin_1_att), admin2:get(admin_2_att));
		map<string, boundary> boundaries <- boundary as_map (each.admin1 + "_" + each.admin2::each);
		matrix mat_data <- matrix(population_csv_file);
		loop j from: 0 to: mat_data.rows - 1 {
			string id <- ""+ mat_data[0,j] + "_" + mat_data[1,j] ;
			boundary bd <- boundaries[id];
			bd.population <- int(mat_data[2,j]);
			
		}
		save boundary to: "boundaryZZZ.shp" format: shp ;
	}
}

species boundary {
	string admin1;
	string admin2;
	int population;
	rgb color <- rnd_color(255);
	aspect default {
		draw shape color: color;
	}
}

experiment generate type: gui {
	output {
		display map {
			species boundary;
		}
	}
}
