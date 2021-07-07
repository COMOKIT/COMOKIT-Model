/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* A model verifying that the epidemiologcal parameters do not break 
* the epidemiological model behind COMOKIT
* 
* Author: Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/

model CoVid19

import "../Model/Entities/Individual.gaml"
import "../Model/Global.gaml"
import "../Model/Parameters.gaml"

global
{
	geometry shape <- square(1000#m);
	int max_age <- 90;
	bool load_epidemiological_parameter_from_file <- true;
	string epidemiological_parameters <- "../Parameters/Epidemiological Parameters.csv"; //File for the parameters
	
	string dataset <- "../Datasets/Vinh Phuc/"; // default
	file shp_boundary <- file_exists(dataset+"boundary.shp") ? shape_file(dataset+"boundary.shp"):nil;
	file shp_buildings <- file_exists(dataset+"buildings.shp") ? shape_file(dataset+"buildings.shp"):nil;

	
	int nb_individual <- 1000;
	int num_infected_init <- 1;
	file csv_parameters <- file_exists(epidemiological_parameters)?csv_file(epidemiological_parameters):nil;
	int nb_infected <- num_infected_init update: length(pseudo_individual where (each.is_infected));
	int nb_infectious <- 0 update: length(pseudo_individual where (each.is_infectious));
	int nb_perma_asymptomatic <- 0 update: length(pseudo_individual where (each.state=asymptomatic));
	int nb_temp_asymptomatic <- 0 update: length(pseudo_individual where (each.state=presymptomatic));
	int nb_symptomatic<- 0 update: length(pseudo_individual where (each.state=symptomatic));
	int nb_exposed<- 0 update: length(pseudo_individual where (each.state=latent));
	int nb_susceptible<- 0 update: length(pseudo_individual where (each.state=susceptible));
	int nb_recovered<- 0 update: length(pseudo_individual where (each.clinical_status=recovered));
	int nb_dead<- 0 update: length(pseudo_individual where (each.clinical_status=dead));
	list<int> test <- list(0,1,2,3,4,5,6,7,8,9,10);
	bool stop <- false;
	init { 
		do create_authority;
		do init_epidemiological_parameters;
		
		create pseudo_individual number:nb_individual
		{
			age <- rnd(0,90);
			do initialise_epidemio;
		}
		
		ask num_infected_init among pseudo_individual {
			do define_new_case;
		}
		
		total_number_individual <- length(pseudo_individual);
		
		save ["NAME","AGE","VALUE"] to: "recovery.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "serial.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "incubation.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "hospitalisation.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "ICU.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "stay_ICU.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "status.csv" type:"csv" header:true rewrite:true;
	}
	
	
	reflex stop{
		if(nb_infected=0 and cycle>0){
			stop <- true;
			ask pseudo_individual{
				save [self.name,self.age,self.infectious_period] to: "recovery.csv" type:"csv" header:false rewrite:false;
				save [self.name,self.age,self.presymptomatic_period] to: "serial.csv" type:csv header:false rewrite:false;
				save [self.name,self.age,self.latent_period] to: "latent.csv" type:csv header:false rewrite:false;
				save [self.name,self.age,self.time_symptoms_to_hospitalisation] to: "hospitalisation.csv" type:csv header:false rewrite:false;
				save [self.name,self.age,self.time_hospitalisation_to_ICU] to: "ICU.csv" type:csv header:false rewrite:false;
				save [self.name,self.age,self.time_stay_ICU] to: "stay_ICU.csv" type:csv header:false rewrite:false;
				save [self.name,self.age,self.clinical_status] to: "status.csv" type:csv header:false rewrite:false;
			}
			do pause;
		}
	}
}

species pseudo_individual parent:BiologicalEntity
{
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: is_infectious
	{
		//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		float reduction_factor <- 1.0;
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic;
		}
		
		//Perform human to human transmission
		if allow_transmission_human {
			float proba <- contact_rate*reduction_factor;
			list<pseudo_individual> fellows <- pseudo_individual where (flip(proba) and (each.state = susceptible));
			ask fellows {
				do define_new_case;
			}
	 	}
		
	}
	aspect default {
		draw shape color: state = latent ? #pink : ((state = symptomatic)or(state=asymptomatic)or(state=presymptomatic)? #red : #green);
	}
}

experiment check_epidemiology type:gui
{
	
	output
	{
		display "map" 
		{
			
			agents pseudo_individual  value: pseudo_individual{
				draw square(state=susceptible or state=recovered? 10: 20) color: state = latent ? #yellow : (self.is_infectious ? #orangered : (state = recovered?#blue: (clinical_status=dead?#black:#green))) ;	
			}
		}
		
		display "chart"
		{
			chart "Model" type:series background:#black  color: #white
			{
				data "Susceptible" value: nb_susceptible color:#green marker:false ;
				data "Exposed" value: nb_exposed color:#gold marker:false;
				data "Asymptomatic P" value: nb_perma_asymptomatic color:#orange marker:false;
				data "Asymptomatic T" value: nb_temp_asymptomatic color:#red marker:false;
				data "Symptomatic" value: nb_symptomatic color:#silver marker:false;
				data "Recovered" value: nb_recovered color:#blue marker:false;
				data "Dead" value: nb_dead color:#white marker:false;
			}
		}
		display "charts Deaths" toolbar: false background: #black  refresh: every(24 #cycle) {
			chart "Dead cases" background: #black axes: #black color: #white legend_font: font("Helvetica", 14, #bold) title_visible: true {
				loop s over: simulations {
					data "Deaths" value: nb_dead color: #red marker: false style: line	 thickness: 2;
				}
			}
		}
	}
}