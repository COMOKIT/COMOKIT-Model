/***
* Name: Functions
* Author: damien
* Description: 
* Tags: Tag1, Tag2, TagN
***/


model Functions
import "Constants.gaml"
import "Parameters.gaml"
import "Global.gaml"

/* Insert your model definition here */

global
{
	float get_rnd_from_distribution(string type, float param_1, float param_2)
	{
		return type=epidemiological_csv_lognormal?lognormal_rnd(param_1,param_2):(type=epidemiological_csv_weibull?weibull_rnd(param_1,param_2):(type=epidemiological_csv_gamma?gamma_rnd(param_1,param_2):(type=epidemiological_csv_normal?gauss_rnd(param_1,param_2):rnd(param_1,param_2))));
	}
	
	float get_contact_rate_human(int age)
	{
		return float(map_epidemiological_parameters[age][epidemiological_csv_successful_contact_rate_human][1])/nb_step_for_one_day;
	}
	
	float get_contact_rate_building
	{
		return successful_contact_rate_building/nb_step_for_one_day;
	}
	
	float get_reduction_contact_rate_asymptomatic(int age)
	{
		return float(map_epidemiological_parameters[age][epidemiological_csv_reduction_asymptomatic][1]);
	}
	
	float get_basic_viral_release(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_csv_basic_viral_release][0]=epidemiological_csv_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_csv_basic_viral_release][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_csv_basic_viral_release][0],float(map_epidemiological_parameters[age][epidemiological_csv_basic_viral_release][1]),float(map_epidemiological_parameters[age][epidemiological_csv_basic_viral_release][2]))*nb_step_for_one_day;
		}
	}
	
	//Time between exposure and symptom onset (Lognormal)
	float get_incubation_time(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_csv_incubation_period][0]=epidemiological_csv_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_csv_incubation_period][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_csv_incubation_period][0],float(map_epidemiological_parameters[age][epidemiological_csv_incubation_period][1]),float(map_epidemiological_parameters[age][epidemiological_csv_incubation_period][2]))*nb_step_for_one_day;
		}
	}
	
	//Time between onset and onset of secondary case (Normal)
	float get_serial_interval(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_csv_serial_interval][0]=epidemiological_csv_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_csv_serial_interval][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_csv_serial_interval][0],float(map_epidemiological_parameters[age][epidemiological_csv_serial_interval][1]),float(map_epidemiological_parameters[age][epidemiological_csv_serial_interval][2]))*nb_step_for_one_day;
		}
	}
	
	//Time between onset and recovery (Lognormal)
	float get_infectious_time(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_csv_onset_to_recovery][0]=epidemiological_csv_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_csv_onset_to_recovery][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_csv_onset_to_recovery][0],float(map_epidemiological_parameters[age][epidemiological_csv_onset_to_recovery][1]),float(map_epidemiological_parameters[age][epidemiological_csv_onset_to_recovery][2]))*nb_step_for_one_day;
		}
	}
	
	float get_reduction_contact_rate_wearing_mask(int age)
	{
		return float(map_epidemiological_parameters[age][epidemiological_csv_reduction_wearing_mask][1]);
	}
	
	bool is_asymptomatic(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_csv_proportion_asymptomatic][1]));
	}
	
	bool is_true_positive(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_csv_probability_true_positive][1]));
	}
	
	bool is_true_negative(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_csv_probability_true_negative][1]));
	}
	
	bool is_hospitalized(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_csv_proportion_hospitalization][1]));
	}
	
	bool is_ICU(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_csv_proportion_icu][1]));
	}
	
	
	bool is_fatal(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_csv_proportion_death_symptomatic][1]));
	}
	
	bool is_wearing_mask(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_csv_proportion_wearing_mask][1]));
	}
	
	
}