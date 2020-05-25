/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Alexis Drogoul, Damien Philippon
* 
* Description: 
* 	Model comparing various scenarios of wearing masks: either no one wears a mask or everybody wears one.
* 	The efficiency of masks to prevent disease transmission is parametrized (set to 0.1).
* 	No other intervention policy is added.
* 
* Parameters:
* 	- factor (defined in the experiment) sets the factor of reduction for successful contact rate of an infectious individual wearing mask 
* 	- proportions (in the _init_ action) sets the various the various proportions of the Individual population wearing a mask (set to 0% or 100%).
* 		One simulation is created for each element of the list. As an example, add 0.5 to test with 50% of the population wearing a mask.
* 
* Dataset: chosen by the user (through a choice popup)
* Tags: covid19,epidemiology,mask
******************************************************************/

model CoVid19

import "../../Model/Global.gaml"
import "../Abstract Experiment.gaml"

global {
	
	//@Override
	action define_policy{
		ask Authority {
			policy <- create_no_containment_policy();
		}
	}
}

experiment "Wearing Masks" parent: "Abstract Experiment" autorun: true {
	// Redefinition of the factor of reduction for successful contact rate of an infectious individual wearing mask (init_all_ages_factor_contact_rate_wearing_mask)
	float factor <- 0.1;

	action _init_ {
		string shape_path <- self.ask_dataset_path();
		float simulation_seed <- rnd(2000.0);
		list<rgb> colors <- brewer_colors("Paired");
		// Set the various proportions of the Individual population wearing a mask
		list<float> proportions <- [0.0,1.0];
		
		loop proportion over: proportions {
			create simulation with: [color::(colors at int(proportion*5)), dataset_path::shape_path, seed::simulation_seed,   
				init_all_ages_factor_contact_rate_wearing_mask::factor, 
				init_all_ages_proportion_wearing_mask::proportion, 
				force_parameters::list(epidemiological_proportion_wearing_mask, epidemiological_factor_wearing_mask)
			] {
				name <- string(int(proportion*100)) + "% with mask";
				// Automatically call define_policy action
			}
		}
	}

	permanent {
		display "charts" parent: infected_cases refresh: every(24 #cycle) {
			graphics "title" {
				draw ("Day " + int((current_date - starting_date) /  #day))  font: default at: {100#px, 0} color:#white anchor: #top_left;
				draw  "Mask Efficiency " + round(factor * 100) + "%" font: default at: {100#px, 30#px}  color: #white anchor: #top_left;
			}
		}
	}

	output {		
		layout #split consoles: false editors: false navigator: false tray: false tabs: false toolbars: false controls: true;

		display "Main" parent: simple_display {
			graphics title {
				draw world.name font: default at: {0, world.shape.height/2 - 30#px} color:world.color anchor: #top_left;
			}
		}
	}
}
