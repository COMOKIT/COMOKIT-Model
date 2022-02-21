/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Parameters for COMOKIT Building
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/
@no_experiment
model Parameters

import "Constants.gaml"

global {
	
	string dataset <- "../../Datasets/Alpes-Maritimes";
	
	float mask_ratio <- 0.5;
	float factor_contact_rate_wearing_mask <- 0.5;

	float density_ref_contact <- 10000.0;//0.1;
	string variant <- DELTA;
	int nb_init_infected <- 5;
}
