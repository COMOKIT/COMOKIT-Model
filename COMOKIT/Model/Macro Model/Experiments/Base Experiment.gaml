/**
* Name: BaseExperiment
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


model BaseExperiment
  
import "../Global.gaml" 
 
 
experiment base_experiment type: gui {
	action _init_ {
		create simulation with:(macro_model:true, shp_boundary_path: dataset + "/generated/boundary.shp");
	
	}
	output {
		monitor nb_infected value:SpatialUnit sum_of (each.nb_infected) color: #red;
		display map {
			species SpatialUnit;
		}
		display charts {
			chart "evolution" {
				data "number of infected" value: SpatialUnit sum_of (each.nb_infected) color: #red;
				data "number of susceptible" value:  SpatialUnit sum_of (each.nb_individuals - each.nb_infected) color: #green;
			}
		}
	}
}