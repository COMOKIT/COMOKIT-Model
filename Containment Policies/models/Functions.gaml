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
		return rnd(3,14);
	}
	
	//Time between onset and onset of secondary case (Normal)
	float get_serial_interval
	{
		return rnd(6,18);
	}
	
	//Time between onset and recovery (Gamma)
	float get_infectious_time
	{
		return rnd(16,28);
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