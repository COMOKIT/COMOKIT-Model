/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/


@no_experiment
model Species_Individual

import "../Constants.gaml"
import "../Parameters.gaml"
import "../Functions.gaml"
import "Building.gaml"
import "Activity.gaml"
import "Authority.gaml"

global
{
	int total_number_of_infected <- 0;
}


species Individual  {
	int ageCategory;
	int sex; //0 M 1 F
	bool wearMask;
	Building home;
	Building school;
	Building office;
	list<Individual> relatives;
	geometry bound;
	
	
	string status; //S,E,Ua,Us,A,R,D
	float incubation_time; 
	float infectious_time;
	float serial_interval;
	
	
	map<int, Activity> agenda_week;
	Activity last_activity;
	bool free_rider;
	int tick <- 0;
	
	action defineNewCase
	{
		total_number_of_infected <- total_number_of_infected +1;
		self.status <- exposed;
		self.incubation_time <- world.get_incubation_time();
		self.serial_interval <- world.get_serial_interval();
		self.infectious_time <- world.get_infectious_time();
		
		if(serial_interval<0)
		{
			infectious_time <- infectious_time - serial_interval;
			incubation_time <- incubation_time + serial_interval;
		}
		self.tick <- 0;
	}
	
	bool is_infectious {
		return [asymptomatic,symptomatic_without_symptoms, symptomatic_with_symptoms ] contains status;
	}
	
	bool is_exposed {
		return status = exposed;
	}
	
	bool is_infected {
		return self.is_infectious() or self.is_exposed();
	}

	reflex infectOthers when: self.is_infectious()
	{
		ask (Individual where ((flip(successful_contact_rate)) and (each.status = susceptible) and ((each.location distance_to self.location) <= contact_distance)))
		 	{
					do defineNewCase;
		 	}
	}
	
	reflex becomeInfectious when: self.is_exposed() and(tick >= incubation_time)
	{
		if(world.is_asymptomatic())
		{
			status <- asymptomatic;
			tick <- 0;
		}
		else
		{
			if(serial_interval<0)
			{
				status <- symptomatic_without_symptoms;
				tick <- 0;
			}
			else
			{
				status <- symptomatic_with_symptoms;
				tick <- 0;
			}
		}
	}
	
	reflex becomeSymptomatic when: (status=symptomatic_without_symptoms) and (tick>=serial_interval)
	{
		status <- symptomatic_with_symptoms;
	}
	
	reflex becomeNotInfectious when: ((status=symptomatic_with_symptoms) or (status=asymptomatic))and(tick>=infectious_time)
	{
		if(status = symptomatic_with_symptoms)
		{
			if(world.is_fatal())
			{
				status <- dead;
			}
			else
			{
				status <- recovered;
			}
		}
		else
		{
			status <- recovered;
		}
	}
	
	
	reflex executeAgenda {
		Activity act <- agenda_week[current_date.hour];
		if (act != nil) { 
			if (Authority[0].allows(self, act)) {
				bound <- any(act.find_target(self));
				location <- any_location_in(bound);
			}

		}
	}

	reflex updateDiseaseCycle when:(status!=recovered)or(status!=dead) {
		tick <- tick + 1;
	}

	aspect default {
		draw shape color: status = exposed ? #pink : ((status = symptomatic_with_symptoms)or(status=asymptomatic)or(status=symptomatic_without_symptoms)? #red : #green);
	}

}