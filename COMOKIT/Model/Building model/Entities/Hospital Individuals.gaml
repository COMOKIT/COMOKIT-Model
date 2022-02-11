/**
* Name: HospitalIndividuals
* Based on the internal empty template. 
* Author: minhduc0711, Hoang Van Dong
* Tags: 
*/


model HospitalIndividuals

import "./BuildingIndividual.gaml"

species Doctor parent: BuildingIndividual {
	init {
		location <- any_location_in(one_of(BuildingEntrance).init_place);
		working_place <- one_of(Room where (each.type = DOCTOR_ROOM));
		
		if not(working_place.is_available()) {
			available_offices >> working_place;
		}
		
		working_desk <- working_place.get_target(self, true);
		if (working_place = nil) {
			do die;
		}
	}
	
	map<date, BuildingActivity> get_daily_agenda {
		map<date, BuildingActivity> agenda;
		
		date arriving_time <- date("05:30", TIME_FORMAT_STR) + rnd(arrival_time_interval);
		// Daily meeting
		date meeting_time <- date("06:00", TIME_FORMAT_STR);
		if arriving_time >= meeting_time {
			agenda[arriving_time] <- first(ActivityGoToMeeting);
		} else {
			// If arrived a bit early, go to office to wait
			agenda[arriving_time] <- first(ActivityGoToOffice);
			agenda[meeting_time] <- first(ActivityGoToMeeting);
		}
		// Morning shift
		date work_time <- date("07:00", TIME_FORMAT_STR);
		// Alternate between working at office, admitting new patients and visit inpatients
		loop while: work_time.hour < 12 {
			int choice <- rnd_choice([0.5, 0.3, 0.2]);
			if choice = 0 {
				agenda[work_time] <- first(ActivityGoToOffice);
				work_time <- work_time + rnd(20#mn, 30#mn); 
			} else if choice = 1 {
				agenda[work_time] <- first(ActivityGoToAdmissionRoom);
				work_time <- work_time + rnd(5#mn, 15#mn);
			} else if choice = 2 {
				agenda[work_time] <- first(ActivityVisitInpatient);
				work_time <- work_time + rnd(5#mn, 10#mn);
			}
		}
		
		// Lunch time
		agenda[work_time] <- first(ActivityLeaveBuilding);
		
		// Afternoon shift
		work_time <- date("13:00", TIME_FORMAT_STR);
		// Alternate between working at office, admitting new patients and visit inpatients
		loop while: work_time.hour < 18 {
			int choice <- rnd_choice([0.5, 0.3, 0.2]);
			if choice = 0 {
				agenda[work_time] <- first(ActivityGoToOffice);
				work_time <- work_time + rnd(20#mn, 30#mn); 
			} else if choice = 1 {
				agenda[work_time] <- first(ActivityGoToAdmissionRoom);
				work_time <- work_time + rnd(5#mn, 15#mn);
			} else if choice = 2 {
				agenda[work_time] <- first(ActivityVisitInpatient);
				work_time <- work_time + rnd(5#mn, 10#mn);
			}
		}
		
		// Leave for dinner / go home
		agenda[work_time] <- first(ActivityLeaveBuilding);
		
		// Might do a night shift
		if flip(0.3) {
			work_time <- date("19:00", TIME_FORMAT_STR);
			agenda[work_time] <- first(ActivityGoToOffice);
		}
		return agenda;
	}

}

species Nurse parent: BuildingIndividual {
	init {
		location <- any_location_in(one_of(BuildingEntrance).init_place);
		working_place <- any(Room where (each.type = NURSE_ROOM));
		
		if not(working_place.is_available()) {
			available_offices >> working_place;
		}
		
		working_desk <- working_place.get_target(self, true);
		if (working_place = nil) {
			do die;
		}
	}

	map<date, BuildingActivity> get_daily_agenda {
		map<date, BuildingActivity> agenda;
		
		date arriving_time <- date("05:30", TIME_FORMAT_STR) + rnd(arrival_time_interval);
		// Daily meeting
		date meeting_time <- date("06:00", TIME_FORMAT_STR);
		if arriving_time >= meeting_time {
			agenda[arriving_time] <- first(ActivityGoToMeeting);
		} else {
			// If arrived a bit early, go to office to wait
			agenda[arriving_time] <- first(ActivityGoToOffice);
			agenda[meeting_time] <- first(ActivityGoToMeeting);
		}
		
		date work_time <- date("06:15", TIME_FORMAT_STR);
		loop while: work_time.hour < 12 {
			if flip(0.7) {
				agenda[work_time] <- first(ActivityVisitInpatient);
				work_time <- work_time + rnd(3#mn, 5#mn); 
			} else {
				agenda[work_time] <- first(ActivityGoToAdmissionRoom);
				work_time <- work_time + rnd(10#mn, 15#mn); 
			}
		}

		date lunch_time <- work_time;
		agenda[work_time] <- first(ActivityLeaveBuilding);
		
		// Afternoon shift
		work_time <- date("13:00", TIME_FORMAT_STR);
		// Alternate between working at office, admitting new patients and visit inpatients
		loop while: work_time.hour < 18 {
			if flip(0.7) {
				agenda[work_time] <- first(ActivityVisitInpatient);
				work_time <- work_time + rnd(3#mn, 5#mn); 
			} else {
				agenda[work_time] <- first(ActivityGoToAdmissionRoom);
				work_time <- work_time + rnd(10#mn, 15#mn); 
			}
		}

		// Go home
		agenda[work_time] <- first(ActivityLeaveBuilding);
		
		// Night shift
		if flip(0.3) {
			work_time <- date("19:00", TIME_FORMAT_STR);
			agenda[work_time] <- first(ActivityGoToOffice);
		}
		
		return agenda;
	}

}

species Staff parent: BuildingIndividual{
	init {
		location <- any_location_in(one_of(BuildingEntrance).init_place);
		working_place <- one_of(Room where (each.type = HALL));
		
		working_place.nb_affected <- working_place.nb_affected + 1;
		if not(working_place.is_available()) {
			available_offices >> working_place;
		}
		
		working_desk <- working_place.get_target(self,true);
		if (working_place = nil) {
			do die;
		}
	}
}

species Inpatient parent: BuildingIndividual {
	Bed mybed;
	Room assigned_ward;
	list<Caregivers> carer;
	init {
		wandering <- true;
		is_outside <- false;
//		assigned_ward <- one_of(Room where (each.type = WARD and each.nb_affected < 5));
//
//		assigned_ward.people_inside << self;
//		current_room <- assigned_ward;
//		dst_room <- assigned_ward;
		mybed <- any(Bed where (each.is_occupied = false));
		mybed.is_occupied <- true;
		assigned_ward <- mybed.room;
		current_room <- assigned_ward;
		location <- mybed.location;
		map<date,BuildingActivity> agenda_day;
		assigned_ward.people_inside << self;
	}
	
	map<date, BuildingActivity> get_daily_agenda {
		return map<date, BuildingActivity>([]);
	}
	
	aspect default{
		if(location = mybed.location){
			draw pple_lie size: 1.7  at: location + {0, 0, 0.85} rotate: 0 color: color;
			if(is_infected){draw circle(0.2)  at: location + {0, 0, 0.7} color: get_color();}
		}
		else{
			draw pple_walk size: people_size  at: location + {0, 0, 0.7} rotate: heading - 90 color: color;
			if(is_infected){draw circle(0.2)  at: location + {0, 0, 0.7} color: get_color();}
		}
	}

}

species Caregivers parent: BuildingIndividual {
	Inpatient sicker;
	BenchWait bench;
	init {
		// Some visitor might be infectious
		if (flip(0.2)) {
			do define_new_case;
			latent_period <- 0.0;
		}
	}
	
	action initalization{
		is_outside <- false;
		sicker <- any(Inpatient where (length(each.carer) < 2));
		ask sicker{
			carer << myself;
		}
		location <- any_location_in(circle(rnd(1#m, 2#m), sicker.mybed.location));
	}

	map<date, BuildingActivity> get_daily_agenda {
		map<date, BuildingActivity> agenda;

		date breakfast <- date("06:00", TIME_FORMAT_STR) + rnd(10#minute);
		agenda[breakfast] <- first(ActivityLeaveBuilding);

		date care1 <- date("06:30", TIME_FORMAT_STR) + rnd(15#minute);
		agenda[care1] <- first(ActivityTakeCare);
		
		return agenda;
	}

}

species interns parent: BuildingIndividual{
	
}


