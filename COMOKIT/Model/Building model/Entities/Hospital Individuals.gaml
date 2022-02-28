/**
* Name: HospitalIndividuals
* Based on the internal empty template. 
* Author: minhduc0711, Hoang Van Dong
* Tags: 
*/


model HospitalIndividuals

import "./BuildingIndividual.gaml"

species Doctor parent: BuildingIndividual {
	rgb color <- #white;
	bool headdoc <- false;
	bool nightshift <- false;
	init {
		
	}
	action initalization{
		Room r <- one_of(BuildingEntrance where (each.floor = 0));
		current_floor <- r.floor;
		location <- r.location + point([0, 0, r.floor*default_ceiling_height]);
		working_place <- headdoc? one_of(Room where (each.type = HEAD_DOCTOR_ROOM)):
								one_of(Room where (each.type = DOCTOR_ROOM));
		
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
//		non nightshift: arrive ~6h30, meeting at 7h, visit inpatient from 7h30 - 8h15, 8h20 start work, 11h30 lunch,
//		13h30 start work, 17h50 go home
//		nightshift: 18h arrive, 19h work, 5h next day go home
		if(!nightshift){
			date arrive <- date("06:30", TFS) + rnd(15#mn);
			agenda[arrive] <- first(ActivityGoToOffice);
			
			date meeting <- date("07:00", TFS);
			agenda[meeting] <- first(ActivityGoToMeeting);
			
			date visit <- date("07:30", TFS);
			loop while: visit < date('08:10', TFS){
				agenda[visit] <- first(ActivityVisitInpatient);
				visit <- visit + rnd(3#mn, 5#mn);
			}
			
			date work <- date("08:20", TFS);
			int choice <- rnd_choice([0.4,0.3,0.3]);
			if(headdoc){
				agenda[work] <- first(ActivityGoToOffice);
			}
			else{
				switch choice{
					match(0){
						agenda[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda[work] <- first(ActivityGoToMinorOperation);
					}
				}
			}
			
			work <- date("09:00", TFS);
			loop while: work <= date("11:10", TFS){
				agenda[work] <- first(ActivityWanderAround);
				work <- work + rnd(10#mn, 15#mn);
			}
			
			date lunch <- date("11:30", TFS);
			agenda[lunch] <- first(ActivityLeaveBuilding);
			
			work <- date("13:30", TFS);
			if(headdoc){
				agenda[work] <- first(ActivityGoToOffice);
			}
			else{
				switch choice{
					match(0){
						agenda[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda[work] <- first(ActivityGoToMinorOperation);
					}
				}
			}
			
			work <- date("14:00", TFS);
			loop while: work <= date("17:30", TFS){
				agenda[work] <- first(ActivityWanderAround);
				work <- work + rnd(10#mn, 15#mn);
			}
			
			date end <- date("17:50", TFS);
			agenda[end] <- first(ActivityLeaveBuilding);
		}
		
		else{
			date arrive <- date("18:00", TFS) + rnd(15#mn);
			agenda[arrive] <- first(ActivityGoToOffice);
			
			date work <- date("19:00", TFS);
			agenda[work] <- first(ActivityGoToAdmissionRoom);
			
			work <- date("19:30", TFS);
			loop while: work <= date("22:00", TFS){
				agenda[work]<- first(ActivityWanderAround);
				work <- work + rnd(10#mn, 20#mn);
			}
			date meeting <- date('07:00', TFS) add_days 1;
			agenda[meeting] <- first(ActivityGoToMeeting);
			date end <- date('07:30', TFS) add_days 1;
			agenda[end] <- first(ActivityLeaveBuilding);
		}
		
		return agenda;
	}

}

species Nurse parent: BuildingIndividual {
	rgb color <-#blue;
	bool nightshift <- false;
	init {
		
		Room r <- one_of(BuildingEntrance where (each.floor = 0));
		current_floor <- r.floor;
		location <- r.location + point([0, 0, r.floor*default_ceiling_height]);
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
//		similar to daily rountine of doctor
		if(!nightshift){
			date arrive <- date("06:30", TFS) + rnd(15#mn);
			agenda[arrive] <- first(ActivityGoToOffice);
			
			date meeting <- date("07:00", TFS);
			agenda[meeting] <- first(ActivityGoToMeeting);
			
			date visit <- date("07:30", TFS);
			loop while: visit <= date("08:10", TFS){
				agenda[visit] <- first(ActivityVisitInpatient);
				visit <- visit + rnd(3#mn, 5#mn);
			}
			
			date work <- date("08:20", TFS);
			loop while: work <= date("11:10", TFS){
				int choice <- rnd_choice([0.3,0.2,0.2, 0.3]);
				switch choice{
					match(0){
						agenda[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda[work] <- first(ActivityGoToMinorOperation);
					}
					match(3){
						agenda[work] <- first(ActivityGetMedicine);
					}
				}
				work <- work + rnd(15#mn, 25#mn);
			}
			
			date lunch <- date("11:30", TFS);
			agenda[lunch] <- first(ActivityLeaveBuilding);
			
			work <- date("13:30", TFS);
			loop while: work <= date("17:30", TFS){
				int choice <- rnd_choice([0.3,0.2,0.2,0.3]);
				switch choice{
					match(0){
						agenda[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda[work] <- first(ActivityGoToMinorOperation);
					}
					match(3){
						agenda[work] <- first(ActivityGetMedicine);
					}
				}
				work <- work + rnd(15#mn, 25#mn);
			}
			
			date end <- date("17:50", TFS);
			agenda[end] <- first(ActivityLeaveBuilding);
		}
		
		else{
			date arrive <- date("18:00", TFS) + rnd(15#mn);
			agenda[arrive] <- first(ActivityGoToOffice);
			
			date work <- date("19:00", TFS);
			agenda[work] <- first(ActivityGoToAdmissionRoom);
			
			work <- date("19:30", TFS);
			loop while:  work <= date("22:00", TFS){
				agenda[work]<- first(ActivityWanderAround);
				work <- work + rnd(10#mn, 20#mn);
			}
			date meeting <- date('07:00', TFS) add_days 1;
			agenda[meeting] <- first(ActivityGoToMeeting);
			date end <- date('07:30', TFS) add_days 1;
			agenda[end] <- first(ActivityLeaveBuilding);
		}
		return agenda;
	}

}

species Staff parent: BuildingIndividual{
	rgb color <- #lightblue;
	init {
		Room r <- one_of(BuildingEntrance where (each.floor = 0));
		current_floor <- r.floor;
		location <- r.location + point([0, 0, r.floor*default_ceiling_height]);
		working_place <- any(Room where (each.type = HALL));
		
		working_place.nb_affected <- working_place.nb_affected + 1;
		if not(working_place.is_available()) {
			available_offices >> working_place;
		}
		
		working_desk <- working_place.get_target(self,true);
		if (working_place = nil) {
			do die;
		}
	}
	map<date, BuildingActivity> get_daily_agenda {
		map<date, BuildingActivity> agenda;
		
		date work <- date('08:00', TFS);
		loop while: work < date('11:00', TFS){
			agenda[work] <- first(ActivityWander);
			work <- work + rnd(10#mn, 30#mn);
		}
		
		date lunch <- date('11:30', TFS);
		agenda[lunch] <- first(ActivityLeaveBuilding);
		
		work <- date('13:30', TFS);
		loop while: work < date('17:00', TFS){
			agenda[work] <- first(ActivityWander);
			work <- work + rnd(10#mn, 30#mn);
		}
		
		date end <- date("17:30", TFS);
		agenda[end] <- first(ActivityLeaveBuilding);
		
		return agenda;
	}
}

species Inpatient parent: BuildingIndividual {
	rgb color <- #yellow;
	Bed mybed;
	Room assigned_ward;
	list<Caregivers> carer;
	init {
		age <- int(skew_gauss(20.0, 80.0, 0.6, 0.3));
		is_outside <- false;
		mybed <- any(Bed where (each.is_occupied = false));
		mybed.is_occupied <- true;
		assigned_ward <- mybed.room;
		current_room <- assigned_ward;
		location <- mybed.location;
		current_floor <- current_room.floor;
		map<date,BuildingActivity> agenda_day;
		assigned_ward.people_inside << self;
	}
	
	map<date, BuildingActivity> get_daily_agenda {
		map<date, BuildingActivity> agenda;
		
		date wander <- date("08:30", TFS);
		loop while: wander < date('11:40', TFS){
			agenda[wander] <- first(ActivityWanderInWardI);
			wander <- wander + rnd(5#mn, 10#mn);
		}
		
		date rest <- date("11:50", TFS);
		agenda[rest] <- first(ActivityRest);
		
		wander <- date("13:30", TFS);
		loop while: wander < date('17:30', TFS){
			agenda[wander] <- first(ActivityWanderInWardI);
			wander <- wander + rnd(5#mn, 10#mn);
		}
		
		rest <- date("18:10", TFS);
		agenda[rest] <- first(ActivityRest);
		
		wander <- date("19:00", TFS);
		loop while: wander < date('21:00', TFS){
			agenda[wander] <- first(ActivityWanderInWardI);
			wander <- wander + rnd(5#mn, 10#mn);
		}
		
		rest <- date("21:10", TFS) + rnd(40#mn);
		agenda[rest] <- first(ActivityRest);
		
		return agenda;
	}
	
	aspect default{
		if!is_outside and (location overlaps circle(0.4, mybed.location)) and show_floor[current_floor]{
			draw pple_lie size: people_size  at: location + {0, 0, 0.85} rotate: 0 color: color;
			if(is_infected){draw circle(0.2)  at: location + {0, 0, 0.7} color: get_color();}
		}
		else if !is_outside and show_floor[current_floor]{
			draw pple_walk size: people_size  at: location + {0, 0, 0.7} rotate: heading - 90 color: color;
			if(is_infected){draw circle(0.2)  at: location + {0, 0, 0.7} color: get_color();}
		}
	}

}

species Caregivers parent: BuildingIndividual {
	rgb color <- #orange;
	Inpatient sicker;
	init {
		age <- rnd(18,60);
		sex <- rnd(1);
	}
	
	action initalization{
		is_outside <- false;
		sicker <- any(Inpatient where (length(each.carer) < 2));
		ask sicker{
			carer << myself;
		}
		current_room <- sicker.assigned_ward;
		current_floor <- current_room.floor;
		location <- any_location_in(inter(circle(rnd(1#m, 2#m), sicker.mybed.location), sicker.assigned_ward))
				    + point([0, 0, current_floor*default_ceiling_height]);
		sicker.assigned_ward.people_inside << self;
	}

	map<date, BuildingActivity> get_daily_agenda {
		map<date, BuildingActivity> agenda;

		date breakfast <- date("06:30", TFS) + rnd(10#minute);
		agenda[breakfast] <- first(ActivityLeaveBuilding);

		date care1 <- date("07:00", TFS) + rnd(15#minute);
		agenda[care1] <- first(ActivityTakeCare);
		
		date wait <- date("07:30", TFS);
		agenda[wait] <- first(ActivityWait);
		
		date care2 <- date("08:15", TFS) + rnd(15#minute);
		agenda[care2] <- first(ActivityTakeCare);
		
		date wander <- date("08:40", TFS);
		
		loop while: wander.hour < 11{
			agenda[wander] <- first(ActivityWanderInWardC);
			wander <- wander + rnd(5#mn, 10#mn);
		}
		
		date lunch <- date("11:30", TFS) +rnd(10#mn);
		agenda[lunch] <- first(ActivityLeaveBuilding);
		
		date care3 <- date("12:10", TFS) +rnd(10#mn);
		agenda[care3] <- first(ActivityTakeCare);
		
		wander <- date("13:30", TFS);
		
		loop while: wander.hour  < 17{
			agenda[wander] <- first(ActivityWanderInWardC);
			wander <- wander + rnd(5#mn, 10#mn);
		}
		
		return agenda;
	}

}

species Outpatients parent: BuildingIndividual{
	Doctor doc;
	date date_come;
	init{
		
	}
	action initialization{
		doc <- one_of(Doctor where (each.headdoc = false and each.is_outside = false));
		date_come <- current_date;
		Room r <- one_of(BuildingEntrance where (each.floor = 0));
		current_floor <- r.floor;
		location <- r.location + point([0, 0, r.floor*default_ceiling_height]);
	}
	
	map<date, BuildingActivity> get_daily_agenda {
		map<date, BuildingActivity> agenda;		

		// see doctor, go to do health examinations, see doctor again and go out
		date see_doc <- date_come + rnd(15#mn);
		agenda[see_doc] <- first(ActivityMeetDoctor);
		date test_perform <- see_doc +rnd(5#mn, 15#mn);
		//Temporary assume that they will do a health check at the admission room
		agenda[test_perform] <- first(ActivityGoToAdmissionRoom);
		see_doc <- test_perform +rnd(10#mn, 40#mn);
		agenda[see_doc] <- first(ActivityMeetDoctor);
		date out <- see_doc +rnd(10#mn, 25#mn);
		agenda[out] <- first(ActivityLeaveBuilding);
		
		return agenda;
	}
}

species Interns parent: BuildingIndividual{
	bool nightshift <- false;
	init{
		
	}
	action initialization{
		Room r <- one_of(BuildingEntrance where (each.floor = 0));
		current_floor <- r.floor;
		location <- r.location + point([0, 0, r.floor*default_ceiling_height]);
		working_place <- any(Room where (each.type = DOCTOR_ROOM));
		
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
		if(!nightshift){
			date arrive <- date("08:00", TFS) + rnd(15#mn);
			
			date work <- date("08:20", TFS);			
			
			work <- date("08:30", TFS);
			loop while: work <= date("11:30", TFS){
				agenda[work] <- first(ActivityWander);
				work <- work + rnd(20#mn, 25#mn);
			}
			
			date lunch <- date("11:30", TFS);
			agenda[lunch] <- first(ActivityLeaveBuilding);
			
			work <- date("13:30", TFS);
			
			
			work <- date("14:00", TFS);
			loop while: work <= date("17:30", TFS){
				agenda[work] <- first(ActivityWander);
				work <- work + rnd(10#mn, 15#mn);
			}
			
			date end <- date("17:50", TFS);
			agenda[end] <- first(ActivityLeaveBuilding);
		}
		
		else{
			date arrive <- date("18:00", TFS) + rnd(15#mn);
			agenda[arrive] <- first(ActivityGoToOffice);
			
			date work <- date("19:00", TFS);
			agenda[work] <- first(ActivityGoToAdmissionRoom);
			
			work <- date("19:30", TFS);
			loop while: work <= date("23:00", TFS){
				agenda[work]<- first(ActivityWander);
				work <- work + rnd(10#mn, 20#mn);
			}
			
			work <- date("23:00", TFS);
			agenda[work] <- first(ActivityGoToAdmissionRoom);

			date end <- date('07:30', TFS) add_days 1;
			agenda[end] <- first(ActivityLeaveBuilding);
		}		
		return agenda;
	}
}


