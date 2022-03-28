/**
* Name: NewModel
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


model GenerateAgenda

import "../Models/Functions.gaml"

import "../Models/Parameters.gaml"

import "../../Core/Models/Parameters.gaml"



global {
	
	bool MODE_TEST <- false;
		
	string folder_path <- "../../Datasets/";
	string dataset <- "Alpes-Maritimes";
	string case_study_path <- folder_path + dataset +"/";
	string folder_generated <- case_study_path+"generated/";
	string folder_agenda <- case_study_path+"Agenda/";
	
	shape_file ZF_EMD2008_shape_file <- shape_file(folder_agenda + "ZF_EMD2008_rubbersheet.shp");
	geometry shape <- envelope(ZF_EMD2008_shape_file);
	string travel_path <- folder_agenda + "DEPLACEMENT.csv";
	string household_path <- folder_agenda+ "MENAGE.csv";
	string people_path <- folder_agenda+ "PERSONNE.csv";
	string folder_coep <- folder_path + "Coep_files";
	
	string agenda_path <- folder_generated+"agenda_data/";
	string population_path <- case_study_path+"generated/population.csv";
	
	float proba_min <-0.005;

	int age_step <- 10;
	int age_max <- 100;
	
	list<string> possible_activities_tot;
	int min_student_age <- 18;
	int max_student_age <- 25;
	int first_act_hour_non_working_min <- 7;
	int first_act_hour_non_working_max <- 10;
			
	float nb_activity_fellows_mean <- 3.0;
	float nb_activity_fellows_std <-2.0;
	int max_num_activity_for_non_working_day <- 4;
		
	float proba_kindergarden <- 0.1;
	int min_age_obligatory_school <- 3;
	list<list<int>> age_cat <- [[0,19],[20,44],[45,54],[55,64],[64,74],[75,84],[85,120] ];
	
	map<list<int>,float> proba_age_sport <- [[10,1]::0.3,[10,2]::0.1, [18,1]:: 0.4,[18,2]:: 0.2, [30,1]:: 0.5,[30,2]:: 0.2, [45,1]::0.2, [45,2]::0.05,[65,1]::0.01, [65,2]::0.01,[120,1]::0.001, [120,2]::0.0001];
	
	list<list<map<string,list<people_data>>>>   generation_tree;
	
	int min_duration_act_minute <- 10;
	
//	map<string,map<string,map<string,map<string,float>>>> data_area;
	map<string,map<string,map<string,float>>> data_area;
	map<string,string> zone_EMD_to_boundary;
	map<string,float> weight_area_tot;
		
	map<string,list<string>> activities;
	
	//'Artisans commerÃ§ants chefs d\'entreprise','Cadres et professions intellectuelles supÃ©rieures',
	//'Autres personnes sans activitÃ© professionnelle','RetraitÃ©s','EmployÃ©s','Professions intermÃ©diaires',
	//'Ouvriers','Agriculteurs exploitants'
	
	//list<string> sex_values <-["0", "1"];
	list<string> study_area;

	
	map<string,boundary> boundary_per_area;
	map<string,string> occupation_mapping <- [
		'36'::'worker',
		'82'::'non worker',
		'32'::'worker',
		'31'::'worker',
		'41'::'worker',
		'83'::'non worker',
		'0'::'non worker',
		'56'::'worker',
		'46'::'worker',
		'61'::'worker',
		'21'::'worker',
		'66'::'worker',
		'47'::'worker',
		'55'::'worker',
		'22'::'worker',
		'85'::'non worker',
		'51'::'worker',
		'84'::'non worker',
		'48'::'worker',
		'54'::'worker',
		'87'::'non worker',
		'89'::'non worker',
		'88'::'non worker',
		'86'::'non worker',
		'23'::'worker',
		'81'::'non worker',
		'10'::'worker',
		'69'::'worker',
		'99'::""
	];
	
	
	map<string,string> motif_explication <- [
		"01"::"staying at home",	
		"02"::"staying at home",	
		"11"::"working",	
		"12"::"working",	
		//"21"::"studying",	
		"22"::"studying",	
		"23"::"studying",	
		"24"::"studying", 	
		"25"::"studying",	
		"26"::"studying",	
		"27"::"studying", 	
		"28"::"studying",	
		"29"::"studying", 	
		"31"::"shopping",	
		"32"::"shopping",	
		"33"::"shopping",	
		"34"::"shopping",	
		"41"::"other activity",	
		"42"::"other activity",	
		"51"::"leisure and sport",		
		"53"::"eating",	
		"54"::"visiting friend",
		"91"::"other activity"
	];
	/*map<string,string> motif_explication <- [
		"01"::"Domicile",	
		"02"::"Résidence secondaire, logement occasionnel, autre domicile",	
		"11"::"Travail sur le lieu d’emploi déclaré en P11",	
		"12"::"Travail sur un autre lieu",	
		"21"::"Nourrice, crèche, garde d’enfants",	
		"22"::"Ecole maternelle et primaire (sur le lieu déclaré en P11)",	
		"23"::"Collège (sur le lieu déclaré en P11)",	
		"24"::"Lycée (sur le lieu déclaré en P11)", 	
		"25"::"Université et grandes écoles (sur le lieu déclaré en P11)",	
		"26"::"Ecole maternelle et primaire (sur un autre lieu)",	
		"27"::"Collège (sur un autre lieu)", 	
		"28"::"Lycée (sur un autre lieu)",	
		"29"::"Université et grandes écoles (sur un autre lieu)", 	
		"31"::"Multi-motifs en centre commercial sans achat",	
		"32"::"Achats en grand magasin, supermarché et hypermarché et leur galerie marchande",	
		"33"::"Achats en petit et moyen commerce",	
		"34"::"Achats en marché couvert et de plein vent",	
		"41"::"Santé",	
		"42"::"Démarches",	
		"43"::"Recherche d’emploi",	
		"51"::"Loisirs, activités sportives, culturelles, associatives",	
		"52"::"Promenade, lèche-vitrines sans achat, leçon de conduite",	
		"53"::"Restauration hors du domicile",	
		"54"::"Visite à des parents ou à des amis",	
		"61"::"Accompagner quelqu’un (personne présente)",	
		"62"::"Aller chercher quelqu’un (personne présente)",	
		"63"::"Accompagner quelqu’un (personne absente)",	
		"64"::"Aller chercher quelqu’un (personne absente)",	
		"71"::"Dépose d’une personne à un mode de transport (personne présente)",	
		"72"::"Reprise d’une personne à un mode de transport (personne présente)",	
		"73"::"Dépose d’une personne à un mode de transport (personne absente)",	
		"74"::"Reprise d’une personne à un mode de transport (personne absente)",	
		"81"::"Tournée professionnelle",	
		"91"::"Autres motifs (préciser)"
	];*/
		
	
	init {
		
		activities <- init_building_type_parameters_fct(building_type_per_activity_parameters, possible_workplaces,possible_schools, school_age ,active_age) ;
	
		possible_activities_tot <- activities.keys - [act_working, act_studying, act_home];
		do import_data_file;
		create zone_EMD from: ZF_EMD2008_shape_file with: [name::string(get("NOM_ZF")), id::string(get("NUM_ZF08")) replace (" ",""), district::int(get("SECTEUR"))] {
			loop while: first(id) = "0" {
				id <- id copy_between (1, length(id) );
			}
		}
		
		create boundary from: file(folder_generated + "boundary.shp") {
			my_zones <- zone_EMD where (each.location overlaps self);
			ask my_zones {
				zone_EMD_to_boundary[id] <- myself.id;
			}
			study_area <- study_area +( my_zones collect each.id);
			boundary_per_area[string(id)] <- self;
		}
		matrix mat <- matrix(csv_file(folder_generated + "boundary.csv",",", true));
		loop i from: 0 to: mat.rows -1 {
			boundary bd <- boundary_per_area[string(mat[0,i])];
			if bd != nil {
				ask bd {
					area_types <- [];
					list<string> types <- string(mat[2,i]) split_with "$";
					loop t over: types {
						list<string> k_v <- t split_with "::";
						if (length(k_v) > 1) {
							
							area_types[k_v[0]] <- float(k_v[1]);
						
						}
					}
					list<string> categories <-string(mat[1,i]) split_with "$";
					loop c over: categories {
						if c != nil and c != "" {
							list<string> k_v <- c split_with "::";
							if length(k_v) > 1 {
								list<string> id_int_str <- k_v[0] split_with "&&";
								int id_ <- int(id_int_str[0]);
								compartments_inhabitants << id_;		
							}
						}
					}
					
				}
			}
		}
		
		
		study_area <- remove_duplicates(study_area);
		
		ask boundary {
			loop type over: area_types.keys {
				if (type in weight_area_tot.keys) {
					weight_area_tot[type] <- weight_area_tot[type] + area_types[type];
				}else {
					weight_area_tot[type] <- area_types[type];
				}
				
			}
			loop bd over: boundary {
				float dist <-   location distance_to bd.location;
				distances_factor[bd] <- dist = 0.0 ? 1.0 : ((1/ min(1.0,(dist / #km)))^2);
			}
		} 
		csv_file f <- csv_file(travel_path, ";", true);
		create travel from: f with: [zone_id::string(int(get("ZONE"))),household_id::string(int(get("NUMECH"))), people_id::string(int(get("P01"))), zone::get("ZONE"), motif::string(int(get("D5.A"))), origin::string(int(get("D3"))), destination::string(int(get("D7"))),hour_data:: string(int(get("D4"))) ];
		map<list<string>, travel> ts <- travel as_map ([each.zone_id, each.household_id, each.people_id]::each);
		
		ask travel {
			if not(motif in motif_explication.keys) {
				motif <- motif_explication["0" + motif];
			} else {
				motif <- motif_explication[motif];
			}
			if (motif = nil) {
				do die;
			}
			do init_hour;
		}
		
		map<string, list<travel>> travel_per_motifs <- travel group_by each.motif;
		
		write "Data loaded";
		
		csv_file f_h <- csv_file(household_path, ";", true);
		create household_data from: f_h with: [day::int(get("MP4")),zone_id::string(int(get("ZONE"))),household_id::string(int(get("NUMECH")))];
		
		
		csv_file f_p <- csv_file(people_path, ";", true);
		map<string,list<travel>> travel_per_id <- travel group_by (each.zone_id +"_" + each.household_id + "_" + each.people_id);
		
		list<string> act_remov;
		create people_data from: f_p with: [zone_id::string(int(get("ZONE"))),household_id::string(int(get("NUMECH"))), people_id::string(int(get("P01"))), age_int:: int(get("P04")), age::to_age_cat(int(get("P04"))), working_status:: string(int(get("P09"))),sex::string(int(get("P02"))), occupation::string(int(get("P11")))] {
			if not (zone_id in study_area) {
				do die;
			}
			occupation <- occupation_mapping[occupation];
			
			if (working_status = "7") {
				occupation <- "Retraités";
			}
			day <- (household_data first_with((each.zone_id = zone_id) and (each.household_id = household_id))).day;
			travels <- travel_per_id[zone_id +"_" + household_id + "_" + people_id];
			list<string> tr <- (travels collect each.hour) + " - " + (travels collect each.motif);
			if (length(travels) >= 2) {
				travels <- travels sort_by each.time_minute;
				list<travel> to_remove;
				bool test_h <- true;
				loop while: test_h and length(travels) >= 2{
					test_h <- false;
					loop i from: 0 to: length(travels) - 2{
						if (travels[i].hour = travels[i+1].hour) {
						test_h <- true;
						int d <- travels[i+1].time_minute -  travels[i].time_minute; 
						
						if (d >= min_duration_act_minute) {
							if (i > 0) {
								if (int(travels[i - 1].hour) < (int(travels[i].hour) - 1) ) {
									travels[i].hour <- string(int(travels[i].hour) - 1) ;
								} else if (int(travels[i].hour) < (int(travels[i+1].hour) - 1) ) {
									travels[i].hour <- string(int(travels[i].hour) + 1) ;
								} else {
									to_remove << travels[i];
								}
							} else if int(travels[i].hour) > 0 {
								travels[i].hour <- string(int(travels[i].hour) - 1) ;
							} else {
								to_remove << travels[i];
							}	
						}
						else {
							to_remove << travels[i];
						}
					}
				}
				travels <- travels - to_remove;
				ask to_remove {
					act_remov << motif;
					do die;
				}
				
				}
				if length(travels) = 1 {
					ask travels {
						do die;
					}
					travels <- [];
				} else if length(travels) > 1 {
					if last(travels).motif != "staying at home" {
						create travel with: [motif::"staying at home"]{
							zone_id<- myself.zone_id;
							household_id<- myself.household_id;
							people_id<- myself.people_id;
							zone<- myself.zone_id;
							origin<- myself.zone_id;
							
							destination<- myself.zone_id;
							hour <- "" + (int(last(myself.travels).hour) + 1);
							myself.travels << self;
						}
					}
				}
				
				
			} else {
				do die;	
			}
		}
		
		ask people_data {
			do manage_leisure_sport;
		}
		ask travel {
			if motif = act_leisure_sport {
				motif <- act_leisure;
			}
		}
	
		ask people_data {
			if (not empty(travels)) {
				coep <- first(travels).coep;
				do prepare_data;
			} else {
				do die;
			}
			
		
		}
		
		
		loop i from: 1 to: 7  {
			generation_tree << [];
		}
		list<map<string,list<people_data>>>  normal_day  <- build_examples([1,2,4]);
		list<map<string,list<people_data>>>  wednesday  <- build_examples([3]);
		list<map<string,list<people_data>>>  friday  <- build_examples([5]);
		loop i over: [0,1,3] {
			generation_tree[i] <- normal_day;
		}
		
		generation_tree[2] <- wednesday;
		generation_tree[4] <- friday;
		
		write "Tree generated";
	 	do generate_agenda_parameter;
		 
	 	csv_file csv_population <-  csv_file(population_path,",",true);
		create people from:csv_population with:[name::get("id"), age :: to_age_cat(int(get("age"))), sex::(string(get("sex")) = "0")? "1":"2", occupation :: get("occupation"), id_area:: int(get("area_id")), id_group:: int(get("group_id"))] {
			age_int <- int(age);
			sex_int <- int(sex);
			
		}
		
		if MODE_TEST {
			ask (0.95 * length(people)) first people {
				do die;
			}
			ask experiment {
				do compact_memory;
			}
		}
		
		ask boundary {
			do init_weights;
		}
		 write "Weights precomputed";
		 
		int cpt ;
		 write "People created";
	 
		ask people parallel: true{
			
			cpt <- cpt + 1;
			if (cpt mod int(length(people)/100) = 0) {
				write "processing agenda generation: " + int(cpt * 100 / length(people)) + "%" ;
			}
			if not (occupation  in (occupation_mapping.values) ){
				occupation <- "Autres personnes sans activité professionnelle";
			}
			loop d from: 0 to: 4 {
				list<int> days_r <-   (d = 2) ?[2,0,4] : ((d = 4) ? [4,0,2] : [0,4,2]);
				do generate_agenda(d,days_r);
				if empty(agenda[d]) {
					do manage_active_day(d);
				}
			}
			loop d from: 5 to: 6 {
				do manag_day_off(d);
			}
			do init_agenda(boundary_per_area[string(id_area)]);
			
		} 
		
		write "Agenda generated";
		
		map<int, list<people>> people_per_compartment <- people group_by (each.id_group);
		cpt <- 0;
		ask boundary parallel: true {
			cpt <- cpt + 1;
			if (cpt mod int(length(boundary)/100) = 0) {
				write "processing macro agenda generation: " + int(cpt * 100 / length(boundary)) + "%";
					
			
			}
			loop comp over: compartments_inhabitants {
				list<people> people_inside <- people_per_compartment[comp];
				if length(people_inside) > 0 {
					write sample(length(people_inside));
					list<list<map<string,map<string,map<string,float>>>>> agenda_comp <- [];
					loop d from: 0 to: 6 {
						list<map<string,map<string,map<string,float>>>> agenda_day <- [];
						loop h from: 0 to: 23 {
							map<string,map<string,map<string,float>>> agenda_hour <- [];
							int cptt <- 0;
							ask people_inside {
								cptt <- cptt + 1;
								float t <- machine_time;
								do update_agenda;
								
								ask myself {
									do update_agenda_compartment(agenda_hour, myself.current_area,myself.current_activity,myself.current_bd_type);
								}
								
								
							}
							agenda_day << agenda_hour;
						}
						agenda_comp << agenda_day;
					} 
					agenda[comp] <- agenda_comp;
				}
			}
		}
		write "Macro Agenda generated";
		
	 	do normalize;
	 	do filter_small_proba;
		list<string> bd_types <- remove_duplicates(boundary accumulate each.area_types.keys) ;
		bd_types <- bd_types inter remove_duplicates(activities.values accumulate each);
		list<string> act_types <- possible_activities_tot +  [act_working, act_studying, act_home];
		
		map<string, int> activity_to_id;
		map<string,int> bd_type_to_id ;
		loop i from: 0 to: length(bd_types) - 1 {
			bd_type_to_id[bd_types[i]] <- i;
		} 
		loop i from: 0 to: length(act_types) - 1 {
			activity_to_id[act_types[i]] <- i;
		} 
		string act_types_str <- "ACTIVITIES$$";
		loop act over: activity_to_id.keys{
			act_types_str <- act_types_str + act +"$$";
		}
		string bd_types_str <- "BD_TYPES$$";
		loop bd over: bd_type_to_id.keys{
			bd_types_str <- bd_types_str +  bd +"$$";
		}
		
		write "Ready to save";
		
		
		ask boundary {
			string path_name <- agenda_path + id + ".data";
			write "saving boundary " + id; 
			save act_types_str to: path_name type: text; 
		
			save bd_types_str to: path_name type: text rewrite: false; 
				
				loop comp over: agenda.keys {
					list<list<map<string,map<string,map<string,float>>>>> agenda_comp <- agenda[comp];
						
					loop d from: 0 to: 6 {
						list<map<string,map<string,map<string,float>>>> agenda_day <- agenda_comp[d];
						loop h from: 0 to: 23 {
							string age_str <- ""+ comp +"," + d +"," + h + ","; 
							map<string,map<string,map<string,float>>> agenda_hour <- agenda_day[h];
							loop zone over:agenda_hour.keys {
								map<string,map<string,float>> agenda_zone <- agenda_hour[zone];
								age_str <- age_str + zone + "@"; 
								loop act over:agenda_zone.keys {
									map<string,float> agenda_act <- agenda_zone[act];
									age_str <- age_str + activity_to_id[act] + "+"; 
									loop type over:agenda_act.keys {
										age_str <- age_str + bd_type_to_id[type] + ":" +agenda_act[type] + "=" ; 
									}
									
									age_str <- age_str +"$";
								}
								age_str <- age_str +"%";
							}
							save age_str to: path_name type: text rewrite: false; 
							//age_str <- age_str +"&";
						}
						//age_str <- age_str +"|";
					}
					
					
				}
			
		}
		
		
	}
	
	action filter_small_proba {
		ask boundary parallel: true{
			loop comp over: agenda.keys {
				list<list<map<string,map<string,map<string,float>>>>> agenda_comp <- agenda[comp];
				loop d from: 0 to: 6 {
					list<map<string,map<string,map<string,float>>>> agenda_day <- agenda_comp[d];
					loop h from: 0 to: 23 {
						map<string,map<string,map<string,float>>> agenda_hour <- agenda_day[h];
						loop zone over: copy(agenda_hour.keys) {
							map<string,map<string,float>> agenda_zone <- agenda_hour[zone];
							loop t over: copy(agenda_zone.keys) {
								map<string,float> agenda_type <- agenda_zone[t];
								loop type over: copy(agenda_type.keys) {
									if agenda_type[type] < proba_min {
										remove key: type from: agenda_type;
									}
								}
								if (empty(agenda_type)) {
									remove key: t from: agenda_zone;
								}
							}
							if (empty(agenda_zone)) {
								remove key: zone from: agenda_hour;
							}
						}
					}
				}
			}
		}
		do normalize;
	}
	
	action normalize {
		write "\n Normalize";
		ask boundary parallel: true{
			int nb <- 0;
			loop comp over: agenda.keys {
				list<list<map<string,map<string,map<string,float>>>>> agenda_comp <- agenda[comp];
				loop d from: 0 to: 6 {
					list<map<string,map<string,map<string,float>>>> agenda_day <- agenda_comp[d];
					loop h from: 0 to: 23 {
						map<string,map<string,map<string,float>>> agenda_hour <- agenda_day[h];
						float sum_tot;
						loop agenda_zone over: agenda_hour.values {
							loop agenda_type over: agenda_zone.values {
								sum_tot <- sum_tot + sum(agenda_type);
							}
						}
						loop agenda_zone over: agenda_hour.values {
							loop agenda_type over: agenda_zone.values {
								loop type over: agenda_type.keys {
									agenda_type[type] <- agenda_type[type] / sum_tot;
									nb <- nb +1;
								}
							}
						}
					}
				}
			}
			write sample(id) +" " + sample(nb); 
		}
	}
	
	string to_age_cat(int Age_) {
		string Age_cat;
		loop ac over: age_cat {
			if Age_ >= ac[0] and Age_ <= ac[1] {
				Age_cat <- string(round(mean(ac)));
			} 
		}
		return Age_cat;
	}
	
	int get_value(list<int> vals, bool use_max) {
		float mean_v <- mean(vals);
		float std <- standard_deviation(vals);
		
		if (use_max) {
			return min(max(vals), round(mean_v + (2 * std)));
		} else {
			return max(min(vals), round(mean_v -  (2 *std)));
		}
		
	}
	
	action import_data_file {
		
		if file_exists(csv_activity_weights_path) {
			matrix data <- matrix(csv_file(csv_activity_weights_path,",",string, false));
			weight_activity_per_age_sex_class <- [];
			list<string> act_type;
			loop i from: 3 to: data.columns - 1 {
				act_type <<string(data[i,0]);
			}
			loop i from: 1 to: data.rows - 1 {
				list<int> cat <- [ int(data[0,i]),int(data[1,i])];
				map<int,map<string, float>> weights <- (cat in weight_activity_per_age_sex_class.keys) ? weight_activity_per_age_sex_class[cat] : map([]);
				int sex <- int(data[2,i]);
				map<string, float> weights_sex;
				loop j from: 0 to: length(act_type) - 1 {
					weights_sex[act_type[j]] <- float(data[j+3,i]); 
				}
				
				weights[sex] <- weights_sex;
				weight_activity_per_age_sex_class[cat] <- weights;
			}
		}
		
		
		if file_exists(csv_building_type_weights_path) {
			weight_bd_type_per_age_sex_class <- [];
			matrix data <- matrix(csv_file(csv_building_type_weights_path,",",string, false));
			list<string> types;
			loop i from: 3 to: data.columns - 1 {
				types <<string(data[i,0]);
			}
			loop i from: 1 to: data.rows - 1 {
				list<int> cat <- [ int(data[0,i]),int(data[1,i])];
				map<int,map<string, float>> weights <- (cat in weight_bd_type_per_age_sex_class.keys) ? weight_bd_type_per_age_sex_class[cat] : map([]);
				int sex <- int(data[2,i]);
				map<string, float> weights_sex;
				loop j from: 0 to: length(types) - 1 {
					weights_sex[types[j]] <- float(data[j+3,i]); 
				}
				
				weights[sex] <- weights_sex;
				weight_bd_type_per_age_sex_class[cat] <- weights;
			}
		}
	}
	
	
	action generate_agenda_parameter {
		list<people_data> people_area <-  people_data where (each.zone_id in study_area );
		save "Parameter,Value" type:text to: case_study_path + "Agenda parameter.csv";
		save "non_working_days,6,7" type:text to: case_study_path + "Agenda parameter.csv" rewrite: false;
		
		
		list<int> min_school_hour_l ;
		list<int> max_school_hour_l;
		list<int> min_school_hour_end_l;
		list<int> max_school_hour_end_l ;
		loop p over: people_area where (each.day in [1,2,4,5]) {
			
			if (p.travels first_with (each.motif = "studying")) != nil {
				travel tf <- p.travels first_with (each.motif = "studying");
				if (int(tf.hour) < 12) {
					loop times: max(1.0,round(p.coep)) {min_school_hour_l << int(tf.hour);}
					loop times: max(1.0,round(p.coep)) {max_school_hour_l << int(tf.hour);}
				
				}
				travel tl <- p.travels last_with (each.motif = "studying");
				if (int(tl.hour) > 13) {
					int ind <- p.travels index_of tl;
					if (ind < (length(p.travels) - 1)) {
						
						loop times: max(1.0,round(p.coep)) {min_school_hour_end_l<<int(p.travels[ind+1].hour);}
						loop times: max(1.0,round(p.coep)) {max_school_hour_end_l<<int(p.travels[ind+1].hour);}
						
					}
					
				}
			
			}
		}
		
		int min_school_hour <- get_value(min_school_hour_l, false);
		int max_school_hour <- get_value(max_school_hour_l, true);
		int min_school_hour_end <- get_value(min_school_hour_end_l, false);
		int max_school_hour_end <- get_value(max_school_hour_end_l, true);
	
		
		list<int>  min_working_hour_l;
		list<int>  max_working_hour_l;
		list<int>  min_working_hour_end_l;
		list<int>  max_working_hour_end_l;
		
		
		
		list<int>  min_lunch_time_l;
		list<int>  max_lunch_time_l;
		
		list<int>  max_duration_lunch_l;
		
		
		int cpt;
		int cpt_outside;
		int cpt_home;
		int cpt_work_outside;
		int cpt2;
		
		
		proba_work_outside <- cpt = 0 ? 0.0 : (cpt_work_outside/cpt) with_precision 2;
		cpt <- 0;
		loop p over: people_area where ((each.occupation != "Autres personnes sans activitÃ© professionnelle") and (each.day in [1,2,4])) {
			if (p.travels first_with (each.motif = "working")) != nil {
				travel tf <- p.travels first_with (each.motif = "working");
				if (int(tf.hour) < 12) {
					loop times: max(1.0,round(p.coep)) {min_working_hour_l << int(tf.hour);}
					loop times: max(1.0,round(p.coep)) {max_working_hour_l << int(tf.hour);}
				}
				
				travel tl <- p.travels last_with (each.motif = "working");
				if (int(tl.hour) > 13) {
					int ind <- p.travels index_of tl;
					if (ind < (length(p.travels) - 1)) {
						loop times: max(1.0,round(p.coep)) {min_working_hour_end_l <<int(p.travels[ind+1].hour);}
						loop times: max(1.0,round(p.coep)) {max_working_hour_end_l <<int(p.travels[ind+1].hour);}
					}	
				}
				
				list<travel> ts <- p.travels where (each.motif in ["eating", "staying at home"]);
				list<int> hours <- ts collect int(each.hour);
				cpt <- cpt + round(p.coep);
				
				if int((p.travels[1 + (p.travels index_of tf)]).hour) >= 15 {
					cpt2 <- cpt2 + round(p.coep);
				}
				loop h over: hours {
					if h > 10 and h < 15 {
						loop times: max(1.0,round(p.coep)) {min_lunch_time_l << h;}
						loop times: max(1.0,round(p.coep)) {max_lunch_time_l << h;}
						
						int index <- hours index_of h;
						travel t <- ts[index];
					
						int id <- p.travels index_of t;
						if ((id > 0) and (id < (length(p.travels) - 1))) {
							if (p.travels[id-1].motif = "working" ) and (p.travels[id+1].motif = "working") {
								loop times: max(1.0,round(p.coep)) {max_duration_lunch_l <<int(p.travels[id+1].hour) - int(p.travels[id].hour);}
								if t.motif = "eating" {
									cpt_outside <- cpt_outside + round(p.coep);
								} else {
									cpt_home <- cpt_home + round(p.coep);
								}
						
							}
						}
					}
				}
			}
		}
		proba_lunch_at_home <- (cpt_home + cpt_outside) = 0 ? 0.0 : (cpt_home / (cpt_home + cpt_outside)) with_precision 2;
		proba_lunch_outside_workplace <- (cpt2 + cpt_home + cpt_outside) = 0 ? 0.0 : ((cpt_home + cpt_outside) / (cpt2 + cpt_home + cpt_outside)) with_precision 2;
	
		
		int min_working_hour  <- get_value(min_working_hour_l, false);
		int max_working_hour <- get_value(max_working_hour_l, true);
		int min_working_hour_end <- get_value(min_working_hour_end_l, false);
		int max_working_hour_end <- get_value(max_working_hour_end_l, true);
		int min_lunch_time <- get_value(min_lunch_time_l, false);
		int max_lunch_time <- get_value(max_lunch_time_l, true);
		max_duration_lunch <- get_value(max_duration_lunch_l, true);
		
		
		list<int> max_duration_default_l ;
	
		max_duration_default <- get_value(max_duration_default_l, true);
		
		proba_go_outside <-0.0;
			
		min_age_for_evening_act <- #max_int;
		
		
		loop p over: people_area where not empty(each.travels) {
			if int(last(p.travels).hour) > 18 {
				min_age_for_evening_act <- min(min_age_for_evening_act, int(p.age_int));
			}
		}
		cpt <- 0;
		int cpt_act;
		loop p over: people_area where ((each.age_int >= min_age_for_evening_act) and length(each.travels) >= 2)  {
			cpt <- cpt + round(p.coep);
			if int(last(p.travels).hour) > 18 {
				cpt_act <- cpt_act + round(p.coep);
			}
		}
		
		proba_activity_evening <- cpt = 0 ? 0.0 : (cpt_act/cpt) with_precision 2;
		
		
		list<int> max_num_activity_for_old_people_l;
		loop p over: people_area where (each.occupation = "RetraitÃ©s") {
			loop times: max(1.0,round(p.coep)) {max_num_activity_for_old_people_l << p.travels count (each.motif != "staying at home");}
		}
		max_num_activity_for_old_people <- get_value(max_num_activity_for_old_people_l, true);
		
		list<int> max_num_activity_for_unemployed_l;
		loop p over: people_area where (each.occupation = "Autres personnes sans activitÃ© professionnelle") {
			if empty(p.travels where (each.motif in ["working", "studying"])){
				loop times: max(1.0,round(p.coep)) {max_num_activity_for_unemployed_l << p.travels count (each.motif != "staying at home");}
			}
		}
		max_num_activity_for_unemployed <- get_value(max_num_activity_for_unemployed_l, true);
		lunch_hours_min <-min_lunch_time ;
		lunch_hours_max <- max_lunch_time ;
		
		
		work_hours_begin_min <- min_working_hour ;
		work_hours_begin_max <- max_working_hour ;
		work_hours_end_min <- min_working_hour_end ;
		work_hours_end_max <- max_working_hour_end ;
		school_hours_begin_min <- min_school_hour ;
		school_hours_begin_max <- max_school_hour ;
		school_hours_end_min <- min_school_hour_end;
		school_hours_end_max <- max_school_hour_end ;
		
	
		ask people_data {
			loop t over: travels {
				if t.motif != act_home {
					if not (t.motif in data_area.keys) {
						data_area[t.motif] <- [];
					}
					map<string,map<string,float>> od <- data_area[t.motif] ;
					string ori <- zone_EMD_to_boundary[t.zone_id];
					if not(ori in od.keys) {
						od[ori] <- [];
					}
					map<string,float> od_dest <- od[ori];
					string dest <- zone_EMD_to_boundary[t.destination];
					
					if not(t.destination in od_dest.keys) {
						od_dest[dest] <- 0.0;
					} 
					od_dest[dest] <- od_dest[dest] + t.coep;
					
				}			
			}
		} 
		
		
		
	}
	
	list<map<string,list<people_data>>> build_examples(list<int> ds) {
		list<people_data> to_consider <- people_data where (each.day in ds);
		list<map<string,list<people_data>>> data_av;
		data_av << to_consider group_by (each.age +"%" +each.occupation +"%" + each.sex);
		data_av << to_consider group_by (each.age +"%" +each.occupation );
		data_av << to_consider group_by (each.age );
		return data_av;
	}
	
	
	
	
	
}




species people {
	string age;
	string age_category;
	string sex;
	string occupation;
	list<map<int,string>> agenda <-[[],[],[],[],[],[],[]];
	
	bool is_unemployed <- false;
	int age_int;
	int sex_int;
	
	int id_area;
	int id_group;
	string current_activity;
	string current_area;
	string current_bd_type;
	string zone_emd;
	string leaving_place;
	string working_place;
	string working_area;
	string school;
	string school_area;
	
	bool is_student <- false;
	bool is_worker <- false;
	boundary homeplace;
	
	
	list<string> choose_bd_type(string activity_type) {
		map<list<string>, float> type_where <- homeplace.weights_per_activity[activity_type];
		return type_where.keys[rnd_choice(type_where.values)];
	
	}
	
	string choose_bd_type_from_type(string activity_type, string type_) {
		list<string> type_possible <- activities[activity_type];
		map<list<string>, float> type_where;
		map<string, float> data_weight <- use_data_to_choose_loc(activity_type);
		float sum_area <- 0.0; 
		loop bd_ over: boundary {
			float dist_fact <- homeplace.distances_factor[bd_];
			float at <- bd_.area_types[type_];
			type_where[[type_, bd_.id]] <- at * dist_fact; 
			sum_area <- sum_area + at;
		}
		
		return type_where.keys[rnd_choice(type_where.values)][1];
	}
	
	action init_agenda ( boundary bd) {
		current_activity <- act_home;
		homeplace <- bd;
		loop i from: 0 to: 6 {
			loop act over: agenda[i] {
				if act = act_working {
					is_worker <- true;
				} else if act = act_studying {
					is_student <- true;
				}
				
			}
		}
		
		list<string> type_possible <- activities[act_home] inter bd.area_types.keys;
		list<float> default_area <- type_possible collect (bd.area_types[each]);
		leaving_place <- type_possible[rnd_choice(default_area)];
		
		if is_worker {
			list<string> type_where <- choose_bd_type(act_working);
			 working_place <- type_where[0];
			 working_area <- type_where[1];
		}
		if is_student {
			
			loop l over: possible_schools.keys {
				list<int> v <- possible_schools[l];
				if (age_int >= min(v) and age_int <= max(v)) {
					school <- l;
					break;
				}
			}
			if school = nil {
				school <- possible_schools.keys with_max_of (max(possible_schools[each]));
			}
			school_area <- choose_bd_type_from_type(act_studying, school);
			
		}
		current_area <- string(id_area);
		current_bd_type <- leaving_place;		
	}
	
	map<string,float> use_data_to_choose_loc(string act) {
		map<string,map<string,float>> data_motif <- data_area[act] ;
		if data_motif != nil {
			return data_motif[zone_emd];
		}
		return nil;
	}
	string choose_best_loc(string act, string type_) {
		string area_c <- nil;
		if (area_c = nil) {
			if (type_ = nil)  {
				list<string> acts <- activities[act];
				if (acts =nil ) {
					write sample(act);
				}
				list<boundary> bds <- boundary where not empty(acts inter each.area_types.keys);
				if empty(bds) {
					
					write sample(act);
					write sample(activities[act]);
				}
				area_c <- (bds[rnd_choice(bds collect homeplace.distances_factor[each])]).id;
			} else {
				list<boundary> bds <- (boundary where (type_ in each.area_types.keys));
				area_c <- (bds[rnd_choice(bds collect homeplace.distances_factor[each])]).id;
			}
			
		}
		return area_c;
	}
	
	action update_agenda(int d, int h) {
		if agenda[d][h] != nil {
			current_activity <- agenda[d][h] ;
			switch current_activity {
				match act_home {
					current_area <- string(id_area);
					current_bd_type <- leaving_place;
			 	}
			 	match act_working {
					current_area <- working_area;
					current_bd_type <- working_place;
			 	}
			 	match act_studying {
					current_area <- school_area;
					current_bd_type <- school;
			 	}
			 	default {
			 		list<string> type_where <- choose_bd_type(current_activity);
			 		current_bd_type <- type_where[0];
			 		current_area <- type_where[1];
			 	}
	
			}
		}
	}
	
	action generate_agenda(int d, list<int> days_test) {
		map<int,string> agenda_day<- [];
		int cpt <- 0;
		int d_s <- days_test[0];
		loop while: empty(agenda_day) {
			map<string,list<people_data>> nt <- generation_tree[d_s][cpt];
			list<people_data> data_p;
			if cpt = 0 {
				data_p <- nt[age+"%" +occupation +"%" + sex];
			} else if cpt = 1 {
				data_p <- nt[age +"%" +occupation];
			} else {
				data_p <- nt[age];
			}
			if not empty(data_p) {
				agenda_day <- data_p[rnd_choice(data_p collect each.coep)].agenda_day;
			}
		
			if not empty(agenda_day) or cpt >= length(generation_tree[d_s]) -1{
				break;
			} else {
				cpt <- cpt + 1;
			}
		}
		//write sample(name) + " " + sample(age) + " " + sample(occupation) + " " + sample(d) + " " + sample(agenda_day);
		if empty(agenda_day) and length(days_test) > 1{
			days_test >> d_s;
			do generate_agenda(d,days_test);
		}
		agenda[d] <- agenda_day;
	}
	
	string get_value(int d, int cpt, list<string> considered_atts) {
		
		if cpt < length(considered_atts){
			return shape.attributes[considered_atts[cpt]];
		} else {
			if ((cpt - length(considered_atts)) < length(agenda[d])) {
				return agenda[d][cpt - length(considered_atts)];
			} else {
				return "";
			}
		}
	}
	
	
	action manage_active_day(int day) {
		//do console_output("manage_active_day","Azur");
		// Initialization for students or workers
			if ((is_unemployed and age_int >= max_student_age) or 
				(age_int < max_student_age and flip(1.0-schoolarship_rate))
			) {
				do manag_day_off(day);
			} else {
				map<int,string> agenda_day <- agenda[day - 1];
				list<string> possible_activities <- possible_activities_tot;
				int current_hour_;
				if (age_int < max_student_age) {
					current_hour_ <- rnd(school_hours_begin_min,school_hours_begin_max);
					agenda_day[current_hour_] <- act_studying;
				} else {
					current_hour_ <-rnd(work_hours_begin_min,work_hours_begin_max);
					agenda_day[current_hour_] <- act_studying;
				}
				bool already <- false;
				loop h from: lunch_hours_min to: lunch_hours_max {
					if (h in agenda_day.keys) {
						already <- true;
						break;
					}
				}
				if not already {
					if (flip(proba_lunch_outside_workplace)) {
						current_hour_ <- rnd(lunch_hours_min,lunch_hours_max);
						int dur <- rnd(1,2);
						if (not flip(proba_lunch_at_home)) {
							agenda_day[current_hour_] <- act_eating ;
						} else {
							agenda_day[current_hour_] <- act_home;
						}
						current_hour_ <- current_hour_ + dur;
						if (age_int < max_student_age) {
							agenda_day[current_hour_] <- act_studying;
						} else {
							agenda_day[current_hour_] <- act_working;
						}
					}
				}
				if (age_int < max_student_age) {
					current_hour_ <- rnd(school_hours_end_min,school_hours_end_max);
				} else {
					current_hour_ <-rnd(work_hours_end_min,work_hours_end_max);
				}
				agenda_day[current_hour_] <- act_home;
					
				already <- false;
				loop h2 from: current_hour_ to: 23 {
					if (h2 in agenda_day.keys) {
						already <- true;
						break;
					}
				}
				if not already and (age_int >= min_age_for_evening_act) and flip(proba_activity_evening) {
					current_hour_ <- current_hour_ + rnd(1,max_duration_lunch);
					string act <- activity_choice( possible_activities);
					current_hour_ <- min(23,current_hour_ + rnd(1,max_duration_default));
					int end_hour <- min(23,current_hour_ + rnd(1,max_duration_default));
					agenda_day[current_hour_] <- act;
					
					agenda_day[end_hour] <- act_home;
				}
				agenda[day-1] <- agenda_day;
			}
			
			
	}
	
	string activity_choice(list<string> possible_activities) {
		if (weight_activity_per_age_sex_class = nil ) or empty(weight_activity_per_age_sex_class) {
			return any(possible_activities);
		}
		loop a over: weight_activity_per_age_sex_class.keys {
			if (age_int >= a[0]) and (age_int <= a[1]) {
				map<string, float> weight_act <-  weight_activity_per_age_sex_class[a][sex_int];
				list<float> proba_activity <- possible_activities collect ((each in weight_act.keys) ? weight_act[each]:1.0 );
				if (sum(proba_activity) = 0) {return any(possible_activities);}
				return possible_activities[rnd_choice(proba_activity)];
			}
		}
		return any(possible_activities);
		
	}
	
	
	
	//specific construction of a "day off" (without work or school)
	action manag_day_off( int day) {
		map<int,string> agenda_day <- agenda[day];
		int max_act <- (age_int >= retirement_age) ? max_num_activity_for_old_people :(is_unemployed ? max_num_activity_for_unemployed : max_num_activity_for_non_working_day);
		int num_activity <- rnd(1,max_act) - length(agenda_day);
		list<int> forbiden_hours;
		bool act_beg <- false;
		int beg_act <- 0;
		loop h over: agenda_day.keys sort_by each {
			if not (act_beg) {
				act_beg <- true;
				beg_act <- h;
			} else {
				act_beg <- false;
				loop i from: beg_act to:h {
					forbiden_hours <<i;
				}
			}
		}
		int current_hour_ <- rnd(first_act_hour_non_working_min,first_act_hour_non_working_max);
		loop times: num_activity {
			if (current_hour_ in forbiden_hours) {
				current_hour_ <- current_hour_ + 1;
				if (current_hour_ > 22) {
					break;
				} 
			}
			
			int end_hour <- min(23,current_hour_ + rnd(1,max_duration_default));
			if (end_hour in forbiden_hours) {
				end_hour <- forbiden_hours first_with (each > current_hour_) - 1;
			}
			if (current_hour_ >= end_hour) {
				break;
			}
			string act <-activity_choice(possible_activities_tot);
			agenda_day[current_hour_] <- act;
			
			agenda_day[end_hour] <- act_home;
			current_hour_ <- end_hour + 1;
		}
		agenda[day] <- agenda_day;
	}
	
}
species people_data {
	int day;
	string zone_id;
	string household_id;
	string people_id;
	string age;
	int age_int;
	string age_category;
	string sex;
	string occupation;
	string working_status;
	list<travel> travels;
	float coep <- 1.0;
	map<int,string> agenda_day;
	
	action manage_leisure_sport {
		loop t over: travels {
			string val <- t.motif;
			if val = act_leisure_sport {
				int sex_id <- int(sex);
				loop gp over: proba_age_sport.keys {
					if (sex_id = gp[1]) and (age_int <= gp[0]) {
						t.motif<- flip(proba_age_sport[gp]) ? act_sport : act_leisure;
						
						//write sample(proba_age_sport[gp]) +" " + sample(t.motif);
						break;
					}
				}
				
			}
		}
	}
	
	action prepare_data {
		
		agenda_day <- [];
		loop ts over: travels {
			agenda_day[min(int(ts.hour), 23)] <- ts.motif;
		}
	}
	
	string get_value(int cpt, list<string> atts) {
		if cpt < length(atts){
			return shape.attributes[atts[cpt]];
		} else {
			int cpt_z <- cpt - length(atts);
			if (cpt_z < (length(travels) * 2)) {
				if (even(cpt_z)) {
					return travels[int(cpt_z/2)].motif;
				} else  {
					return travels[int(cpt_z/2)].hour;
				}
				
				
			} else {
				return "";
			}
		}
	}
	
}

species household_data {
	string zone_id;
	string household_id;
	int day;
}

species travel {
	string zone_id;
	string motif;
	string household_id;
	string people_id;
	string zone;
	string origin;
	string destination;
	string hour_data;
	string hour;
	int time_minute;
	
	float coep <- 1.0;
	
	
	action init_hour {
		string minutes_str <- hour_data copy_between (length(hour_data)-2,length(hour_data));
		int minutes <- int(minutes_str);
		int hours <- int(hour_data replace (minutes_str, ""));
		time_minute <- hours * 60 +  minutes;
		if minutes > 30 { hours <- hours + 1;}
		hour <- string(hours);
	}
	
	
}

species boundary {
	string id;
	map<int,list<list<map<string,map<string,map<string,float>>>>>> agenda;
	list<zone_EMD> my_zones;
	list<int> compartments_inhabitants ;
	map<string,float> area_types;
	
	map<boundary,float> distances_factor;
	
	map<string, map<list<string>, float>> weights_per_activity;
	
	map<string,float> use_data_to_choose_loc(string act) {
		map<string,map<string,float>> data_motif <- data_area[act] ;
		if data_motif != nil {
			return data_motif[id];
		}
		return nil;
	}
	
	action update_agenda_compartment(map<string,map<string,map<string,float>>> agenda_hour, string current_area, string current_activity, string current_bd_type) {
		if (current_area = nil) or (current_activity = nil) or (current_bd_type = nil) {
			write sample(current_area) +" " + sample(current_activity) +" " + sample(current_bd_type);
		
		}
		if not (current_area in agenda_hour.keys ) {
			agenda_hour[current_area] <- [];
		}
		map<string,map<string,float>> agenda_h_s <- agenda_hour[current_area];
	
		if not (current_activity in agenda_h_s.keys ) {
			agenda_h_s[current_activity] <- [];
		}
		map<string,float> agenda_h_s_a <- agenda_h_s[current_activity];
		
		
		if not(current_bd_type in agenda_h_s_a.keys) {
			agenda_h_s_a[current_bd_type] <- 1.0;
		} else {
			agenda_h_s_a[current_bd_type] <- agenda_h_s_a[current_bd_type]  + 1.0;
		}
	}
	
	action init_weights {
		loop act over: possible_activities_tot {
			weights_per_activity[act]<- weight_bd_type_area(act, nil);
		}
		weights_per_activity[act_working]<- weight_bd_type_area(act_working,possible_workplaces);
	}
	
	map<list<string>, float> weight_bd_type_area(string activity_type, map<string,float> weights) {
		list<string> type_possible <- activities[activity_type];
		map<list<string>, float> type_where;
		map<string, float> data_weight <- use_data_to_choose_loc(activity_type);
		float sum_area <- 0.0; 
		loop bd_ over: boundary {
			float dist_fact <- distances_factor[bd_];
			loop type over: type_possible {
				float at <- bd_.area_types[type];
				type_where[[type, bd_.id]] <- at * dist_fact; 
				sum_area <- sum_area + at;
				
			}
		}
		if data_weight != nil {
			loop tw over: type_where.keys {
				type_where[tw] <- type_where[tw] /sum_area + ((tw[1] in data_weight) ? data_weight[tw[1]] : 0.0) ; 
			}
		}
		
		if weights != nil {
			loop tw over: type_where.keys {
				type_where[tw] <- type_where[tw] * ((tw[0] in weights.keys) ? weights[tw[0]] : 0.0);
			}
		}
			
		return type_where;
	}
	
	
	
}

species zone_EMD {
	int district;
	string id;
	aspect default {
		draw shape color: #gray border: #black;
	}
}
experiment GenerateAgenda type: gui {
	output {
		display map {
			species zone_EMD;
		}
	}
}

