/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Global

import "species/Building.gaml"
import "species/Commune.gaml"
import "species/River.gaml"
import "species/Road.gaml"
import "species/Individual.gaml"
import "species/Hospital.gaml"
import "species/Activity.gaml"
import "species/Spatialized_Politics.gaml"
import "Constants.gaml"
import "Parameters.gaml"

global {
	init {
		create River from:river_shapefile;
		create Commune from:commune_shapefile;
		create Road from: road_shapefile;
		road_network <- as_edge_graph(Road);
		create Building from: building_shapefile {		
		}
		ask (0.1*length(Building)) among Building{				
				is_school <- true;
		}  
		create Individual number: nb_people {
			my_school <- any(Building where (each.is_school)); //sch[rnd_choice(idx)]; 
			my_building <- any(Building where (!each.is_school));
			location <- any_location_in(my_building);
			my_bound <- my_building.shape;
			//			masked <- flip(0.8) ? true : false;
		}

		ask (0.5*nb_people) among Individual {
			masked <- true;
		}

		ask 1 among (Individual) {
			exposed <- true;
		}

	}
	reflex stop_sim when:cycle>=1500{
		do pause;
	}
}