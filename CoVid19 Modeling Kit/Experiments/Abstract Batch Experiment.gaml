/***
* Batch experiment to explore the GAMA CoVid19 Modeling Kit
* see http://gama-platform.org/covid19
* Author: Arthur Brugiere <roiarthurb>, Kevin Chapuis <chapuisk>
* Tags: covid19,batch,hpc,exploration
***/

model CoVid19

import "Abstract Experiment.gaml"

global{
	
	/**************/
	/* PARAMETERS */
	/**************/

	// Parameters for batch experiment
	bool had_infected_Individual <- false;
	bool batch_enable_detailedCSV <- true;
	int cpt <- 0;
	
	// Batch data export
	string result_folder <- "../../batch_output/";
	string modelName <- self.host.name;
	list<string> list_shape_path <- [];
	
	bool sim_stop { return (Individual count each.is_infected = 0) and had_infected_Individual; }
	
	/***************/
	/* SAVING DATA */
	/***************/
		
	// Experiment may stop after at least 1 infected Individual
	reflex had_infected when: !had_infected_Individual {
		if (Individual count each.is_infected > 0){
			had_infected_Individual <- true;
		}
	}
	
	// Save data at every cycle on the simulation
	reflex observerPattern when: batch_enable_detailedCSV {
		save [
			// Number of new cases (incidence) per step per age category
			total_number_of_infected,			
			// Number of new cases per step per building (or building type) and age category
			
			// Number of hospitalizations per step per age category
			
			// Number of ICU per step per age category
			
			// Number of susceptible per step per age category
			length(Individual where (each.status=susceptible)),
			// Number of exposed per step per age category
			length(Individual where (each.is_exposed())),
			// Number of asymptomatic permanent per step per age category
			length(Individual where (each.status = asymptomatic)),
			// Number of asymptomatic temporary per step per age category
			length(Individual where (each.status = symptomatic_without_symptoms)),
			// Number of symptomatic per step per age category
			length(Individual where (each.status = symptomatic_with_symptoms)),
			// Number of recovered per step per age category
			length(Individual where (each.status = recovered)),			
			// Number of dead per step per age category
			length(Individual where (each.status = dead))
		] type: "csv" to: result_folder + "batchDetailed-" + modelName + "-" + int(self) + "_" + cpt + ".csv" rewrite:false;
	}
	
	/***************/
	/*  OVERRIDES  */
	/***************/
	
	// @Override	
	//string shape_path <- "../Datasets/Vinh Phuc/";
}

experiment "Abstract Batch Experiment" type:batch repeat: 2 until: world.sim_stop()
		 virtual:true  parent: "Abstract Experiment"
{
	// @Override			
	reflex end_of_runs {		
		save [
			// Number of new cases (incidence) per step per age category
			simulations mean_of each.total_number_of_infected,
			// Number of new cases per step per building (or building type) and age category
			
			// Number of hospitalizations per step per age category
			
			// Number of ICU per step per age category
			
			// Number of susceptible per step per age category
			simulations mean_of length(each.Individual where (each.status=susceptible)),
			// Number of exposed per step per age category
			simulations mean_of length(each.Individual where (each.is_exposed())),
			// Number of asymptomatic permanent per step per age category
			simulations mean_of length(each.Individual where (each.status = asymptomatic)),
			// Number of asymptomatic temporary per step per age category
			simulations mean_of length(each.Individual where (each.status = symptomatic_without_symptoms)),
			// Number of symptomatic per step per age category
			simulations mean_of length(each.Individual where (each.status = symptomatic_with_symptoms)),
			// Number of recovered per step per age category
			simulations mean_of length(each.Individual where (each.status = recovered)),			
			// Number of dead per step per age category
			simulations mean_of length(each.Individual where (each.status = dead))
		] type: "csv" to: result_folder + "batchResult-" + modelName + "_" + cpt + ".csv" rewrite:false;
		cpt <- cpt +1;
	}
}