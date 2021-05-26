/**
* Name: Virus
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags:  
*/ 

model Virus

import "../Parameters.gaml"

/*
 * Represent Sars-CoV-2 virus and all variants
 * 
 * For a global overview of strain evolution and prevalence: https://nextstrain.org/ncov/global
 * 
 */
global {
	
	/*
	 * The very first strain of Sars-Cov-2
	 */
	virus original_strain <- create_variant(nil,"SARS-CoV-2",1.0,1.0,1.0);
	
	/*
	 * List of variants of concern, as stated by WHO
	 * source : https://www.cdc.gov/coronavirus/2019-ncov/cases-updates/variant-surveillance/variant-info.html#Concern
	 */
	list<sarscov2> VOC <- [
		create_variant(sarscov2(original_strain),"B.1.1.7",1.1,1.5,1.4), // UK
		create_variant(sarscov2(original_strain),"P.1",2.0,1.0,1.0), // Brazil
		create_variant(sarscov2(original_strain),"B.1.351",2.0,1.5,1.0) // South-Africa
	];
	
	/*
	 * List of variants of interest, as stated by WHO
	 * source : https://www.who.int/publications/m/item/weekly-epidemiological-update-on-covid-19---27-april-2021
	 * TODO : requalified the Indian into VOC
	 */
	list<sarscov2> VOI <- [
		 // B.1.615 FRANCE
		create_variant(sarscov2(original_strain),"B.1.617",1.5,1.5,1.0) // INDIA
	];
	
	/*
	 * The comprehensive list of all sars-cov-2 strains
	 */
	list<virus> viruses <- VOC + VOI + original_strain;
	
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
	sarscov2 create_variant(sarscov2 source, string variant_name, float immune_evad, float infect, float severity) {
		create sarscov2 with:[
			source_of_mutation::source,
			name::variant_name,
			immune_evasion::source=nil?immune_evad:source.immune_evasion*immune_evad,
			infectiousness::source=nil?infect:source.infectiousness*infect,
			phenotype_shift::source=nil?severity:source.phenotype_shift*severity
		] returns:variants;
		return first(variants);
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
	 * How much this virus is infectious on a one dimensional scale [0:+infinit]
	 */
	float get_infectiousness_factor virtual:true;
	
	/*
	 * How much this virus is able to escape from immune defense compare to the original strain
	 */
	float get_immune_escapement virtual:true;
	float get_reinfection_probability {return 0.0;}
}

/*
 * Every attribute of the virus is based upon 
 */
species sarscov2 parent:virus {
	
	/*
	 * TODO : clarify wehther it should be general or be tight to immune response to each sarscov2 and vax
	 * e.g. CDC makes a difference between immune evastion from vax and monoclonal antibody treatments
	 */ 
	float immune_evasion;
	float get_immune_escapement {return immune_evasion < 1 ? 1.0 : 1.0 / immune_evasion;}
	float get_reinfection_probability {return basic_selfstrain_reinfection_probability;}
	
	// Should impact the viral load of infected people
	float infectiousness;
	float get_infectiousness_factor {return infectiousness;}

	/*
	 * TODO : To be validated
	 * Should impact the expected set of clinical outcomes : 
	 * - simple hypothesis : the risk to develop a sever form of the disease
	 * - complex hypothesis : piece by piece changes in the clinical picture, e.g. probability to develop symptoms or not, sever forms, timelines shift (onset to symptoms, infectious period, etc.)
	 */ 
	float phenotype_shift;
	
	// The ability of the virus to escape from testing
	float test_prone <- 1.0;
	
}