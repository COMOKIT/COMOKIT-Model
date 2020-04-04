/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Constants

global {
	string susceptible <- "S";
	string exposed <- "E";
	string asymptomatic <- "A";
	string symptomatic_without_symptoms <- "Ua";
	string symptomatic_with_symptoms <- "Us";
	string recovered <- "R";
	string dead <- "D";
	
	string not_tested <- "Not tested";
	string tested_positive <- "Positive";
	string tested_negative <- "Negative";
	
	string act_neighbor <- "visiting neighbor";
	string act_friend <- "visiting friend";
	string act_home <- "staying at home";
	string act_working <- "working";
	string act_studying <- "studying";
	string act_eating <- "eating";
	string act_shopping <- "shopping";
	string act_leisure <- "leisure";
	string act_outside <- "outside activity";
	string act_sport <- "sport";
	string act_other <- "other activity";
	
	
	
	// OSM Constant (type of building)
	list<string> OSM_eat <- ["restaurant","bakery"];
	list<string> OSM_home <- ["yes","house", "manor","apartments",'chocolate','shoes',"caravan"];
	list<string> OSM_shop <- ['commercial','supermarket',"bakery","frozen_food","alcohol","retail","furniture","bicycle"];
	list<string> OSM_outside_activity <- [];
	list<string> OSM_leisure <- [];
	list<string> OSM_sport <- ['tennis','multi','basketball','soccer','rugby_league','swimming','cycling','pelota','boules','skateboard','beachvolleyball','athletics'];
	list<string> OSM_other_activity <- ['car_repair','garages','church','hairdresser',"chapel","memorial","ruins"];
	list<string> OSM_work_place <- ['office',"estate_agent","public","civic","government","manufacture","company"];
	list<string> OSM_school <- ["school"];
	
	int epidemiological_csv_column_name <- 0;
	int epidemiological_csv_column_age <- 1;
	int epidemiological_csv_column_detail <- 2;
	int epidemiological_csv_column_parameter_one <- 3;
	int epidemiological_csv_column_parameter_two <- 4;
	string epidemiological_csv_transmission_human <- "Transmission_human";
	string epidemiological_csv_transmission_building <- "Transmission_building";
	string epidemiological_csv_basic_viral_decrease <- "Basic_viral_decrease";
	string epidemiological_csv_fixed <- "Fixed";
	string epidemiological_csv_lognormal <- "Lognormal";
	string epidemiological_csv_normal <- "Normal";
	string epidemiological_csv_weibull <- "Weibull";
	string epidemiological_csv_gamma <- "Gamma";
	string epidemiological_csv_uniform <- "Uniform";
	string epidemiological_csv_successful_contact_rate_human <- "Successful_contact_rate_human";
	string epidemiological_csv_successful_contact_rate_building <- "Successful_contact_rate_building";
	string epidemiological_csv_reduction_asymptomatic <-"Reduction_asymptomatic";
	string epidemiological_csv_proportion_asymptomatic <- "Proportion_asymptomatic";
	string epidemiological_csv_basic_viral_release <- "Basic_viral_release";
	string epidemiological_csv_probability_true_positive <- "Probability_true_positive";
	string epidemiological_csv_probability_true_negative <- "Probability_true_negative";
	string epidemiological_csv_proportion_wearing_mask <- "Proportion_wearing_mask";
	string epidemiological_csv_reduction_wearing_mask <- "Reduction_wearing_mask";
	string epidemiological_csv_incubation_period <-"Incubation_period";
	string epidemiological_csv_serial_interval <- "Serial_interval";
	string epidemiological_csv_proportion_hospitalization <- "Proportion_hospitalization";
	string epidemiological_csv_proportion_icu <- "Proportion_icu";
	string epidemiological_csv_proportion_death_symptomatic <- "Proportion_death_symptomatic";
	string epidemiological_csv_onset_to_recovery <- "Onset_to_recovery";
	
}