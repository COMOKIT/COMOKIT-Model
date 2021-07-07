/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Declares a set of global constants used throughout COMOKIT.
* 
* Author: Benoit Gaudou, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment

model CoVid19


global {
	
	//State of an individual
	string susceptible <- "susceptible";
	string latent <- "latent";
	string presymptomatic <- "presymptomatic";
	string asymptomatic <- "asymptomatic";
	string symptomatic <- "symptomatic";
	string removed <- "removed"; //Removed means that the agent is not infectious anymore, for death or recovery, use the clinical status
	
	//Diagnostic status of the individual
	string not_tested <- "Not tested";
	string tested_positive <- "Positive";
	string tested_negative <- "Negative";
	
	//Clinical status of the individual
	string dead <- "Dead";
	string recovered <- "Recovered";
	string no_need_hospitalisation <- "Not needed";
	string need_hospitalisation <- "Need hospitalisation";
	string need_ICU <- "Need ICU";

	//The list of activities
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
	
	//Type of model for building choice during activity
	string random <- "random";
	string gravity <- "gravity";
	string closest <- "closest";
	
	//Modifier headers for configuration files
	string WEIGHT <- "WEIGHT";
	string RANGE <- "RANGE";
	string SPLIT <- "::";
	
	//List of demogrphic attributes
	string AGE <- "age";
	string SEX <- "sex";
	string EMP <- "is_unemployed";
	string HID <- "household_id";
	string IID <- "individual_id";
	
	//Epi attributes
	string COMORBIDITIES <- "comorbidities";
	
	//Virus and variant
	string SARS_CoV_2 <- "SARS-CoV-2";
	
	//number of the column for the epidemiological parameters CSV file
	int epidemiological_csv_column_name <- 0; //Name of the parameter
	//  From last column  - python like syntax  ;)
	int epidemiological_csv_params_number <- 3; // Number of parameter per epistemological variable x entry
	
	// Default para of the epidemiological distribution
	list<string> epidemiological_csv_entries <- [AGE,SEX,COMORBIDITIES];
	// TODO  : there is a huge issue related to the fact that biological entities does not have Sex var.
	list<int> epidemiological_default_entry <- [-1,-1,-1];
	
	// Available distributions to parameter the epidemiological values of the model
	string epidemiological_fixed <- "Fixed";
	string epidemiological_lognormal <- "Lognormal";
	string epidemiological_normal <- "Normal";
	string epidemiological_weibull <- "Weibull";
	string epidemiological_gamma <- "Gamma";
	string epidemiological_uniform <- "Uniform";
	
	// Virus specific parameter value
	string epidemiological_successful_contact_rate_human <- "Successful_contact_rate_human";
	string epidemiological_successful_contact_rate_building <- "Successful_contact_rate_building";
	string epidemiological_factor_asymptomatic <-"Factor_asymptomatic";
	string epidemiological_proportion_asymptomatic <- "Proportion_asymptomatic";
	string epidemiological_probability_true_positive <- "Probability_true_positive";
	string epidemiological_probability_true_negative <- "Probability_true_negative";
	string epidemiological_incubation_period_symptomatic <-"Incubation_period_symptomatic";
	string epidemiological_incubation_period_asymptomatic <-"Incubation_period_asymptomatic";
	string epidemiological_serial_interval <- "Serial_interval";
	string epidemiological_proportion_hospitalisation <- "Proportion_hospitalisation";
	string epidemiological_onset_to_hospitalisation <- "Onset_to_hospitalisation";
	string epidemiological_proportion_icu <- "Proportion_icu";
	string epidemiological_hospitalisation_to_ICU <- "Hospitalisation_to_ICU";
	string epidemiological_stay_ICU <- "Stay_ICU";
	string epidemiological_proportion_death_symptomatic <- "Proportion_death_symptomatic";
	string epidemiological_infectious_period_symptomatic <- "Infectious_period_symptomatic";
	string epidemiological_infectious_period_asymptomatic <- "Infectious_period_asymptomatic";
	string epidemiological_allow_viral_individual_factor <- "Allow_viral_individual_factor";
	string epidemiological_immune_evasion <- "Immune_evasion";
	string epidemiological_reinfection_probability <- "Re_infection_probability";
	
	// General epidemiological parameters
	string epidemiological_viral_individual_factor <- "Viral_individual_factor";
	string epidemiological_factor_wearing_mask <- "Factor_wearing_mask";
	string epidemiological_basic_viral_release <- "Basic_viral_release";
	string epidemiological_transmission_human <- "Transmission_human";
	string epidemiological_transmission_building <- "Transmission_building";
	string epidemiological_basic_viral_decrease <- "Basic_viral_decrease";
	
	//Behavioral parameters
	string epidemiological_proportion_wearing_mask <- "Proportion_wearing_mask";
	string proportion_antivax <- "Proportion_antivax";
	
	//Vaccines
	string vaccine_infection_prevention <- "Prevent infection case";
	string vaccine_symptomatic_prevention <- "Prevent symptomatic case";
	string vaccine_sever_cases_prevention <- "Prevent sever case";
	
}