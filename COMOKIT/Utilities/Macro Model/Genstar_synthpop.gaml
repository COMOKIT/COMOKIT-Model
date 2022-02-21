/******************************************************************
 * Name: Genstarsynthpop
 *   
 * Release ****
 * Author: kevinchapuis
 * Tags: Synthetic population, genstar, GIS
 ******************************************************************/

model Genstarsynthpop 


global {
	
	bool TEST_MODE <- false;
	
	
	string folder_path <- "../../Datasets/";
	string dataset <- "Alpes-Maritimes";
	// The case study
	string case_study_path <- folder_path + dataset +"/";
	string folder_generated <- case_study_path+"generated/";
		
	shape_file boundary_file <- shape_file(case_study_path+ "/SynthPop/commune.shp");

	shape_file buildings_shape_file <- shape_file(case_study_path + "/SynthPop/buildings.shp");

	shape_file EMD_shapefile <- shape_file(case_study_path + "Agenda/ZF_EMD2008_rubbersheet.shp");
	string travel_path <- case_study_path + "Agenda/DEPLACEMENT.csv";
	string household_path <- case_study_path + "Agenda/MENAGE.csv";
	string people_path <- case_study_path + "Agenda/PERSONNE.csv";
	string folder_coep <- folder_path + "Agenda/Coep_files";
	
	string agenda_path <- case_study_path+"generated/agenda.csv";
	
	geometry shape <-envelope(boundary_file);
	
	int min_numbers <- 25;
	
	// --------------------------------------------
	// Genstar Individual into household generation
	// --------------------------------------------
	
	csv_file pop6_age_x_gender_x_csp0_csv_file <- csv_file(case_study_path + "SynthPop/pop6_age_x_gender_x_csp.csv");
	csv_file rp2017_td_pop1B0_csv_file <- csv_file(case_study_path + "SynthPop/rp2017_td_pop1B.csv");
		
	// Population overall size, with expansion factor (upscale population for optimization)
	int pop_size <- 20000;
	float expansion_factor <- 1.3;
	
	// Individual variables
	list<string> tranches_age <- ["Moins de 4 ans","5 à 9 ans","10 à 14 ans","15 à 19 ans", "20 à 24 ans", "25 à 29 ans", 
								"30 à 34 ans", "35 à 39 ans", "40 à 44 ans", "45 à 49 ans", "50 à 54 ans", "55 à 59 ans", 
								"60 à 64 ans","65 à 69 ans","70 à 74 ans","75 à 79 ans","80 à 84 ans","85 à 89 ans",
								"90 à 94 ans","95 à 99 ans","100 ans ou plus"];							 
	list<string> tranches_age_agg <- ["15 à 19 ans", "20 à 24 ans", "25 à 29 ans", "30 à 34 ans", "35 à 39 ans", "40 à 44 ans", 
								"45 à 49 ans", "50 à 54 ans", "55 à 59 ans", "60 à 64 ans", "65 ans ou plus"];
	list<string> var_gender <- ["Homme","Femme"];
	list<string> var_pro <- ["Agriculteurs exploitants","Artisans commerçants chefs d'entreprise","Cadres et professions intellectuelles supérieures",
								"Professions intermédiaires","Employés","Ouvriers","Retraités","Autres personnes sans activité professionnelle"];
	
	map<list<string>,list<string>> mapperage <- [
				["15 à 19 ans"]::["15 à 19 ans"], ["20 à 24 ans"]::["20 à 24 ans"], ["25 à 29 ans"]::["25 à 29 ans"],
				["30 à 34 ans"]::["30 à 34 ans"], ["35 à 39 ans"]::["35 à 39 ans"], ["40 à 44 ans"]::["40 à 44 ans"],
				["45 à 49 ans"]::["45 à 49 ans"], ["50 à 54 ans"]::["50 à 54 ans"], ["55 à 59 ans"]::["55 à 59 ans"],
				["60 à 64 ans"]::["60 à 64 ans"], ["65 ans ou plus"]::["65 à 69 ans","70 à 74 ans","75 à 79 ans",
											"80 à 84 ans","85 à 89 ans", "90 à 94 ans","95 à 99 ans","100 ans ou plus"]
			];
	
	// Household roles
	string HEAD <- "Head";
	string M_HEAD <- "Male Head";
	string F_HEAD <- "Femal Head";
	string SPOUSE <- "Spouse";
	string CHILD <- "Child";
	string OTHER_RELATIVES <- "Relative";
	list<string> ROLE_LIST <- [HEAD,SPOUSE,CHILD,OTHER_RELATIVES];
	
	// Parameters to twiks algorithm that build households
	int max_age <- 120;
	int max_age_relax <- 10;
	int max_nb_child <- 6;
	
	int min_head_age <- 16;
	int max_age_child <- 30;
	int min_age_spouse <- 18;
	
	float proba_homo_parentality <- 0.03;
	
	list<int> age_gap_child_parent <- [-16,-22,10,-40]; // min age gap, average, std, max age gap
	list<int> age_gap_wife <- [-25,-3,8,15]; 
	list<int> age_gap_husband <- [-15,3,8,25]; 
	
	
	
	
	// ----------------------------------
	// Genstar localisation of households
	// ----------------------------------
	file pop_square_file;
	
	string pop_output_path <- folder_generated+"boundary.shp"; 
	
	
	int age_step <- 10;
	int age_max <- 100;
	

	init {
		
	
		write "Start of the population generation process";
		
		
			create building from: buildings_shape_file {
				functions <- type split_with "$";
			}
			
			create boundary from: boundary_file;
			map<string, list<boundary>> group_name <- boundary group_by each.name;
			loop n over: group_name.keys {
				list<boundary> bd <- group_name[n];
				if length(bd)> 1 {
					
					loop i from: 1 to: length(bd) - 1 {
						ask bd[i] {do die;}
					}	
				}
			}
			ask boundary {
				list<building> bds <- building overlapping self;
				list<string> type <- remove_duplicates(bds accumulate each.functions);
				id <- string(int(self));	
				map<string, float> area_types <- type as_map (each::0.0);
				loop bd over: bds {
					loop fct over: bd.functions {
						area_types[fct] <- area_types[fct] + bd.shape.area;
					}	
				}
				types <- "";
				loop t over: type {
					types <- types + (t +"::" + area_types[t] +"$");
				}
				
			}
			
			ask building {do die;}
		
			 
		
			if not TEST_MODE {
				pop_size <- int(boundary sum_of each.population);
			}
			
		ask experiment {
			do compact_memory;
		}
	
		write "Spatial objects generated - pop to generate: " + pop_size ;
		
		// GENSTAR GENERATION SETUP
		
		if TEST_MODE {pop_size <- round(pop_size*expansion_factor); }
		
		
		 			
	 	gen_population_generator pop_gen;
		pop_gen <- pop_gen with_generation_algo "Direct Sampling";
		
	 	pop_gen <- add_census_file(pop_gen, pop6_age_x_gender_x_csp0_csv_file.path, "ContingencyTable", ",", 2, 1);
		
		pop_gen <- add_census_file(pop_gen, rp2017_td_pop1B0_csv_file.path, "ContingencyTable", ",", 1, 1);
	
		// AGE								
			
		pop_gen <- pop_gen add_range_attribute ("Age", tranches_age, 0, max_age);
		
		pop_gen <- pop_gen add_mapper ("Age", gen_range, mapperage);
									
		// GENDER

		pop_gen <- pop_gen add_attribute ("Sex", string, var_gender);
	
		// PROFESSIONAL STATUS
	
		pop_gen <- pop_gen add_attribute ("Activity", string, var_pro);
	
		// CREATE POPULATION OF INDIVIDUAL
		if TEST_MODE { generate species: dummy_agent from: pop_gen number: pop_size*expansion_factor attributes:[]; }
		else { generate species: dummy_agent from: pop_gen number: pop_size attributes:[]; }
		
	 	write "Population generation process setup";
		// ---------------------------------------------- //
		//												  //
		// START BUILDING HOUSEHOLD FROM GEN* INDIVIDUALS //
		//												  //
		// ---------------------------------------------- //
	
	
		// ************  STEP 1  ***********
		//  Set up the distributions Size and composition of the household
		// 
	
		csv_file menage_aggTable_10_csv_file <- csv_file(case_study_path + "SynthPop/menage_agg-Table 1.csv");
		
		map<string,int> hh_composition <- ["Couple sans enfant"::2,"Couple avec enfant"::2,
			"Famille monoparentale composée d'un homme avec enfant(s)"::1,"Famille monoparentale composée d'une femme avec enfant(s)"::1];
		map<string,pair> hh_children_number <- ["Aucun enfant de moins de 25 ans"::pair(0,0),"1 enfant de moins de 25 ans"::pair(1,1),
			"2 enfants de moins de 25 ans"::pair(2,2),"3 enfants de moins de 25 ans"::pair(3,3),"4 enfants ou plus de moins de 25 ans"::pair(4,max_nb_child)];
		
		csv_file td_femmeTable_10_csv_file <- csv_file(case_study_path + "SynthPop/td_femme-Table 1.csv");
		csv_file td_hommeTable_10_csv_file <- csv_file(case_study_path + "SynthPop/td_homme-Table 1.csv");
		
		list<string> hh_size <- ["1 personne","2 personnes","3 personnes","4 personnes","5 personnes","6 personnes ou plus"];
		map<string,list<int>> head_age <- ["Moins de 20 ans"::[min_head_age,19],"20 à 24 ans"::[20,24],"25 à 29 ans"::[25,29],
									"30 à 34 ans"::[30,34],"35 à 39 ans"::[35,39],"40 à 44 ans"::[40,44],"45 à 49 ans"::[45,49],
									"50 à 54 ans"::[50,54],"55 à 59 ans"::[55,59],"60 à 64 ans"::[60,64],"65 à 69 ans"::[65,69],
									"70 à 74 ans"::[70,74],"75 à 79 ans"::[75,79],"80 ans ou plus"::[80,max_age]];
		
		// PREPARE AND STORE PROBABILITIES OF HOUSEHOLD HEAD
		map<int, map<pair<string,list<int>>, int>> age_gender_head_distribution <- hh_size as_map (int(first(each))::map<pair<string,list<int>>, int>([]));
		loop i from:0 to:length(head_age)-1 {
			loop j from:1 to:length(hh_size) {
				int hh_size_key <- int(first(hh_size[j-1]));
				list<int> age_key <- head_age[head_age.keys[i]];
				age_gender_head_distribution[hh_size_key][pair<string, list<int>>(pair(last(var_gender),age_key))] <- int(td_femmeTable_10_csv_file.contents[j,i]);
				age_gender_head_distribution[hh_size_key][pair<string, list<int>>(pair(first(var_gender),age_key))] <- int(td_hommeTable_10_csv_file.contents[j,i]);
			}
		} 
		
		write "-- Distribution to elicit the head of household defined";
		
		
		// TODO : proportion of single person household
		
		pair<string,string> lone_person_household <- "Personne seule"::"Aucun enfant de moins de 25 ans";
		int single_phh <- sum(age_gender_head_distribution[1].values);
		int couple_hh <- sum([2,3,4,5,6] accumulate age_gender_head_distribution[each].values);
		
		float actual_sphh_prop <- single_phh / (single_phh+couple_hh);
		write "Proportion of single person household is "+actual_sphh_prop;
		
		
		// PREPARE AND STORE PROBABILITIES OF HOUSEHOLD COMPOSITION
		map<pair<string,string>,int> hh_composition_distribution;
				
		loop compo over:hh_composition.keys {
			loop nb_child over:hh_children_number.keys {
				int i <- hh_composition.keys index_of compo;
				int j <- hh_children_number.keys index_of nb_child + 1;
				int contingency <- int(menage_aggTable_10_csv_file.contents[j,i]);
				if contingency > 0 { hh_composition_distribution[pair(compo,nb_child)] <- int(menage_aggTable_10_csv_file.contents[j,i]); }
			}
		}
		
		// TODO : add single person household to the distribution
		
		int actual_couple_hh <- sum(hh_composition_distribution.values);
		int estimated_single_person_hh <- round(actual_couple_hh * actual_sphh_prop / (1-actual_sphh_prop));
		
		float estimated_sphh_prop <- estimated_single_person_hh / (actual_couple_hh+estimated_single_person_hh);
		if abs(estimated_sphh_prop - actual_sphh_prop) > 0.01 {
			error "The actual and estimated proportion of single person household mismatch: \n"
				+sample(actual_sphh_prop)+" | "+sample(estimated_sphh_prop);
		}
		
		hh_composition_distribution[lone_person_household] <- estimated_single_person_hh;
		
		write "-- Distribution to elicit composition of household defined";
		
		// Draw a head profile according to household compositions
		//list<dummy_agent> remaining_person <- list(dummy_agent);
		map<int,list<dummy_agent>> remaining_person <- dummy_agent group_by each.Age; 
		 
		//************  STEP 2  ***********
		//  Set up a distribution to elicit
		 // the head of household
		 //
				
		// Build theoretical households (not the proper people but only the wrigth number)
		int people_left <- not TEST_MODE ? length(dummy_agent) : pop_size;
		loop while: people_left > 0 {
			create dummy_household {
				pair compo <- rnd_choice(hh_composition_distribution);
				
				switch compo.key {
					match_one ["Couple sans enfant","Couple avec enfant"] { theoretical_composition <- [HEAD,SPOUSE]; }
					match "Famille monoparentale composée d'un homme avec enfant(s)" { theoretical_composition <- [M_HEAD]; }
					match "Famille monoparentale composée d'une femme avec enfant(s)" { theoretical_composition <- [F_HEAD]; }
					default { theoretical_composition <- [HEAD]; }
				}
				
				theoretical_composition <<+ list_with(rnd(int(hh_children_number[compo.value].key),int(hh_children_number[compo.value].value)),CHILD);
				
				people_left <- people_left - length(theoretical_composition);
				
			}
		}
		
		write " Size and composition of the household defined";
		 
		// ************  STEP 3  ***********
		 // Set up a distribution to elicit
		//  the head of household
		 //
		
		
		int cpt <- 0;
		int nb_people <- length(dummy_agent);
		ask dummy_household {
			cpt <- cpt + 1;
			if (cpt mod int(length(dummy_household)/100) = 0) {
				write "processing houshold generation: " + int(cpt * 100 / length(dummy_household)) + "%";
			}
			int hh_size_key <- length(theoretical_composition) > 6 ? 6 : length(theoretical_composition); 
			map<pair<string,list<int>>,int> agh_distribution <- age_gender_head_distribution[hh_size_key];
			// Filter distribution to only take into account head that are women
			if theoretical_composition contains F_HEAD { 
				agh_distribution <- agh_distribution.keys where (each.key=last(var_gender)) as_map (each::agh_distribution[each]);
				theoretical_composition >- F_HEAD;
				theoretical_composition <+ HEAD;
			} 
			// Filter distribution to only take into account head that are men
			if theoretical_composition contains M_HEAD { 
				agh_distribution <- agh_distribution.keys where (each.key=first(var_gender)) as_map (each::agh_distribution[each]);
				theoretical_composition >- M_HEAD;
				theoretical_composition <+ HEAD;
			} 
			
			// Find a head of household
			pair<string,list<int>> the_head_gender_age <- rnd_choice(agh_distribution);
			pair<int,int> head_relage <- first(the_head_gender_age.value)-min_head_age::max_age_relax;
			
			dummy_agent possible_head <- world.find_someone_with_iterative_relax(
				remaining_person, the_head_gender_age.value, the_head_gender_age.key, nil, head_relage
			);
			
		 	if possible_head = nil {
		 		write("Remaining number of household to fill = "+length(dummy_household count (each.head = nil))+" ("+length(dummy_household)+" expected)");
		 		error "Failing to retrieve a "+the_head_gender_age.key+" head of household aged between "+the_head_gender_age.value; break;
		 	}
			
			remaining_person[possible_head.Age] >- add_member(possible_head,HEAD);
			nb_people <- nb_people - 1;
			
			if nb_people > 0 and not(empty(theoretical_composition)) {
				int nb_bef <- length(theoretical_composition);
				if theoretical_composition contains SPOUSE {
					string spouse_gender <- flip(proba_homo_parentality) ? head.Sex : first(var_gender - head.Sex);
					list<int> spouse_age <- world.get_age_gap(head, SPOUSE, head.Sex=spouse_gender);
					pair<int,int> spouse_relage <- (first(spouse_age)-min_age_spouse)::max_age_relax;
					// TODO : homophilic rule for activity ???
					dummy_agent possible_spouse <- world.find_someone_with_iterative_relax(remaining_person, spouse_age, spouse_gender, nil, spouse_relage);
					
					if possible_spouse = nil {error "have not been able to find a spouse: "+spouse_gender+" | "+spouse_age
						+" among "+length(remaining_person)/float(length(dummy_agent))*100+"% remaining person";
					} 
					
					remaining_person[possible_spouse.Age] >- add_member(possible_spouse,SPOUSE);
					nb_people <- nb_people - 1;
	
				
				}
				
				if nb_people > 0 and theoretical_composition contains CHILD {
					dummy_agent youngest_parent <- family where ([HEAD,SPOUSE] contains each.role) with_min_of (each.Age);
					loop times:theoretical_composition count (each = CHILD) {
						
						list<int> child_age <- world.get_age_gap(youngest_parent, CHILD);
						pair<int,int> child_relage <- (first(child_age)<max_age_relax?first(child_age):max_age_relax)::max_age_child-last(child_age);
						dummy_agent possible_child <- world.find_someone_with_iterative_relax(remaining_person, child_age, nil, nil, child_relage);
						
						if possible_child = nil {error "have not been able to find a child between "+first(child_age)+" and "+last(child_age)+" years old"
							+" among "+length(remaining_person)/float(length(dummy_agent))*100+"% remaining person";
						}
						
						remaining_person[possible_child.Age] >- add_member(possible_child,CHILD);
						nb_people <- nb_people - 1;
						if (nb_people = 0) {break;}
				
					}
					
				}
				
				if nb_people > 0 and theoretical_composition contains OTHER_RELATIVES {
					loop times:theoretical_composition count (each = OTHER_RELATIVES) {
						
				
						dummy_agent possible_other <- world.find_someone_with_iterative_relax(remaining_person, [16,max_age], nil,nil);
						if possible_other = nil {error "have not been able to find an agent with age between 16 and "+max_age
							+" among "+nb_people/float(length(dummy_agent))*100+"% remaining person";
						}
						
						remaining_person[possible_other.Age] >- add_member(possible_other,OTHER_RELATIVES);
						nb_people <- nb_people - 1;
						if (nb_people = 0) {break;}
						
					}
				
					
				}
				if (nb_bef >= length(theoretical_composition) and not empty(theoretical_composition)) {
					theoretical_composition >> one_of (theoretical_composition);
					write "something weird is happening";
				}
				
			}
			
		}
		write "Population generated";
		
		
		

		// --------------------------- //
		//							   //
		// START LOCALIZING HOUSEHOLD  //
		//							   //
		// --------------------------- //
		
	
		//write " nb people : " + length(dummy_agent);
		//write "nb household: " + length(dummy_household);
		
		//write "nb places in buildings: " + sum_places;
		//write "total households - real: " + pop_square sum_of (each.Men);
		//write "total people - real: " + pop_square sum_of (each.Ind);
		
		
		list<boundary> places <- list(boundary);
		cpt <- 0;
		bool random_selection <- false;
	
		ask shuffle(dummy_household){
			cpt <- cpt + 1;
			if (cpt mod int(length(dummy_household)/100) = 0) {
				write "processing localization: " + int(cpt * 100 / length(dummy_household)) + "%";
			}
			home <-  one_of(random_selection ? boundary : places);
			home.num_people <- home.num_people  + length(family);
			if not random_selection and (home.num_people >= home.population) {
				places >> home;
			}
			if (empty(places)) {
				random_selection <- true;
			}
			location <- any_location_in(home);
		}
		
		write "Population localized";
	
		// ************  STEP 4  ***********
		//  Save population to a csv and localization to a shapefile
		 //
		
		
		ask dummy_agent {
			if (Age < 6) {
				Age_cat <- "3";
			} else if (Age < 19) {
				Age_cat <- "15";
			}else if (Age < 26) {
				Age_cat <- "22";
			}else if (Age < 36) {
				Age_cat <- "30";
			}else if (Age < 51) {
				Age_cat <- "45";
			}else if (Age < 66) {
				Age_cat <- "55";
			}else if (Age < 86) {
				Age_cat <- "75";
			} else {
				Age_cat <- "85";
			}
			if Sex = "Homme" {Sex <- "0";} else {Sex<-"1";}
			if Activity in ["Agriculteurs exploitants","Artisans commerçants chefs d'entreprise","Cadres et professions intellectuelles supérieures",
								"Professions intermédiaires","Employés","Ouvriers"] {
				Activity_cat <- "worker";						
			}
			else  {
				Activity_cat <- "non worker";						
			}
			id_cat <- Age_cat +"%"+ Sex +"%"+Activity_cat;
		}
		int nb_tot;
		
		
		ask boundary {
			list<dummy_agent> people_in <- (dummy_household overlapping self) accumulate each.family;
			map<string,list<dummy_agent>> group_agents <- people_in group_by each.id_cat;
			num_cat <- group_agents.keys as_map (each :: length(group_agents[each]));
			
			categories <- "";
			bool still_continue <- true;
			loop while: still_continue {
				bool cont <- false;
				loop cat over: num_cat.keys sort_by (num_cat[each]){
					if num_cat[cat] < min_numbers {
						list<string> occupation_values <-["worker", "non worker"];
						list<string> sex_values <-["0", "1"];
						list<string> age_values <-["3", "15", "22", "30", "45", "55", "75", "85"];
						loop while: true {
							if  length(occupation_values) = 1 and length(age_values) = 1 and length(sex_values) = 1{
								break;
							}
							string new_value <- world.find_closest(cat,occupation_values,sex_values,age_values );
							if new_value in  num_cat.keys {
								num_cat[new_value] <- num_cat[new_value] + num_cat[cat];
								remove key: cat from: num_cat;
								cont <- true;
								break;
							}
						}
						if cont {
							break;
						}
					}
				}
				still_continue <- cont;
				
			}
		}
		int tot_remove <- 0;
		ask boundary {
			loop cat over: num_cat.keys {
				if num_cat[cat] < min_numbers {
					write sample(cat) +" " + sample(num_cat[cat]);
					tot_remove <- tot_remove + num_cat[cat];
				}// else {
					categories <- categories + cat +"::" + num_cat[cat] +"$";
					nb_tot <- nb_tot + num_cat[cat] ;
				//}
				
			}			
		}
		write sample(nb_tot) +" " + sample(tot_remove);
		
		
		
		save boundary type:shp to: pop_output_path attributes: ["name", "population","categories", "types"];
		

		write "Population saved";		
		
		
	}
	
	string find_closest(string val,list<string> occupation_values,list<string> sex_values,  list<string> age_values ) {
		list<string> vv <- (val split_with "%");
			
		if length(occupation_values) >1 {
			string n_v;
			if vv[2] = "worker" {
				n_v <- "non worker";
			} else {
				n_v <- "non worker";
			}
			occupation_values >> n_v;
			return vv[0] +"%"+ vv[1] +"%"+ n_v;
		} else if length(age_values) >1  {
			string n_v;
			string c <- vv[0];
			int index <- age_values index_of c;
			if index < 0 {write c +" " + age_values;}
			if (index = 0) {index <- 1;  }
			else if (index = (length(age_values) - 1)) {index <- index - 1;  }
			else {
				index <- index + (flip(0.5) ? -1 : 1);
			}
			n_v <- age_values[index];
			age_values >> n_v;
			return n_v + "%"+ vv[1] + "%" + vv[2];
		} else {
			string n_v;
			if vv[1] = "0" {
				n_v <- "1";
			} else {
				n_v <- "0";
			}
			sex_values >> n_v;
			return vv[0] +"%"+ n_v + "%"+ vv[2];
		
		}
	}
	
	
	/*
	 * Find a person with age, gender and activity with relaxation criterion for each
	 */
	dummy_agent find_someone_with(map<int,list<dummy_agent>> draw_within, 
		list<int> ages, 
		string gen <- nil, string pro <- nil, list<string> pro_relax <- [] 
	) {
		dummy_agent ag;
		list<string> acts;
		if (pro != nil) {
			acts<- pro_relax+pro;
		}
		loop age over: shuffle(ages) {
			list<dummy_agent> ags <- draw_within[age];
			if ags != nil and not empty(ags) {
				if (pro = nil) {
					if (gen = nil) {
						ag <- one_of(ags);
					}
					else {
						ag <- ags first_with (each.Sex = gen);
					}
				} else {
					if (gen = nil) {
						ag <- ags first_with (acts contains each.Activity);
					} else {
						ag <- ags first_with ((each.Sex = gen) and (acts contains each.Activity));
					}
				}
			}
			if ag !=nil{ 
				break;
			}
		}
		return ag;
	}
	
	/*
	 * Find a person iteratively relaxing the age constraint and gender (when half of available relaxation iteration are done)
	 */
	dummy_agent find_someone_with_iterative_relax(map<int,list<dummy_agent>> draw_within, 
		list<int> ager, string gen, string activity, pair iter_relax <- 10::10) {
		int age_min <- max(0,ager[0]);
		int age_max_ <- min(max_age, ager[1]);
		int age_relax_min <- max(0,age_min - iter_relax.key);
		int age_relax_max <- min(max_age,age_max_ + iter_relax.value);
		dummy_agent the_chosen_one <- nil;
		
		int itr <- 0; 
		list<int> ages;
		loop i from: age_min to: age_max_  {
			ages <<i;
		}
		int iter_max <- max(age_min - age_relax_min,age_relax_max-age_max_);
		loop while:the_chosen_one = nil  {
			the_chosen_one <- find_someone_with(draw_within, ages,gen,activity);
			if (the_chosen_one = nil) {
				itr <- itr + 1;
				ages <- [];
				
				if (age_min - itr) >= 0 {ages << (age_min - itr);}
				if (age_max_ + itr) <= max_age  {ages << (age_max_ + itr);}
				
				if (itr > iter_max) and (gen != nil or activity != nil) {
					gen <- nil; activity <-nil;itr <- 0;
					loop i from: age_min to: age_max_  {
							ages <<i;
						}
				}
				
				if empty(ages) and (age_min - itr) < 0 and (age_max_ + itr) > max_age {
					list<dummy_agent> ags <- draw_within.values accumulate each;
					if empty(ags) {
						break;
					} else {
						the_chosen_one <- one_of(ags);
					}
				
				}		
				
			} else {
				break;
			} 
			
			
		} 
		return the_chosen_one;
	}
	
	/*
	 * Draw age gap
	 */
	list<int> get_age_gap(dummy_agent referent, string role, bool homo <- false) {
		list<int> age_range;
		
		switch role {
			match CHILD {
				int minage <- max(0, referent.Age + age_gap_child_parent[1] - rnd(age_gap_child_parent[2]));
				int maxage <- max(referent.Age+first(age_gap_child_parent), referent.Age + age_gap_child_parent[1] + rnd(age_gap_child_parent[2])); 
				age_range <- [
					minage>max_age_child?(max_age_child+minage-maxage):minage,
					maxage>max_age_child?max_age_child:maxage
				];
			}
			match SPOUSE { 
				list<int> dist_age_gap <- referent.Sex = first(var_gender) ? age_gap_wife : age_gap_husband;
				loop times:2 { 
					int rnd_age <- round(gauss(referent.Age + dist_age_gap[1], dist_age_gap[2]));
					
					rnd_age <- rnd_age < referent.Age + first(dist_age_gap) ? 
						referent.Age + first(dist_age_gap) : rnd_age;
					
					rnd_age <- rnd_age > referent.Age + last(dist_age_gap) ?
						referent.Age + last(dist_age_gap) : rnd_age;
					
					rnd_age <- rnd_age < min_age_spouse ? min_age_spouse : rnd_age; 
					
					age_range <+ rnd_age;
				}
				
			}
		} 
		
		return age_range sort_by each;
	}
	
	// POP SYNTH STATS //
	
	// 1st list = gender
	// 2nd list = age
	// 3rd list = activity
	matrix<int> get_age_activity_data {
		matrix data <- matrix(pop6_age_x_gender_x_csp0_csv_file);
		
		matrix output <- {length(tranches_age_agg),length(var_pro)} matrix_with 0;
		
		loop a from:0 to:length(tranches_age_agg)-1 {
			loop p from:0 to:length(var_pro)-1 {
				output[{a,p}] <- int(data[a,p*2]) + int(data[a,p*2+1]);
			}
		}
		
		return output;
	}
	
	matrix<int> get_age_activity_pop {
		map<string, pair<int,int>> mapage <- ["15 à 19 ans"::(15::19), "20 à 24 ans"::(20::24), "25 à 29 ans"::(25::29), 
			"30 à 34 ans"::(30::34), "35 à 39 ans"::(35::39), "40 à 44 ans"::(40::44), "45 à 49 ans"::(45::49), 
			"50 à 54 ans"::(50::54), "55 à 59 ans"::(55::59), "60 à 64 ans"::(60::64), "65 ans ou plus"::(65::120)];
		matrix output <- {length(tranches_age_agg),length(var_pro)} matrix_with 0;
		
		loop a from:0 to:length(tranches_age_agg)-1 {
			loop p from:0 to:length(var_pro)-1 {
				output[{a,p}] <- dummy_agent count (each.Activity = var_pro[p] and
					mapage[tranches_age_agg[a]].key <= each.Age and each.Age <= mapage[tranches_age_agg[a]].value
				);
			}
		}
		
		return output;
	}
	
	matrix<int> get_age_gender_pop {
		map<string, pair<int,int>> mapage <- ["Moins de 4 ans"::(0::4),"5 à 9 ans"::(5::9),
			"10 à 14 ans"::(10::14), "15 à 19 ans"::(15::19), "20 à 24 ans"::(20::24), "25 à 29 ans"::(25::29), 
			"30 à 34 ans"::(30::34), "35 à 39 ans"::(35::39), "40 à 44 ans"::(40::44), "45 à 49 ans"::(45::49), 
			"50 à 54 ans"::(50::54), "55 à 59 ans"::(55::59), "60 à 64 ans"::(60::64), "65 à 69 ans"::(65::69),
			"70 à 74 ans"::(70::74), "75 à 79 ans"::(75::79), "80 à 84 ans"::(80::84), "85 à 89 ans"::(85::89),
								"90 à 94 ans"::(90::94),"95 à 99 ans"::(95::99),"100 ans ou plus"::(100::120)];
		matrix output <- {length(tranches_age),length(var_gender)} matrix_with 0;
		loop a from:0 to:length(tranches_age)-1 {
			loop g from:0 to:length(var_gender)-1 {
				output[{a,g}] <- dummy_agent count (each.Sex = var_gender[g] and
					mapage[tranches_age[a]].key <= each.Age and each.Age <= mapage[tranches_age[a]].value
				);
			}
		}
		
		return output;
	}
	
}

species building {
	string type;
	list<string> functions;
}
species dummy_agent {
	int Age;
	string Age_cat;
	string Activity_cat;
	string Sex;
	string Activity; 
	
	dummy_household household;
	string role;
	string id_cat;
	
}

species dummy_household {
	
	boundary home;
	list<string> theoretical_composition;
	list<dummy_agent> family;
	dummy_agent head;
	
	dummy_agent add_member(dummy_agent new_member, string role) {
		if not(ROLE_LIST contains role) {error "Unknown role "+role;} 
		if (role=HEAD and head!=nil) {error "Cannot add a head in this household because there is already one";}
		if not(theoretical_composition contains role) {error "There is no theoretical space for this role (remainings: "+theoretical_composition+")";}
		
		if role=HEAD { head <- new_member; }
		family <+ new_member;
		new_member.household <- self;
		new_member.role <- role;
		theoretical_composition >> role;
		
		return new_member;
	}
	
	boundary best_loc(list<boundary> places) {
								
		boundary sq <- places with_max_of (each.population - each.num_people);
		
		return sq;
	}
	
	aspect default {
		draw circle(20) color: #red border: #black;
	}
	
}

species boundary {
	string types;
	int population;
	int num_people;
	string id;
	map<string,int> num_cat;
	string categories;
	aspect default { draw shape color: #blue wireframe: true; }
}

experiment generate type:gui {
	output {
		display map type: opengl{
			species boundary ;
			species dummy_household;
		}	
	
		display age {
			chart "ages" type: histogram {
				loop i from: 0 to: 110 {
					data ""+i value: dummy_agent count(each.Age = i);
				}
			}
		}
		
		display chart_csp {
			chart "csp" type: histogram {
				loop csp over: var_pro {
					data ""+csp value: dummy_agent count(each.Activity = csp);
				}
			}
		}		
		
		display s { 
			chart "sex" type: pie {
				loop se over: var_gender {
					data se value: dummy_agent count(each.Sex = se);
				}
			}
		}
		
		display roles {
			chart "household role composition" type: histogram {
				loop r over: [HEAD, SPOUSE, CHILD, OTHER_RELATIVES] {
					data r value: mean(dummy_household collect (each.family count (each.role = r)));
				}
			}
		}
		
		display household_size {
			chart "household size" type: histogram {
				list<int> sizes <- remove_duplicates(dummy_household collect length(each.family));
				loop s over:sizes sort (each) { data string(s) value: dummy_household count (length(each.family)=s); }
			}
		}
	}
}