/**
* Name: Constants
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


model Constants

global {
	
	string SUSCEPTIBLE <-"susceptible";
	string LATENT <- "latent";
	string PRESYMPTOMATIC <- "presymptomatic";
	string SYMPTOMATIC <- "symptomatic";
	string ASYMPTOMATIC <- "asymptomatic";
	string REMOVED <- "removed";
	string HOSPITALISATION <- "hospitalisation";
	string ICU <- "icu";
	string DEAD <- "dead";
	string ALPHA <- "Alpha";
	string BETA <- "Beta";
	string DELTA <- "Delta";
	string GAMMA <- "Gamma";
	string ORGINAL <- "SARS-CoV-2";
}
