/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Constants

global {
	string susceptible <- "S";
	string exposed <- "E";
	string asymptomatic <- "A";
	string symptomatic_without_symptoms <- "Ua";
	string symptomatic_with_symptoms <- "Us";
	string recovered <- "R";
	string dead <- "D";
	
	string not_tested <- "Not tested";
	string tested_positive <- "Positive";
	string tested_negative <- "Negative";
	
	string act_neighbor <- "visiting neighbor";
	string act_friend <- "visiting friend";
	string act_home <- "staying at home";
	string act_working <- "working";
	string act_studying <- "studying";
	string act_eating <- "eating";
	string act_shopping <- "shopping";
	string act_leisure <- "leisure";
	string act_outside <- "outside activity";
	string act_other <- "other activity";

}