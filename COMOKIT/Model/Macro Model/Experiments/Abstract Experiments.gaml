/**
* Name: BaseExperiment
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

 @no_experiment
model AbstractExperiment
  
import "../Global.gaml" 

global {
	init {
		do before_init;
		do init_simulation;
		do create_authority;
		
		do after_init;
	}
	
	
}
 
experiment abstract_experiment virtual: true type: gui {
	
	output {
		monitor nb_infected value:SpatialUnit sum_of (each.nb_infected) color: #red;
		display map {
			species SpatialUnit;
		}
		display charts refresh: every(#day){
			chart "evolution" {
				data "number of infected" value: SpatialUnit sum_of (each.nb_infected) color: #red;
				data "number of susceptible" value:  SpatialUnit sum_of (each.nb_individuals - each.nb_infected) color: #green;
			}
		}
	}
}