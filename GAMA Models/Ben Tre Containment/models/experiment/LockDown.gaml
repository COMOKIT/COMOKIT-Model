/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona
import "../Global.gaml"
experiment "Lock Down" { 
	output {
 	display "d1" synchronized: false type:java2D {
		 
			species Commune ;
			species River;
			species Road ;
			species Building;
			species Individual;
		}
//
//		display "chart" {
//			chart "sir" background: #white axes: #black {
//				data "susceptible" value: length(people where (each.susceptible)) color: #green marker: false style: line;
//				data "infected" value: length(people where (each.exposed or each.infected)) color: #red marker: false style: line;
//				data "recovered" value: length(people where (each.recovered)) color: #blue marker: false style: line;
//				data "dead" value: dead color: #black marker: false style: line;
//			}
//
//		}

	}

}