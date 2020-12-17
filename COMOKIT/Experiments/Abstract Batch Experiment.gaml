/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit 
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Arthur Brugiere <roiarthurb>, Kevin Chapuis <chapuisk>
* Description: Batch experiment to explore the GAMA CoVid19 Modeling Kit.
*    This model defines experiments on top of which exploration models can be built. 
*    In particular, it describes all the data that will be saved at each simulation step in a file.
* Tags: covid19,batch,hpc,exploration
******************************************************************/
model CoVid19

import "Abstract Experiment.gaml"

global{
	
	/**************/
	/* PARAMETERS */
	/**************/

	// Parameters for batch experiment
	bool batch_enable_detailedCSV <- false;
	int idSimulation <- -1;
	int ageCategory <- 100;
	
	// Batch data export
	string result_folder <- "../../batch_output/";
	string modelName <- self.host.name;
	list<string> list_shape_path <- [];
	
	bool sim_stop { return (all_individuals all_match ([susceptible, removed] contains each.state)); }
	
	init{
		if (idSimulation = -1){
			idSimulation <- int(self);
		}
		
	}
	/***************/
	/* SAVING DATA */
	/***************/
	
	// Save data at every cycle on the simulation
	reflex observerPattern when: batch_enable_detailedCSV {
		float start <- BENCHMARK ? machine_time : 0.0;
		if(cycle=0)
		{
			save building_infections.keys type:"csv" to: result_folder + "batchDetailed-" + modelName + "-" + idSimulation + "_building.csv" rewrite:true header:false;
		}
		save building_infections.values type:"csv" to: result_folder + "batchDetailed-" + modelName + "-" + idSimulation + "_building.csv" rewrite:false;
			
		loop i from: ageCategory to: 100 step: ageCategory{
			
			// Calculate sub_incidence per age category
			int total_incidence <- 0;
			loop min_age from: i-ageCategory to: i-1{
				if(total_incidence_age.keys contains min_age)
				{
					total_incidence <- total_incidence+total_incidence_age[min_age];
				}
			}			
			// Get corresponding Individual in age category
			list<Individual> subIndividual;
			if (i = 100){ // Include age 100 in last CSV
				subIndividual <- all_individuals where(each.age <= i and each.age >= (i - ageCategory));
			}else{
				subIndividual <- all_individuals where(each.age < i and each.age >= (i - ageCategory));	
			}
			
			save [
				// Number of new cases (incidence) per step per age category
				total_incidence,				
				// Number of hospitalisations per step per age category
				subIndividual count (each.clinical_status=need_hospitalisation),
				// Number of ICU per step per age category
				subIndividual count (each.clinical_status=need_ICU),
				// Number of susceptible per step per age category
				subIndividual count (each.state=susceptible),
				// Number of exposed per step per age category
				subIndividual count (each.is_latent()),
				// Number of asymptomatic permanent per step per age category
				subIndividual count (each.state = asymptomatic),
				// Number of asymptomatic temporary per step per age category
				subIndividual count (each.state = presymptomatic),
				// Number of symptomatic per step per age category
				subIndividual count (each.state = symptomatic),
				// Number of recovered per step per age category
				subIndividual count (each.clinical_status = recovered),			
				// Number of dead per step per age category
				subIndividual count (each.clinical_status = dead)
			] type: "csv" to: result_folder + "batchDetailed-" + modelName + "-" + idSimulation + "_" + (i - ageCategory) + "-" + (i-1) + ".csv" rewrite: (cycle = 0);
		}
		if BENCHMARK { bench["Abstract Batch Experiment.observerPattern"] <- bench["Abstract Batch Experiment.observerPattern"] + machine_time - start;}
	}
}

// This experiment is needed to run batch within GAMA
experiment "Abstract Batch" type:batch repeat: 80 until: world.sim_stop() keep_simulations: false
		 virtual:true  parent: "Abstract Experiment"
{
	init {
		batch_enable_detailedCSV <- true;
		dataset_path <- build_dataset_path();
		ageCategory <- 5;
	}
}

// This experiment is needed to run headless experiments
experiment "Abstract Headless" type:gui
		 virtual:true  parent: "Abstract Experiment"
{
	init {
		batch_enable_detailedCSV <- true;
		dataset_path <- build_dataset_path();
	}
	// Parameters for headless settings
	parameter var:idSimulation init: 9999 min: 0;
	parameter var:ageCategory init: 5 min: 1 max: 100;
	parameter var:result_folder;
}