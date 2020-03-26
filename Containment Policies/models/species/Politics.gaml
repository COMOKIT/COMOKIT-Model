/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Species_Politics
import "Individual.gaml"

species Politics {
	map<string,bool> authorsisation;
	bool ask_authorisation(Individual i, string activity){
		return authorsisation[activity];
	}
	aspect default {
		draw shape+10 color: #black;
	}

}