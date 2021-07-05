/**
* Name: Virus
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags:  
*/ 

model Virus

import "../Parameters.gaml"
import "../Constants.gaml"
import "Biological Entity.gaml"
import 'Individual.gaml'

/*
 * Represent Sars-CoV-2 virus and all variants
 * 
 * For a global overview of strain evolution and prevalence: https://nextstrain.org/ncov/global
 * 
 */
global {
	
	/*
	 * 
	 */
	map<virus,float> proba_outside_contamination_per_hour <- [original_strain::0.0]; //proba per hour of being infected for Individual outside the study area
	
	/*
	 * The very first strain of Sars-Cov-2
	 */
	virus original_strain;
	
	/*
	 * List of variants of concern, as stated by WHO
	 * source : https://www.cdc.gov/coronavirus/2019-ncov/cases-updates/variant-surveillance/variant-info.html#Concern
	 */
	list<sarscov2> VOC;
	
	/*
	 * List of variants of interest, as stated by WHO
	 * source : https://www.who.int/publications/m/item/weekly-epidemiological-update-on-covid-19---27-april-2021
	 * TODO : requalified the Indian into VOC
	 */
	list<sarscov2> VOI;
	
	/*
	 * The comprehensive list of all sars-cov-2 strains
	 */
	list<virus> viruses -> VOC + VOI + original_strain;

	/*
	 * Init the variants
	 */
	action init_variants {
		VOC <+ create_simple_variant(sarscov2(original_strain),"Alpha",1.1,1.5,[1.4,1.0,1.0]); // UK
		VOC <+ create_simple_variant(sarscov2(original_strain),"Gamma",2.0,1.0,[1.0,1.0,1.0]); // Brazil
		VOC <+ create_simple_variant(sarscov2(original_strain),"Beta",2.0,1.5,[1.0,1.0,1.0]); // South-Africa
		VOC <+  create_simple_variant(sarscov2(original_strain),"Delta",1.5,2.0,[1.5,1.5,1.5]); // INDIA
	}
	
	/*
	 * Create sarscov2 variants
	 * 
	 * - source : original strain from which this variant mutate from
	 * - variant_name : name of the variant following "pango lineage"
	 * 
	 * => All numerical value hereafter are express based on a {1,1,1} profile of the source vector, 
	 * meaning that a profile of {2,2,2} multiply by two every characteristics of the original (whatever value they can be)
	 * 
	 * - immune_evad : how much it can disrupt immune protection built against the viral source (vax, immunity due to prior infection or antibiotic)
	 * - infect : how much more it is infectious compare to the source
	 * - severity : how it is worse in term of clinical picture compare to original
	 * 
	 */
	sarscov2 create_simple_variant(sarscov2 source, string variant_name, float immune_evad, float infect, list<float> severity) {
		create sarscov2 with:[
			source_of_mutation::source,
			name::variant_name
		] returns:variants {
			map<list<int>,map<string,list<string>>> inherited_epidemiological_distribution <- copy(source.epidemiological_distribution);
			loop dist over:inherited_epidemiological_distribution {
				dist[epidemiological_immune_evasion] <- [epidemiological_fixed, string(float(dist[epidemiological_immune_evasion][1])/immune_evad)]; // = source evastion / immune_evad
				dist[epidemiological_successful_contact_rate_human] <- [epidemiological_fixed, string(float(dist[epidemiological_successful_contact_rate_human][1])*infect)]; // = source rate * infect
				// Severity
				dist[epidemiological_proportion_hospitalisation] <- [epidemiological_fixed, string(float(dist[epidemiological_proportion_hospitalisation][1])*infect)]; // Hosp
				dist[epidemiological_proportion_icu] <- [epidemiological_fixed, string(float(dist[epidemiological_proportion_icu][1])*infect)]; // ICU
				dist[epidemiological_proportion_death_symptomatic] <- [epidemiological_fixed, string(float(dist[epidemiological_proportion_death_symptomatic][1])*infect)]; // Death
			}
		}
		return first(variants);
	}
	
	// ----------------------------------------------------------------- //
	// ----------------------------------------------------------------- //
	// 		MANAGE EPIDEMIOLOGICAL PARAMETERS			  //
	// ----------------------------------------------------------------- //
	// ----------------------------------------------------------------- //
	
	/*
	 * The list of individual determinant in epidemiological expression of SARS-CoV-2
	 */
	list<string> EPI_ENTRIES  <- [AGE,SEX,COMORBIDITIES];
	/*
	 * The list of <b>epidemiological parameters</b> for SARS-CoV-2. Can be: 
	 * <ul>
	 * <l> <b>RATE</b> -  expressed per tick of simulation or per day <br>
	 * 	<ul>
	 * 	<l> CONSTANT - constant value<br>
	 * 	<l> DISTRIBUTION - expressed with a type of distribution (see Function.gaml) and parameter 1 (usually mean) and 2 (usually stdv)
	 * 	</ul>
	 * <l> <b>FACTOR</b> - based on a distribution with potential contant value <br>
	 * <l> <b>PERIOD</b>
	 * 	<ul>
	 * 	<l> CONSTANT - constant value<br>
	 * 	<l> DISTRIBUTION - expressed with a type of distribution (see Function.gaml) and parameter 1 (usually mean) and 2 (usually stdv)
	 * 	</ul> 
	 * </ul>
	 * 
	 * TODO : is it correct to make them per tick (direct value), per day (to be divided per the number of step for one day) or for a day (to be multiplied per the number of step for one day) ???
	 * 
	 */
	list<string> SARS_COV_2_EPI_PARAMETERS <- [
		epidemiological_successful_contact_rate_human, // RATE - CONSTANT PER  DAY
		epidemiological_factor_asymptomatic, //  FACTOR - CONSTANT (DEFAULT)
		epidemiological_basic_viral_release, // DISTRIBUTION (PER DAY ???)
		epidemiological_viral_individual_factor, // DISTRIBUTION or CONSTANT
		epidemiological_incubation_period_symptomatic, // PERIOD
		epidemiological_incubation_period_asymptomatic,
		epidemiological_serial_interval,
		epidemiological_infectious_period_symptomatic,
		epidemiological_infectious_period_asymptomatic,
		epidemiological_onset_to_hospitalisation,
		epidemiological_hospitalisation_to_ICU,
		epidemiological_stay_ICU,
		epidemiological_immune_evasion
	];
	
	/*
	 * Epidemiological parameter that should be fliped 
	 */
	list<string> SARS_COV_2_EPI_FLIP_PARAMETERS <- [
		epidemiological_proportion_asymptomatic,
		epidemiological_probability_true_positive,
		epidemiological_probability_true_negative,
		epidemiological_proportion_hospitalisation,
		epidemiological_proportion_icu,
		epidemiological_proportion_death_symptomatic,
		epidemiological_reinfection_probability
	];
	
	list<string> SARS_COV_2_PARAMETERS <- SARS_COV_2_EPI_PARAMETERS+SARS_COV_2_EPI_PARAMETERS;
	
	/*
	 * Gives antecedant of individuals
	 */
	list<int> get_individual_entries(BiologicalEntity indiv) { 
		if indiv is Individual { Individual i <- Individual(indiv); return [i.age,i.sex,i.comorbidities]; }
		if indiv is BiologicalEntity { return [indiv.age,epidemiological_default_entry[1],indiv.comorbidities]; } 
		return epidemiological_default_entry;
	}
	
	/*
	 * Use the proper indicator for each SARS-CoV-2 epidemiological parameter
	 */
	float get_epi_val(string var, list<string> parameters, float mod <- nil, bool is_max <-  true) {
		switch var {
			//Successful contact rate of an infectious individual - MUST BE FIXED (i.e not relying on a distribution)
			match epidemiological_successful_contact_rate_human { return get_rate(parameters,true);}
			//The amount of viral agents (epi sens of agent) release in the environment - FIXED or DISTRIBUTION 
			match epidemiological_basic_viral_release { return get_rate(parameters,true); }
			//Basic viral release in the environment of an infectious individual of a given age MUST BE A DISTRIBUTION -  or can be a CONSTANT = 1.0 based on 'allow_viral_individual_factor'
			match epidemiological_viral_individual_factor { return get_factor(parameters,allow_viral_individual_factor,1.0);}
			//The amount of protection guaranteed by previous infection and / or vaccine
			match epidemiological_immune_evasion {return get_factor(parameters);}
			
			// ALL EPI STATE PERIODS
			//Time between exposure and symptom onset of an individual of a given age - PERIOD
			match epidemiological_incubation_period_symptomatic  { return get_period(parameters); }
			//Time between exposure and symptom onset of an individual of a given age - PERIOD
			match epidemiological_incubation_period_asymptomatic { return get_period(parameters); }
			//Time between onset of a primary case of a given age and onset of secondary case - PERIOD
			match epidemiological_serial_interval { return get_period(parameters); }
			//Time between onset and recovery for an infectious individual of a given age
			match epidemiological_infectious_period_symptomatic { return get_period(parameters); }
			//Time between onset and recovery for an infectious individual of a given age
			match epidemiological_infectious_period_asymptomatic { return get_period(parameters); }
			//Give the number of steps between onset of symptoms and time for hospitalization
			match epidemiological_onset_to_hospitalisation { return get_period(parameters, mod, is_max); }
			//Give the number of steps between hospitalization and ICU
			match epidemiological_hospitalisation_to_ICU { return get_period(parameters,mod, is_max); }
			//Give the number of steps in ICU
			match epidemiological_stay_ICU { return get_period(parameters); }
			
			// All parameters expressed as a factor 
			default { return get_factor(parameters); }
		}
	}				
	
	/*
	 * Retrieve a factor based on a distribution, a fixed value or a default constant value
	 */
	float get_factor(list<string> parameters, bool or_else_default_value <- false, float default_value <- 0.0) {
		if or_else_default_value {return default_value;}
		if first(parameters)=epidemiological_fixed { return float(parameters[1]); }
		else {return get_rnd_from_distribution(parameters[0],float(parameters[1]),float(parameters[2]));}
	}
		
	/*
	 * Retrieve a rate, either expressed for one day (per_day=true) or one step (default : per_day=false)
	 */
	float get_rate(list<string> parameters, bool per_day <- false) {
		float val;
		if first(parameters)=epidemiological_fixed { val <- float(parameters[1]); }
		else {val <- get_rnd_from_distribution(parameters[0],float(parameters[1]),float(parameters[2]));}
		return per_day?val/nb_step_for_one_day:val;
	}
	
	/*
	 * Retrieve a period, either expressed in days (per_step=false) or in steps (default : per_step=true)
	 */
	float get_period(list<string> parameters, float max  <-  nil,  bool is_max <- true, bool per_step <- true) {
		float val;
		if first(parameters)=epidemiological_fixed { val <- float(parameters[1]); }
		else if max=nil {val <- get_rnd_from_distribution(parameters[0],float(parameters[1]),float(parameters[2]));}
		else {val <- get_rnd_from_distribution_with_threshold(parameters[0],float(parameters[1]),float(parameters[2]),max,is_max);}
		return per_step?val*nb_step_for_one_day:val;
	}
		
}

/*
 * Abstract representation of a viruses, with very few and simple (often expressed as a unique floating number) traits:
 * - source_of_mutation : the original strain (type virus) this virus derived from
 * > get_infectiousness_factor : how infectious is this virus (simplified to unidimensional infectiousness)
 * > get_immune_escapement : how much it is able to escape from immune defense (simplified to unidimensional immunity, pretty much like a shield amount)
 */
species virus virtual:true {
	
	/*
	 * The original strain of this virus
	 */
	virus source_of_mutation;
	
	/*
	 * The identifier of the virus, made up of distribution for immune escapment, infectiousness and severity (i.e. IE|CR|PH|PI|PD)
	 */
	string epi_id;
	
	// ------------------------------------------------------------------ //
	// 		EPIDEMIOLOGICAL PROFILE OF THE VIRUS			    //
	map<list<int>,map<string,list<string>>> epidemiological_distribution;
	
	float get_value_for_epidemiological_aspect(BiologicalEntity indiv, string aspect, float mod <- nil) virtual:true;
	bool flip_epidemiological_aspect(BiologicalEntity indiv, string aspect) virtual:true; 
	
	string get_epi_id {
		string ie <-  "Immune escapment:"; string cr <- "Infectiousness:"; string ph  <- "Severity (Hosp):"; string pi <- "Severity (ICU):";  string pd <- "Severity (Death):";
		loop entry over:epidemiological_distribution {
			ie <- ie + entry[epidemiological_immune_evasion];
			cr <- cr + entry[epidemiological_successful_contact_rate_human];
			ph  <- ph + entry[epidemiological_proportion_hospitalisation];
			pi <- pi + entry[epidemiological_proportion_icu];
			pd <- pd + entry[epidemiological_proportion_death_symptomatic];
		}
		return ie+cr+ph+pi+pd;
	}
	
}

/*
 * Every attribute of the virus is based upon 
 */
species sarscov2 parent:virus {
	
	// ----------------------------------------------------- //
	// EPI PARAMETER 
	
	/*
	 * Get parameter from the virus distribution (according to age, gender and comorbidities for sars-cov-2) and validate the epidemiological aspect (see list above)
	 */
	float get_value_for_epidemiological_aspect(BiologicalEntity indiv, string aspect, float mod <- nil) {
		if not(SARS_COV_2_EPI_PARAMETERS  contains aspect) {error "Trying to retrieve an unknown epidemiological aspect "+aspect;}
		return world.get_epi_val(aspect,epidemiological_distribution[world.get_individual_entries(indiv)][aspect],mod);
	}
	
	/*
	 * TODO : We only have given FIXED probability of being *aspect  (e.g. asymptomatic, presymptomatic, etc.) although it depends on individual antecedants...
	 */
	bool flip_epidemiological_aspect(BiologicalEntity indiv, string aspect) {
		if not(SARS_COV_2_EPI_FLIP_PARAMETERS contains aspect) {error "Trying to flip over an unknow epidemiological aspect"+aspect;}
		return flip(float(epidemiological_distribution[world.get_individual_entries(indiv)][aspect][1]));
	}	
	
}
