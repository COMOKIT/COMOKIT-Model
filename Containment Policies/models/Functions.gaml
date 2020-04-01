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
	float get_rnd_from_distribution(string type, float param_1, float param_2)
	{
		return type="Lognormal"?lognormal_rnd(param_1,param_2):(type="Weibull"?weibull_rnd(param_1,param_2):(type="Gamma"?gamma_rnd(param_1,param_2):gauss_rnd(param_1,param_2)));
	}
	//Time between exposure and symptom onset (Lognormal)
	float get_incubation_time
	{
		return get_rnd_from_distribution(distribution_type_incubation,parameter_1_incubation,parameter_2_incubation)*nb_step_for_one_day;
	}
	
	//Time between onset and onset of secondary case (Normal)
	float get_serial_interval
	{
		return get_rnd_from_distribution(distribution_type_serial_interval, parameter_1_serial_interval, parameter_2_serial_interval)*nb_step_for_one_day;
	}
	
	//Time between onset and recovery (Lognormal)
	float get_infectious_time
	{
		return get_rnd_from_distribution(distribution_type_onset_to_recovery,parameter_1_onset_to_recovery,parameter_2_onset_to_recovery)*nb_step_for_one_day;
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