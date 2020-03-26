/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "../species/Politics.gaml"

global {

	init { 
			
			create Politics  {
				Gov_policy<-self;
				authorsisation[schooling]<-false;
				authorsisation[working]<-false;
			} 

	}

}

experiment "Lock Down" {
	output {
		display "d1" synchronized: false type: java2D {
			species Commune;
			species River;
			species Road;
			species Building;
			species Individual;
		}

		display "chart" {
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