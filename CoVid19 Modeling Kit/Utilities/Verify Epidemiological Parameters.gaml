/***
* Part of the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Damien Philippon
* Tags: covid19,epidemiology
***/

model CoVid19

import "../Model/Entities/Individual.gaml"
import "../Model/Global.gaml"
import "../Model/Parameters.gaml"
/* Insert your model definition here */

global
{
	geometry shape <- square(1000#m);
	int max_age <- 90;
	bool load_epidemiological_parameter_from_file <- true;
	string epidemiological_parameters <- "../Parameters/Epidemiological Parameters.csv"; //File for the parameters
	
	string dataset <- "../Datasets/Vinh Phuc/"; // default
	file shp_boundary <- file_exists(dataset+"boundary.shp") ? shape_file(dataset+"boundary.shp"):nil;
	file shp_buildings <- file_exists(dataset+"buildings.shp") ? shape_file(dataset+"buildings.shp"):nil;

	
	file csv_parameters <- file_exists(epidemiological_parameters)?csv_file(epidemiological_parameters):nil;
	int nb_infected <- 0 update: length(pseudo_individual where (each.is_infected));
	int nb_infectious <- 0 update: length(pseudo_individual where (each.is_infectious));
	int nb_perma_asymptomatic <- 0 update: length(pseudo_individual where (each.status=asymptomatic));
	int nb_temp_asymptomatic <- 0 update: length(pseudo_individual where (each.status=symptomatic_without_symptoms));
	int nb_symptomatic<- 0 update: length(pseudo_individual where (each.status=symptomatic_with_symptoms));
	int nb_exposed<- 0 update: length(pseudo_individual where (each.status=exposed));
	int nb_susceptible<- 0 update: length(pseudo_individual where (each.status=susceptible));
	int nb_recovered<- 0 update: length(pseudo_individual where (each.status=recovered));
	int nb_dead<- 0 update: length(pseudo_individual where (each.status=dead));
	int nb_individual <- 1000;
	int num_infected_init <- 1;
	list<int> test <- list(0,1,2,3,4,5,6,7,8,9,10);
	bool stop <- false;
	init { 
		do init_epidemiological_parameters;
		create pseudo_bound number:1
		{
			shape <- world.shape;
		}
		
		create pseudo_individual number:nb_individual
		{
			is_at_home <- false;
			age <- rnd(0,90);
			do initialize;
			bound <- first(pseudo_bound);
		}
		
		ask num_infected_init among pseudo_individual {
			do defineNewCase;
		}
		
		ask num_recovered_init among pseudo_individual where(each.is_infected=false)
		{
			do set_status(recovered);
		}
		
		total_number_individual <- length(pseudo_individual);
		
		save ["NAME","AGE","VALUE"] to: "recovery.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "serial.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "true_serial.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "incubation.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "hospitalization.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "ICU.csv" type:"csv" header:false rewrite:true;
		save ["NAME","AGE","VALUE"] to: "stay_ICU.csv" type:"csv" header:false rewrite:true;
	}
	
	
	reflex stop{
		if(nb_infected=0){
			stop <- true;
			do pause;
		}
	}
}
species pseudo_bound parent:Building
{
	list<pseudo_individual> individuals;
}

species pseudo_individual parent:Individual
{
	
	int age;
	bool wearMask;
	bool is_outside <- false;
	pseudo_bound bound;
	
	string status <- susceptible; //S,E,Ua,Us,A,R,D
	string report_status <- not_tested; //Not-tested, Negative, Positive
	bool is_infectious <- define_is_infectious();
	bool is_infected <- define_is_infected();
	bool is_asymptomatic <- define_is_asymptomatic();
	
	float incubation_time; 
	float infectious_time;
	float serial_interval;
	
	bool free_rider <- false;
	int tick <- 0;
	
	int age_category;
	bool counted_as_infected <- false;
	bool counted_as_dead <- false;
	bool counted_as_symptomatic <- false;
	
	action defineNewCase
	{
		total_number_of_infected <- total_number_of_infected +1;
		do set_status(exposed);
		self.incubation_time <- world.get_incubation_time(self.age);
		self.serial_interval <- world.get_serial_interval(self.age);
		self.infectious_time <- world.get_infectious_time(self.age);
		
		save [self.name, self.age,self.infectious_time] to: "recovery.csv" type:"csv" header:false rewrite:false;
		save [self.name, self.age,self.incubation_time] to: "incubation.csv" type:"csv" header:false rewrite:false;
		
		save [self.name, self.age,self.serial_interval] to: "serial.csv" type:"csv" header:false rewrite:false;
		if(serial_interval<0)
		{
			if(abs(serial_interval)>incubation_time)
			{
				serial_interval <- -incubation_time;
			}
			self.infectious_time <- max(0,self.infectious_time - self.serial_interval);
			self.incubation_time <- max(0,self.incubation_time + self.serial_interval);
		}
		
		save [self.name, self.age,self.serial_interval] to: "true_serial.csv" type:"csv" header:false rewrite:false;
		self.tick <- 0;
	}
	
	action set_hospitalization_time{
		if(world.is_hospitalized(self.age))
		{
			time_before_hospitalization <- status=symptomatic_without_symptoms? abs(self.serial_interval)+world.get_time_onset_to_hospitalization(self.age,self.infectious_time):world.get_time_onset_to_hospitalization(self.age,self.infectious_time);
			if(time_before_hospitalization>infectious_time)
			{
				time_before_hospitalization <- infectious_time;
			}
			save [self.name, self.age,self.time_before_hospitalization] to: "hospitalization.csv" type:"csv" header:false rewrite:false;
		
			if(world.is_ICU(self.age))
			{
				time_before_ICU <- world.get_time_hospitalization_to_ICU(self.age, self.time_before_hospitalization);
				save [self.name, self.age,self.time_before_ICU] to: "ICU.csv" type:"csv" header:false rewrite:false;
				time_stay_ICU <- world.get_time_ICU(self.age);
				save [self.name, self.age,self.time_stay_ICU] to: "stay_ICU.csv" type:"csv" header:false rewrite:false;
				if(time_before_hospitalization+time_before_ICU>=infectious_time)
				{
					time_before_hospitalization <- infectious_time-time_before_ICU;
				}
			}
		}
	}
	
	reflex executeAgenda when: status!=dead{
		if(stop=false)
		{
			do enter_building(one_of(pseudo_bound));
		}
		else
		{
			is_outside <- true;
		}
	}
	aspect default {
		if not is_outside {
			draw shape color: status = exposed ? #pink : ((status = symptomatic_with_symptoms)or(status=asymptomatic)or(status=symptomatic_without_symptoms)? #red : #green);
		}
	}
}

experiment check_epidemiology type:gui
{
	
	output
	{
		//layout #split consoles: true editors: false navigator: false tray: false tabs: false toolbars: false;
		display "map" 
		{
			species pseudo_bound {
				draw shape color:  viral_load>0?rgb(255*viral_load,0,0):#lightgrey empty: true width: 2;
			}
			agents pseudo_individual  value: pseudo_individual{
				draw square(status=susceptible or status=recovered? 10: 20) color: status = exposed ? #yellow : (self.is_infectious ? #orangered : (status = recovered?#blue: (status=dead?#black:#green))) ;	
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
	}
}