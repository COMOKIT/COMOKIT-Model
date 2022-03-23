/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 2.0, March 2021. See http://comokit.org for support and updates
* 
* The base of all experiments in COMOKIT Macro. Provides a set of utilities
* (dataset path management, virtual displays, graphic constants, ...) 
* that can be reused, inherited or redefined in child experiments.
* Also see Abstract Experiment with Parameters.gaml and Abstract 
* Batch Experiment for more features in terms of parameterization 
* and exploration of simulations.
* 
* Author: Patrick Taillandier, Alexis Drogoul
* Tags: covid19,epidemiology
******************************************************************/

 @no_experiment
model AbstractExperiment
  
import "../Global.gaml" 

global {
	
	font default <- font("Helvetica", 18, #bold) const: true;
	
	bool show_legend <- true ;
	init {
		do before_init;
		do init_simulation;
		do create_authority;
		
		do after_init;
	}
	
	
	
}
 
experiment abstract_experiment virtual: true type: gui {
	
	float simulation_seed <- 0.0; //0.0 = random seed
	string bound_shapefile <- dataset + "/generated/boundary.shp";
	string  bound_csv <- dataset + "/generated/boundary.csv";
	string name_sim <- "abstract experiment";
		
	action create_simulation {
		create simulation with:(name:name_sim, macro_model:true, shp_boundary_path: bound_shapefile, csv_boundary_path: bound_csv, seed:simulation_seed );
	}
	
	output {
		display map background: #black type: opengl axes: false virtual: true   {
			species SpatialUnit;
			graphics "legend" position: {0,0,0.01}{
				if show_legend {
					draw (name) at: {world.shape.width*4/5, world.shape.height / 20} color: #white font: font("Helvetica", 40 , #bold); 
					
					draw (""+ current_date.day + " - " + current_date.month + " - " + current_date.year) at: {world.shape.width*4/5, world.shape.height / 15} color: #white font: font("Helvetica", 30 , #bold); 
					draw ("Rate of infected people") at: {world.shape.width*4/5, world.shape.height / 11} color: #white font: font("Helvetica", 30 , #bold); 
					

					draw rectangle( world.shape.width / 6,world.shape.height / 50) at: {world.shape.width*4.5/5, 1.17* world.shape.height/10.0} texture: "../../../Utilities/degrade.png";
					draw ("0.0") at:   {world.shape.width*3.9/5, 1.2 * world.shape.height/10.0} color: #white  font: font("Helvetica", 30 , #bold); 
					draw ("1.0") at: {world.shape.width*5/5, 1.2 * world.shape.height/10.0} color: #white  font: font("Helvetica", 30 , #bold);	
				}
			}
		}
		
		display "states_evolution_chart"  refresh: every(#day)  virtual: true {
			chart "Population epidemiological states evolution - " + name background: #black axes:  #white color:  #white title_font: default legend_font: font("Helvetica", 14, #bold) {
				data "Susceptible" value:group_individuals sum_of (each.num_susceptibles) color: #lightgreen marker: false style: line;
				data "Latent" value: group_individuals sum_of (each.num_latent_asymptomatics + each.num_latent_symptomatics) color: #orange marker: false style: line;
				data "Infectious" value: group_individuals sum_of (each.num_symptomatic + each.num_asymptomatic) color: #red marker: false style: line;
				data "Recovered" value: group_individuals sum_of (each.num_recovered) color: #lightblue marker: false style: line;
				data "Dead" value: group_individuals sum_of (each.num_dead) color: #white marker: false style: line;
			}

		}
	}
}