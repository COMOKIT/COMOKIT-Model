/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "Abstract.gaml"

global {

	init { 
			
			create Politics  {
				Gov_policy<-self;
				authorsisation[schooling]<-true;
				authorsisation[working]<-true;
			} 

	}

}

experiment "No Containment" parent: "Abstract Experiment"{
	output {
		display "Main" parent: d1 {}
	}
}