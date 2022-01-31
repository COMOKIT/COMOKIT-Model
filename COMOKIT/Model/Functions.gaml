/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Declares a set of global functions used throughout COMOKIT (principally 
* by the epidemiological sub-model)
* 
* Author: Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/


@no_experiment

model CoVid19

import "Constants.gaml"
import "Parameters.gaml"
 
global
{
	//Function to get a value from a random distribution (among Normal, Lognormal, Weibull, Gamma and Uniform)
	float get_rnd_from_distribution(string type, float param_1, float param_2)
	{
		switch type {
			match (epidemiological_lognormal) { return lognormal_rnd(param_1,param_2); }
			match (epidemiological_weibull) { return weibull_rnd(param_1,param_2); }
			match (epidemiological_gamma) { return gamma_rnd(param_1,param_2); }
			match (epidemiological_normal) { return gauss_rnd(param_1,param_2); }
			default {return rnd(param_1,param_2);}
		}
		// return type=epidemiological_lognormal?lognormal_rnd(param_1,param_2):(type=epidemiological_weibull?weibull_rnd(param_1,param_2):(type=epidemiological_gamma?gamma_rnd(param_1,param_2):(type=epidemiological_normal?gauss_rnd(param_1,param_2):rnd(param_1,param_2))));
	}
	
	//Function to get a value from a random distribution (among Normal, Lognormal, Weibull, Gamma and Uniform)
	float get_rnd_from_distribution_with_threshold(string type, float param_1, float param_2, float threshold, bool threshold_is_max)
	{
		switch type {
			match (epidemiological_lognormal) { return lognormal_trunc_rnd(param_1,param_2,threshold,threshold_is_max); }
			match (epidemiological_weibull) { return weibull_trunc_rnd(param_1,param_2,threshold,threshold_is_max); }
			match (epidemiological_gamma) { return gamma_trunc_rnd(param_1,param_2,threshold,threshold_is_max); }
			match (epidemiological_normal) { return truncated_gauss(param_1,param_2,threshold,threshold_is_max); }
			default {
				if(threshold_is_max)
				{
					return rnd(param_1,threshold);
				}
				else
				{
					return rnd(threshold,param_2);
				}
			}
		}
		// return type=epidemiological_lognormal?lognormal_rnd(param_1,param_2):(type=epidemiological_weibull?weibull_rnd(param_1,param_2):(type=epidemiological_gamma?gamma_rnd(param_1,param_2):(type=epidemiological_normal?gauss_rnd(param_1,param_2):rnd(param_1,param_2))));
	}

	// TODO : FIND SOMETHING FOR THOSE PARAMETER

	//Successful contact rate of the building - MUST BE FIXED (i.e not relying on a distribution)
	float get_contact_rate_building { return successful_contact_rate_building/nb_step_for_one_day;  }
	
	//Amount of viral agent realeased in the environment - is it actually a rate of release ???
	float get_basic_viral_release(int age) { return basic_viral_release/nb_step_for_one_day; }

	//Reduction of the successful contact rate of an infectious individual of a given age
	float get_factor_contact_rate_wearing_mask(int age) {
		return init_all_ages_factor_contact_rate_wearing_mask;
		// TODO : replace a parameter based initialization 
		//return float(map_epidemiological_parameters[age][epidemiological_factor_wearing_mask][1]);
	}
		
	//Give a boolean to say if an individual of a given age should be wearing a mask - MUST BE FIXED (i.e. not following a distribution)
	float get_proba_wearing_mask(int age) {
		return init_all_ages_proportion_wearing_mask;
		// TODO : replace a parameter based initialization
		//return (float(map_epidemiological_parameters[age][epidemiological_proportion_wearing_mask][1]));
	}
	
	//Gives a probability to be antivax given the age of the person
	float get_proba_antivax(int age) { 
		return init_all_ages_proportion_antivax;
		// TODO : replace a parameter based initialization
		// return flip(float(map_epidemiological_parameters[age][proportion_antivax][1]))?1.0:0.0;
	}
	
	float get_proba_free_rider(int age) {
		return init_all_ages_proportion_freerider;
	}
	
}