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
	bool load_epidemiological_parameter_from_file <- false;
	int nb_infected <- 0 update: length(pseudo_individual where (each.is_infected));
	int nb_infectious <- 0 update: length(pseudo_individual where (each.is_infectious));
	int nb_perma_asymptomatic <- 0 update: length(pseudo_individual where (each.status=asymptomatic));
	int nb_temp_asymptomatic <- 0 update: length(pseudo_individual where (each.status=symptomatic_without_symptoms));
	int nb_symptomatic<- 0 update: length(pseudo_individual where (each.status=symptomatic_with_symptoms));
	int nb_exposed<- 0 update: length(pseudo_individual where (each.status=exposed));
	int nb_susceptible<- 0 update: length(pseudo_individual where (each.status=susceptible));
	int nb_recovered<- 0 update: length(pseudo_individual where (each.status=recovered));
	int nb_dead<- 0 update: length(pseudo_individual where (each.status=dead));
	list<int> age_categories <- list(0,15,30,45,60,75);
	map<int,int> nb_cases_incubation;
	map<int,int> nb_cases_serial_interval;
	map<int,int> nb_cases_recovery;
	map<int,int> nb_cases_death_symptomatic;
	map<int,int> nb_cases_symptomatic;
	map<int,int> nb_cases;
	map<int,int> age_distribution;
	int nb_individual <- 1000;
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
			age <- rnd(0,90);
			age_category <- get_age_category();
			do initialize;
			ask world 
			{
				do add_to_map(age_distribution,myself.age_category,1);
			}
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
	}
	
	action add_to_map(map<int,int> a_map,int key,int value)
	{
		if(a_map.keys contains key)
		{
			a_map[key] <- a_map[key]+value;
		}
		else
		{
			add value to: a_map at: key;
		}
	}
	reflex stop{
		if(length(pseudo_individual where(each.counted_as_infected))=nb_individual){
			stop <- true;
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
	
	int get_age_category
	{
		loop aCategory from:0 to: length(age_categories)-2
		{
			if(self.age>=age_categories[aCategory] and self.age<age_categories[aCategory+1])
			{
				return aCategory;
			}
		}
		return length(age_categories)-1;
	}
	
	reflex update_counted_infected when:self.is_infected=true and self.counted_as_infected=false
	{
		if(counted_as_infected=false)
		{
			ask world
			{
				do add_to_map(nb_cases,myself.age_category,1);
				do add_to_map(nb_cases_incubation,round(myself.incubation_time),1);
				do add_to_map(nb_cases_serial_interval,round(myself.serial_interval),1);
				do add_to_map(nb_cases_recovery,round(myself.infectious_time),1);
			}
			counted_as_infected <- true;
		}
	}
	
	reflex update_symptomatic when: self.status=symptomatic_with_symptoms and self.counted_as_symptomatic=false
	{
		if(counted_as_symptomatic=false)
		{
			ask world
			{
				do add_to_map(nb_cases_symptomatic,myself.age_category,1);
			}
			counted_as_symptomatic <- true;
		}
	}
	reflex update_counted_dead when:self.status=dead and self.counted_as_dead=false
	{
		if(counted_as_dead=false)
		{
			ask world
			{
				do add_to_map(nb_cases_death_symptomatic,myself.age_category,1);
			}
			counted_as_dead <- true;
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
		
		display "age_distribution"
		{
			chart "Age distribution" type:histogram background:#white  color: #black
			{
				loop anAgeIndex from:0 to: length(age_categories)-1
				{
					if(anAgeIndex=length(age_categories)-1)
					{
						data string(">"+age_categories[anAgeIndex]) value:age_distribution[anAgeIndex] color:#grey;
					}
					else
					{
						data string(""+age_categories[anAgeIndex]+"-"+age_categories[anAgeIndex+1]) value:age_distribution[anAgeIndex]  color:#grey;
					}
				}
			}
		}
		
		display "cases age distribution"
		{
			chart "Cases age distribution" type:histogram background:#white  color: #black
			{
				loop anAgeIndex from:0 to: length(age_categories)-1
				{
					if(anAgeIndex=length(age_categories)-1)
					{
						data string(">"+age_categories[anAgeIndex]) value:nb_cases[anAgeIndex] color:#grey;
					}
					else
					{
						data string(""+age_categories[anAgeIndex]+"-"+age_categories[anAgeIndex+1]) value:nb_cases[anAgeIndex] color:#grey;
					}
				}
			}
		}
		
		display "deaths age distribution"
		{
			chart "SIFR age distribution" type:histogram background:#white  color: #black
			{
				loop anAgeIndex from:0 to: length(age_categories)-1
				{
					if(anAgeIndex=length(age_categories)-1)
					{
						data string(">"+age_categories[anAgeIndex]) value:nb_cases_symptomatic[anAgeIndex]>0?nb_cases_death_symptomatic[anAgeIndex]/nb_cases_symptomatic[anAgeIndex]:0 color:#grey;
					}
					else
					{
						data string(""+age_categories[anAgeIndex]+"-"+age_categories[anAgeIndex+1]) value:nb_cases_symptomatic[anAgeIndex]>0?nb_cases_death_symptomatic[anAgeIndex]/nb_cases_symptomatic[anAgeIndex]:0 color:#grey;
					}
				}
			}
		}
		
		display "incubation period distribution"
		{
			chart "incubation period distribution" type:histogram background:#white  color: #black
			{
				loop anIncubationTime over: nb_cases_incubation.keys
				{
					data string(anIncubationTime) value:nb_cases_incubation[anIncubationTime] color:#grey;
				}
			}
		}
		
		display "serial interval distribution"
		{
			chart "serial interval distribution" type:histogram background:#white  color: #black
			{
				loop aSerialInterval over: nb_cases_serial_interval.keys
				{
					if(aSerialInterval = 0)
					{
						data "Zero" value:100 color:#red;
					}
					data string(aSerialInterval) value:nb_cases_serial_interval contains aSerialInterval?nb_cases_serial_interval[aSerialInterval]:0 color:#grey;
				}
			}
		}
		
		display "time recovery distribution"
		{
			chart "time recovery distribution" type:histogram background:#white  color: #black
			{
				loop aRecovery over: nb_cases_recovery.keys
				{
					data string(aRecovery) value:nb_cases_recovery[aRecovery] color:#grey;
				}
			}
		}
	}
}