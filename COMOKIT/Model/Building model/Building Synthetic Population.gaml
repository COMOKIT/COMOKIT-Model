/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Uitilities to create Building Individual agents.
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/

model BuildingSyntheticPopulation

import "Entities/BuildingActivity.gaml"
import "Entities/Building Spatial Entities.gaml" 
import "Constants.gaml"
import "Entities/BuildingIndividual.gaml"
import "Entities/Hospital Individuals.gaml"

global {
	action create_recurring_people {
		create Doctor number: 10;
		create Nurse number: 16;
		create Staff number: 3;
		create Inpatient number: 38;
		create Caregivers number: 29;
	}
}