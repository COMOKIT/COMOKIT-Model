/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Example of experiments in COMOKIT Building.
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/


@no_experiment

model CoVid19

import "../Entities/BuildingIndividual.gaml"

import "../Entities/Building Spatial Entities.gaml"
 
import "../Parameters.gaml"


experiment AbstractExperiment type:gui autorun:false virtual: true{
		
	output{
		layout #split;
	  	display Simulation type:opengl  background:#black draw_env:false synchronized:false autosave:false toolbar:false	{
		   	species Room  ;
		    species BuildingEntrance ;
			species RoomEntrance;
			species CommonArea ;
			species RoomEntrance aspect: queuing;
			species unit_cell;
			species Wall refresh: false;
			species PedestrianPath aspect: free_space_aspect transparency: 0.5;
			species PedestrianPath ;
			species Separator;
			species BuildingIndividual;
		 
	  	}	  
	  // OUTBREAK
		
		display "states_evolution_chart" refresh: every(15#mn) {
			chart "Population epidemiological states evolution" background: #white axes: #black color: #black title_font: default legend_font: font("Helvetica", 14, #bold) {
				data "Susceptible" value: length(all_building_individuals where (each.state = susceptible)) color: #green marker: false style: line;
				data "Latent" value: length(all_building_individuals where (each.is_latent())) color: #orange marker: false style: line;
				data "Infectious" value: length(all_building_individuals where (each.is_infectious)) color: #red marker: false style: line;
				data "Recovered" value: length(all_building_individuals where (each.clinical_status = recovered)) color: #blue marker: false style: line;
				data "Dead" value: length(all_building_individuals where (each.clinical_status = dead)) color: #black marker: false style: line;
			}

		}

		display "cumulative_incidence" refresh: every(15#mn) {
			chart "Cumulative incidence" background: #white axes: #black {
				data "cumulative incidence" value: total_number_of_infected color: #red marker: false style: line;
			}
		}
		
		display "secondary_infection_distribution" refresh: every(15#mn) {
			chart "Distribution of the number of people infected per individual" type: histogram {
				loop i over:[pair(0,0),pair(1,1),pair(2,4),pair(5,9),pair(10,24),
					pair(24,49),pair(50,99),pair(100,499),pair(500,10000)
				] {
					data i.key=i.value?string(i.key):string(i) 
						value: all_building_individuals count (each.number_of_infected_individuals>=int(i.key) and each.number_of_infected_individuals<=int(i.value));
				}
			}
		}
		
	}	
}


