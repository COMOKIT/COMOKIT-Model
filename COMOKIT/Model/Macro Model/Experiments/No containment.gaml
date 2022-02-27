/**
* Name: BaseExperiment
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

model NoPolicy 
 
import "Abstract Experiments.gaml"

global {
  action define_policy{   
		ask Authority {
			name <- "No containment policy";
			policy <- create_no_containment_policy();
		}
	}	
}
 
experiment no_contaiment parent: abstract_experiment {
	action _init_ {
		create simulation with:(macro_model:true, shp_boundary_path: dataset + "/generated/boundary.shp", csv_boundary_path: dataset + "/generated/boundary.csv" );
	}
}