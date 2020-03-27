/***
* Name: Functions
* Author: damien
* Description: 
* Tags: Tag1, Tag2, TagN
***/


model Functions
import "Constants.gaml"
import "Parameters.gaml"

/* Insert your model definition here */

global
{
	//Time between exposure and symptom onset (Lognormal)
	float get_incubation_time
	{
		return lognormal_rnd(1.57,0.65)*24;
	}
	
	//Time between onset and onset of secondary case (Normal)
	float get_serial_interval
	{
		return gauss_rnd(3.96,3.75)*24;
	}
	
	//Time between onset and recovery (Lognormal)
	float get_infectious_time
	{
		return lognormal_rnd(log(20.8),0.34)*24;
	}
	
	bool is_asymptomatic
	{
		return flip(proportion_asymptomatic);
	}
	
	bool is_fatal
	{
		return flip(proportion_dead_symptomatic);
	}
	
}