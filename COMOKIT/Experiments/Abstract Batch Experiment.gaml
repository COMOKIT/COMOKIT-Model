/******************************************************************
* Batch experiment to explore the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Arthur Brugiere <roiarthurb>, Kevin Chapuis <chapuisk>
* Tags: covid19,batch,hpc,exploration
******************************************************************/

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
				subIndividual <- Individual where(each.age <= i and each.age >= (i - ageCategory));
			}else{
				subIndividual <- Individual where(each.age < i and each.age >= (i - ageCategory));	
			}
			
			save [
				// Number of new cases (incidence) per step per age category
				total_incidence,
				// Number of new cases per step per building (or building type) and age category
				
				// Number of hospitalisations per step per age category
				length(subIndividual where(each.clinical_status=need_hospitalisation)),
				// Number of ICU per step per age category
				length(subIndividual where(each.clinical_status=need_ICU)),
				// Number of susceptible per step per age category
				length(subIndividual where (each.state=susceptible)),
				// Number of exposed per step per age category
				length(subIndividual where (each.is_latent())),
				// Number of asymptomatic permanent per step per age category
				length(subIndividual where (each.state = asymptomatic)),
				// Number of asymptomatic temporary per step per age category
				length(subIndividual where (each.state = presymptomatic)),
				// Number of symptomatic per step per age category
				length(subIndividual where (each.state = symptomatic)),
				// Number of recovered per step per age category
				length(subIndividual where (each.clinical_status = recovered)),			
				// Number of dead per step per age category
				length(subIndividual where (each.clinical_status = dead))
			] type: "csv" to: result_folder + "batchDetailed-" + modelName + "-" + idSimulation + "_" + (i - ageCategory) + "-" + (i-1) + ".csv" rewrite:false;
		}
	}
	

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
			simulations mean_of length(each.Individual where (each.state=susceptible)),
			// Number of exposed per step per age category
			simulations mean_of length(each.Individual where (each.is_latent())),
			// Number of asymptomatic permanent per step per age category
			simulations mean_of length(each.Individual where (each.state = asymptomatic)),
			// Number of asymptomatic temporary per step per age category
			simulations mean_of length(each.Individual where (each.state = presymptomatic)),
			// Number of symptomatic per step per age category
			simulations mean_of length(each.Individual where (each.state = symptomatic)),
			// Number of recovered per step per age category
			simulations mean_of length(each.Individual where (each.clinical_status = recovered)),			
			// Number of dead per step per age category
			simulations mean_of length(each.Individual where (each.clinical_status = dead))
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
	parameter var:result_folder;
}