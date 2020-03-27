/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/


@no_experiment
model Species_Individual

import "../Constants.gaml"
import "../Parameters.gaml"
import "Building.gaml"
import "Activity.gaml"
import "Authority.gaml"


species Individual skills: [moving] {
	int ageCategory;
	int sex; //0 M 1 F
	string status; //susceptible, exposed, asymptomatic, infected, recovered, death
	bool wearMask;
	Building home;
	Building school;
	Building office;
	list<Individual> relatives;
	geometry bound;
	float incubation_time; //15 * 24h
	float recovery_time;
	float hospitalization_time;
	map<int, Activity> agenda_week;
	Activity last_activity;
	bool free_rider;
	int tick <- 0;

	reflex become_infected when: status = exposed and (tick >= incubation_time) {
		if (flip(epsilon)) {
			status <- asymptomatic;
			recovery_time <- rnd(max_recovery_time);
			tick <- 0;
		} else if (flip(sigma)) {
			status <- infected;
			recovery_time <- rnd(max_recovery_time);
			tick <- 0;
		}

	}

	reflex recovering when: (status = asymptomatic or status = infected) and (tick >= recovery_time) {
		if (flip(delta)) {
			status <- recovered;
			tick <- 0;
		} else {
			status <- death;
			tick <- 0;
		}

	}

	reflex executeAgenda {
		Activity act <- agenda_week[current_date.hour];
		if (act != nil) {
			last_activity <- act;
		}

		if (Authority[0].allows(self, last_activity)) {
			bound <- any(last_activity.find_target(self));
			location <- any_location_in(bound);
		}

		do wander bounds: bound speed: 0.001;
	}

	reflex updateDiseaseCycle {
		tick <- tick + 1;
	}

	reflex infectOthers when: (status = exposed) {
		list<Individual> neighbors <- (Individual at_distance 2 #m);
		if (length(neighbors) > 0) {
			if (flip(transmission_rate)) {
				ask R0 among neighbors {
					incubation_time <- rnd(max_incubation_time);
					status <- exposed;
				}

			}

		}

	}

	aspect default {
		draw shape color: status = exposed ? #pink : (status = infected ? #red : #green);
	}

}