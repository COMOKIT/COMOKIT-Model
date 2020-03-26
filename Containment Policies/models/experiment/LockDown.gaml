/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Corona

import "../Global.gaml"
import "../species/Politics.gaml"
import "Abstract.gaml"

global {

	init { 
			
			create Politics  {
				Gov_policy<-self;
				authorsisation[schooling]<-false;
				authorsisation[working]<-false;
			} 

	}

}

experiment "Lock Down" parent: "Abstract Experiment"{


	output {
		display "Main" parent: d1 {}
	}
}