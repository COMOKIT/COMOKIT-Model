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
	bool batch_enable_detailedCSV <- false;
	int idSimulation <- -1;
	int ageCategory <- 100;
	
	// Batch data export
	string result_folder <- "../../batch_output/";
	string modelName <- self.host.name;
	list<string> list_shape_path <- [];
	
	bool sim_stop { return (Individual count each.is_infected = 0) and had_infected_Individual; }
	
	init{
		if (idSimulation = -1){
			idSimulation <- int(self);
		}
	}
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
		loop i from: ageCategory to: 100 step: ageCategory{
			// Get corresponding age category
			list<Individual> subIndividual <- Individual where(each.age < i and each.age >= (i - ageCategory));
			
			save [
				// Number of new cases (incidence) per step per age category
				length(subIndividual where (each.is_infected)),
				// Number of new cases per step per building (or building type) and age category
				
				// Number of hospitalizations per step per age category
				length(subIndividual where(each.hospitalization_status=need_hospitalization)),
				// Number of ICU per step per age category
				length(subIndividual where(each.hospitalization_status=need_ICU)),
				// Number of susceptible per step per age category
				length(subIndividual where (each.status=susceptible)),
				// Number of exposed per step per age category
				length(subIndividual where (each.is_exposed())),
				// Number of asymptomatic permanent per step per age category
				length(subIndividual where (each.status = asymptomatic)),
				// Number of asymptomatic temporary per step per age category
				length(subIndividual where (each.status = symptomatic_without_symptoms)),
				// Number of symptomatic per step per age category
				length(subIndividual where (each.status = symptomatic_with_symptoms)),
				// Number of recovered per step per age category
				length(subIndividual where (each.status = recovered)),			
				// Number of dead per step per age category
				length(subIndividual where (each.status = dead))
			] type: "csv" to: result_folder + "batchDetailed-" + modelName + "-" + idSimulation + "_" + (i - ageCategory) + "-" + (i-1) + ".csv" rewrite:false;
		}
	}
	
	/***************/
	/*  OVERRIDES  */
	/***************/
	
	// @Override	
	//string shape_path <- "../Datasets/Vinh Phuc/";
}

// This experiment is needed to run batch within GAMA
experiment "Abstract Batch Experiment" type:batch repeat: 2 until: world.sim_stop()
		 virtual:true  parent: "Abstract Experiment"
{
	init {
		batch_enable_detailedCSV <- true;
		string shape_path <- "../Datasets/Vinh Phuc/";
	}
	
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
		] type: "csv" to: result_folder + "batchResult-" + modelName + ".csv" rewrite:false;
	}
}

// This experiment is needed to run headless experiments
experiment "Abstract Batch Headless" type:gui
		 virtual:true  parent: "Abstract Experiment"
{
	init {
		batch_enable_detailedCSV <- true;
		string shape_path <- "../Datasets/Vinh Phuc/";
	}
	// Parameters for headless settings
	parameter var:idSimulation init: 0 min: 0;
	parameter var:ageCategory init: 5 min: 1 max: 100;
}