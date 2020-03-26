/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "../species/Politics.gaml"

experiment "Abstract Experiment" virtual: true {
	output {
		display "d1" synchronized: false type: opengl background: #black virtual: true {
			species Commune {
						draw shape color: #yellow empty:true;
				
			}
			species River;
			species Road {
				draw shape + 3 color: #white;
			}
			species Building {
				draw shape * 3 color: type_activity="school" ? #blue : #gray empty: true;
			}
			species Individual {
				draw circle(15) color: status = exposed ? #orange : (status = infected ? #red : #green);
			}
		}

		display "chart" virtual: true {
			chart "sir" background: #white axes: #black {
			//				data "susceptible" value: length(Individual where (each.status="susceptible")) color: #green marker: false style: line;
				data "exposed" value: length(Individual where (each.status = "exposed")) color: #orange marker: false style: line;
				data "infected" value: length(Individual where (each.status = "asymptomatic" or each.status = "infected")) color: #red marker: false style: line;
				data "recovered" value: length(Individual where (each.status = "recovered")) color: #blue marker: false style: line;
				data "dead" value: length(Individual where (each.status = "death")) color: #black marker: false style: line;
			}

		}

	}

}