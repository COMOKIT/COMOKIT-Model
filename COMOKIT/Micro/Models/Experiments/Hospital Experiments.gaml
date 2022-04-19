/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Example of experiments with COMOKIT Building.
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/
model CoVid19

import "Abstract Experiment.gaml"

global {
	
	
	
	action create_individuals {
		
		do create_doctors(100);
		do create_patients(1000);
	}
	
	action create_patients(int number) {
		create BuildingIndividual number: number {
			date d <- copy(current_date) add_days rnd(0,6) ;
			ask world {do agenda_day_patient(d,myself.agenda_week);}
			age <- rnd(10,100);
			color <- #yellow;
			is_outside <- true;
		}
	}
	
	action create_doctors(int number) {
		create BuildingIndividual number: number {
			loop i from: 0 to:6 {
				date d <- copy(current_date) add_days i;
				if d.day_of_week = 7 {
					if flip(0.2) {
						ask world {do agenda_day_doctor(d,myself.agenda_week);}
					}
				} else if flip(0.8) {
					ask world {do agenda_day_doctor(d,myself.agenda_week);}
				}
			}
			age <- rnd(30,65);
			color <- #magenta;
			is_outside <- true;
		}
	}
	
	action agenda_day_patient(date d, map<date, BuildingActivity> agenda) {
		date d_ ;
		if flip(0.2) {
			d_ <- d add_hours rnd(0,7);
		} else if flip(0.6) {
			d_ <- d add_hours rnd(7,18);
		} else {
			d_ <- d add_hours rnd(18,23);
		}
		agenda[d_ ] <- first(ActivityGotoRoom);
		agenda[d_ add_minutes rnd(30,60)] <- first(ActivityLeaveArea);
	}
	
	action agenda_day_doctor(date d, map<date, BuildingActivity> agenda) {
		if flip(0.2) {
			agenda[d add_hours rnd(0,1)] <- first(ActivityGotoRoom);
			agenda[d add_hours rnd(7,9)] <- first(ActivityLeaveArea);
		} else if flip(0.6) {
			agenda[d add_hours rnd(7,10)] <- first(ActivityGotoRoom);
			agenda[d add_hours rnd(16,18)] <- first(ActivityLeaveArea);
				
		} else {
			agenda[d add_hours rnd(16,18)] <- first(ActivityGotoRoom);
			agenda[d add_hours rnd(23,23)] <- first(ActivityLeaveArea);
		}
	}
}

experiment hospital_no_intervention type: gui parent: "Abstract Experiment"{
	
	action _init_
	{   
		create simulation with: [
			//init_all_ages_proportion_wearing_mask::0.6,
			//init_all_ages_factor_contact_rate_wearing_mask:: 0.8,
			//ventilation_proba::0.7

		];
	}
}
