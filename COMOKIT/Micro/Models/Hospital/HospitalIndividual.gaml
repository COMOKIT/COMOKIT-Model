/**
* Name: HospitalIndividual
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


model HospitalIndividual

import "Hospital Spatial Entities.gaml"

import "HospitalActivity.gaml"
 
import "Hospital Experiments.gaml"

 
global {
	int nb_doctors <- 100;
	int nb_nurses <- 300;	
	int nb_staffs <- 100;
	
	int nb_in_patients <- 200;
	
	int nb_caregivers <- 200;
	
	int nb_interns <- 50;
	int nb_out_patients <- 2000;
	
	action create_individuals {
		do external_initilization;
		available_rooms <- list(Room);
		create Doctor number: nb_doctors;
		create Nurse number: nb_nurses;
		create Staff number: nb_staffs;
		create Intern number: nb_interns;
		create Inpatient number: nb_in_patients;
		create Caregiver number: nb_caregivers;
		
	}
	
	
	list<int> choose_working_days {
		map<int,float> weight_day <- map([0::0.9,1::1.0,2::0.7,3::1.0,4::0.9,5::0.6,6::0.2]);
		list<int> working_days <- [];
		loop times: rnd(5,6) {
			int index <- rnd_choice(weight_day.values);
			working_days<<weight_day.keys[index];
			remove key: weight_day.keys[index] from: weight_day;
		}
		return working_days;
	}
	
	
	reflex generate_patients_week when: every(#week){
		create Outpatient number: nb_out_patients;
		create Inpatient number: nb_in_patients;
		
	}
}
species Worker parent: BuildingIndividual {
	Room working_place;
}
species Doctor parent: Worker {
	rgb color <- #white;
	bool headdoc <- false;
	bool nightshift <- false;
	init {
		age <- int(skew_gauss(35.0, 65.0, 0.6, 0.3));
		
		working_place <- headdoc? one_of(available_rooms where (each.type = HEAD_DOCTOR_ROOM)):
								one_of(available_rooms where (each.type = DOCTOR_ROOM));
		
		if working_place != nil {
			available_rooms >> working_place;
		} else {
			do die;
		}
		
		list<int> working_days <- world.choose_working_days();
		loop i from: 0 to: 6 {
			if (copy(current_date) add_days i).day_of_week in working_days {
		
//		non nightshift: arrive ~6h30, meeting at 7h, visit inpatient from 7h30 - 8h15, 8h20 start work, 11h30 lunch,
//		13h30 start work, 17h50 go home
//		nightshift: 18h arrive, 19h work, 5h next day go home
		if(!nightshift){
			date arrive <- date("06:30", TFS) add_days i + rnd(15#mn);
			agenda_week[arrive] <- first(ActivityGoToOfficeHospital);
			date meeting <- date("07:00", TFS) add_days i;
			agenda_week[meeting] <- first(ActivityGoToMeeting);
			
			date visit <- date("07:30", TFS)  add_days i;
			loop while: visit < date('08:10', TFS) add_days i{
				agenda_week[visit] <- first(ActivityVisitInpatient);
				visit <- visit + rnd(3#mn, 5#mn);
			}
			
			date work <- date("08:20", TFS) add_days i;
			int choice <- rnd_choice([0.4,0.3,0.3]);
			if(headdoc){
				agenda_week[work] <- first(ActivityGoToOfficeHospital);
			}
			else{
				switch choice{
					match(0){
						agenda_week[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda_week[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda_week[work] <- first(ActivityGoToMinorOperation);
					}
				}
			}
			
			
			date lunch <- date("11:30", TFS) add_days i;
			agenda_week[lunch] <- first(ActivityLeaveArea);
			
			work <- date("13:30", TFS)  add_days i;
			if(headdoc){
				agenda_week[work] <- first(ActivityGoToOfficeHospital);
			}
			else{
				switch choice{
					match(0){
						agenda_week[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda_week[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda_week[work] <- first(ActivityGoToMinorOperation);
					}
				}
			}
			
		
			
			date end <- date("17:50", TFS) add_days i;
			agenda_week[end] <- first(ActivityLeaveArea);
		}
		
		else{
			date arrive <- date("18:00", TFS)  add_days i + rnd(15#mn);
			agenda_week[arrive] <- first(ActivityGoToOfficeHospital);
			
			date work <- date("19:00", TFS) add_days i;
			agenda_week[work] <- first(ActivityGoToAdmissionRoom);
			
			
			date meeting <- date('07:00', TFS) add_days (i+1);
			agenda_week[meeting] <- first(ActivityGoToMeeting);
			date end <- date('07:30', TFS) add_days (i+1);
			agenda_week[end] <- first(ActivityLeaveArea);
		}
		
		}
		
		}
		
	}

}

species Nurse parent: Worker {
	rgb color <-#blue;
	bool nightshift <- false;
	
	init {
		age <- int(skew_gauss(20.0, 60.0, 0.6, 0.3));
		
		working_place <- any(Room where (each.type = NURSE_ROOM));
		if working_place != nil {
			available_rooms >> working_place;
		} else {
			do die;
		}	
		
		list<int> working_days <- world.choose_working_days();
		loop i from: 0 to: 6 {
			if (copy(current_date) add_days i).day_of_week in working_days {

//		similar to daily rountine of doctor
		if(!nightshift){
			date arrive <- date("06:30", TFS) add_days i + rnd(15#mn);
			agenda_week[arrive] <- first(ActivityGoToOfficeHospital);
			
			date meeting <- date("07:00", TFS) add_days i;
			agenda_week[meeting] <- first(ActivityGoToMeeting);
			
			date visit <- date("07:30", TFS) add_days i;
			loop while: visit <= date("08:10", TFS) add_days i{
				agenda_week[visit] <- first(ActivityVisitInpatient);
				visit <- visit + rnd(3#mn, 5#mn);
			}
			
			date work <- date("08:20", TFS) add_days i;
			loop while: work <= date("11:10", TFS) add_days i{
				int choice <- rnd_choice([0.3,0.2,0.2, 0.3]);
				switch choice{
					match(0){
						agenda_week[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda_week[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda_week[work] <- first(ActivityGoToMinorOperation);
					}
					match(3){
						agenda_week[work] <- first(ActivityGetMedicine);
					}
				}
				work <- work + rnd(15#mn, 25#mn);
			}
			
			date lunch <- date("11:30", TFS) add_days i;
			agenda_week[lunch] <- first(ActivityLeaveArea);
			
			work <- date("13:30", TFS) add_days i;
			loop while: work <= date("17:30", TFS) add_days i{
				int choice <- rnd_choice([0.3,0.2,0.2,0.3]);
				switch choice{
					match(0){
						agenda_week[work] <- first(ActivityGoToAdmissionRoom);
					}
					match(1){
						agenda_week[work] <- first(ActivityGoToInjecting);
					}
					match(2){
						agenda_week[work] <- first(ActivityGoToMinorOperation);
					}
					match(3){
						agenda_week[work] <- first(ActivityGetMedicine);
					}
				}
				work <- work + rnd(15#mn, 25#mn);
			}
			
			date end <- date("17:50", TFS) add_days i;
			agenda_week[end] <- first(ActivityLeaveArea);
		}
		
		else{
			date arrive <- date("18:00", TFS) add_days i + rnd(15#mn);
			agenda_week[arrive] <- first(ActivityGoToOfficeHospital);
			
			date work <- date("19:00", TFS) add_days i;
			agenda_week[work] <- first(ActivityGoToAdmissionRoom);
			
			
			date meeting <- date('07:00', TFS) add_days (i+1);
			agenda_week[meeting] <- first(ActivityGoToMeeting);
			date end <- date('07:30', TFS) add_days (i+1);
			agenda_week[end] <- first(ActivityLeaveArea);
		}
		
		}
		
		}
	}

}

species Staff parent: Worker{
	rgb color <- #lightblue;
	
	init {
		age <- int(skew_gauss(20.0, 60.0, 0.6, 0.3));
		
		working_place <- any(Room where (each.type = HALL));
		if working_place != nil {
			available_rooms >> working_place;
		} else {
			do die;
		}	
		
		list<int> working_days <-  world.choose_working_days();
		loop i from: 0 to: 6 {
			if (copy(current_date) add_days i).day_of_week in working_days {
		
				date work <- date('08:00', TFS)  add_days i;
				loop while: work < date('11:00', TFS) add_days i{
					agenda_week[work] <- first(ActivityWander);
					work <- work + rnd(10#mn, 30#mn);
				}
				
				date lunch <- date('11:30', TFS) add_days i;
				agenda_week[lunch] <- first(ActivityLeaveArea);
				
				work <- date('13:30', TFS) add_days i;
				loop while: work < date('17:00', TFS)  add_days i{
					agenda_week[work] <- first(ActivityWander);
					work <- work + rnd(10#mn, 30#mn);
				}
				
				date end <- date("17:30", TFS)  add_days i;
				agenda_week[end] <- first(ActivityLeaveArea);
				
				}
			}
	}
}

species Inpatient parent: BuildingIndividual {
	rgb color <- #yellow;
	Bed mybed;
	Room assigned_ward;
	list<Caregiver> carer;
	
	init {
		
		has_to_renew_agenda <- false;
		age <- int(skew_gauss(20.0, 80.0, 0.6, 0.3));
		mybed <- any(Bed where (each.is_occupied = false));
		if mybed = nil {do die;}
		mybed.is_occupied <- true;
		assigned_ward <- mybed.my_room;
		current_room <- assigned_ward;
		location <- mybed.location;
		
		int nb_days <- rnd(1,7);
		int nb_start <- rnd(6);
		loop i from: nb_start to: nb_start + nb_days {
			date wander <- date("08:30", TFS) add_days i;
			loop while: wander < date('11:40', TFS) add_days i{
				agenda_week[wander] <- first(ActivityWanderInWardI);
				wander <- wander + rnd(5#mn, 10#mn);
			}
			
			date rest <- date("11:50", TFS) add_days i;
			agenda_week[rest] <- first(ActivityRest);
			
			wander <- date("13:30", TFS) add_days i;
			loop while: wander < date('17:30', TFS) add_days i{
				agenda_week[wander] <- first(ActivityWanderInWardI);
				wander <- wander + rnd(5#mn, 10#mn);
			}
			
			rest <- date("18:10", TFS) add_days i;
			agenda_week[rest] <- first(ActivityRest);
			
			wander <- date("19:00", TFS) add_days i;
			loop while: wander < date('21:00', TFS) add_days i{
				agenda_week[wander] <- first(ActivityWanderInWardI);
				wander <- wander + rnd(5#mn, 10#mn);
			}
			
			rest <- date("21:10", TFS) add_days i+ rnd(40#mn);
			agenda_week[rest] <- first(ActivityRest);
		}			
	}
	
	action remove_agent {
		mybed.is_occupied <- false;
		do die;
	}
	
	aspect default{
		if !is_outside and int(current_building) = building_map and current_floor = floor_map and (current_activity = first(ActivityRest)) and (location = mybed.location){
			draw pple_lie size: {0.5,people_size}  at: location + {0, 0, people_size/2.0} rotate: heading - 90 color: color;
			if(is_infected){draw circle(0.7)  at: location + {0, 0, 0.7} color: get_color();}
		}
		else if !is_outside and int(current_building) = building_map and current_floor = floor_map{
			draw pple_walk size: {0.5,people_size}  at: location + {0, 0, people_size/2.0} rotate: heading - 90 color: color;
			if(is_infected){draw circle(0.7)  at: location + {0, 0, 0.7} color: get_color();}
		}
	}

}

species Caregiver parent: BuildingIndividual {
	rgb color <- #orange;
	Inpatient sicker;
	init {
		age <- int(skew_gauss(20.0, 60.0, 0.6, 0.3));
		is_outside <- true;
		sicker <- any(Inpatient where (length(each.carer) < 2));
		ask sicker{
			carer << myself;
		}
		list<int> working_days <- world.choose_working_days();
		loop i from: 0 to: 6 {
			if (copy(current_date) add_days i).day_of_week in working_days {
	
				
				date breakfast <- date("06:30", TFS) add_days i+ rnd(10#minute);
				agenda_week[breakfast] <- first(ActivityLeaveArea);
		
				date care1 <- date("07:00", TFS) add_days i+ rnd(15#minute);
				agenda_week[care1] <- first(ActivityTakeCare);
				
				
				date care2 <- date("08:15", TFS) add_days i+ rnd(15#minute);
				agenda_week[care2] <- first(ActivityTakeCare);
				
				date wander <- date("08:40", TFS)add_days i;
				
				loop while: wander.hour < 11{
					agenda_week[wander] <- first(ActivityWanderInWardC);
					wander <- wander + rnd(5#mn, 10#mn);
				}
				
				date lunch <- date("11:30", TFS) add_days i +rnd(10#mn);
				agenda_week[lunch] <- first(ActivityLeaveArea);
				
				date care3 <- date("12:10", TFS)add_days i +rnd(10#mn);
				agenda_week[care3] <- first(ActivityTakeCare);
				
				wander <- date("13:30", TFS) add_days i;
				
				loop while: wander.hour  < 17{
					agenda_week[wander] <- first(ActivityWanderInWardC);
					wander <- wander + rnd(5#mn, 10#mn);
				}
				
			}
			
		}

	}

}

species Outpatient parent: BuildingIndividual{
	Doctor doc;
	date date_come;
	init{
		has_to_renew_agenda <- false;
		age <- int(skew_gauss(20.0, 80.0, 0.6, 0.3));
		
		doc <- one_of(Doctor where (each.headdoc = false and each.is_outside = false));
		date_come <- copy(current_date) add_hours rnd(23);
		int day <- rnd(6);
		// see doctor, go to do health examinations, see doctor again and go out
		date see_doc <- (date_come add_days day) + rnd(15#mn);
		agenda_week[see_doc] <- first(ActivityMeetDoctor);
		date test_perform <- see_doc +rnd(5#mn, 15#mn);
		//Temporary assume that they will do a health check at the admission room
		agenda_week[test_perform] <- first(ActivityGoToAdmissionRoom);
		see_doc <- test_perform +rnd(10#mn, 40#mn);
		agenda_week[see_doc] <- first(ActivityMeetDoctor);
		date out <- see_doc +rnd(10#mn, 25#mn);
		agenda_week[out] <- first(ActivityLeaveArea);
		
	}
}

species Intern parent: Worker{
	bool nightshift <- false;
	init {
		age <- int(skew_gauss(30.0, 40.0, 0.6, 0.3));
		
		working_place <- any(Room where (each.type = DOCTOR_ROOM));
		
		if (working_place = nil) {
			do die;
		}
		list<int> working_days <- world.choose_working_days();
		loop i from: 0 to: 6 {
			if (copy(current_date) add_days i).day_of_week in working_days {
	
			if(!nightshift){
				date arrive <- date("08:00", TFS) add_days i + rnd(15#mn);
				
				date work <- date("08:20", TFS) add_days i ;			
				
				work <- date("08:30", TFS) add_days i ;
				loop while: work <= date("11:30", TFS) add_days i {
					agenda_week[work] <- first(ActivityWander);
					work <- work + rnd(20#mn, 25#mn);
				}
				
				date lunch <- date("11:30", TFS) add_days i ;
				agenda_week[lunch] <- first(ActivityLeaveArea);
				
				work <- date("13:30", TFS) add_days i ;
				
				
				work <- date("14:00", TFS) add_days i ;
				loop while: work <= date("17:30", TFS) add_days i {
					agenda_week[work] <- first(ActivityWander);
					work <- work + rnd(10#mn, 15#mn);
				}
				
				date end <- date("17:50", TFS) add_days i ;
				agenda_week[end] <- first(ActivityLeaveArea);
			}
			
			else{
				date arrive <- date("18:00", TFS) add_days i + rnd(15#mn);
				agenda_week[arrive] <- first(ActivityGoToOfficeHospital);
				
				date work <- date("19:00", TFS) add_days i ;
				agenda_week[work] <- first(ActivityGoToAdmissionRoom);
				
				work <- date("19:30", TFS ) add_days i ;
				loop while: work <= date("23:00", TFS) add_days i {
					agenda_week[work]<- first(ActivityWander);
					work <- work + rnd(10#mn, 20#mn);
				}
				
				work <- date("23:00", TFS) add_days i ;
				agenda_week[work] <- first(ActivityGoToAdmissionRoom);
	
				date end <- date('07:30', TFS) add_days (i+1);
				agenda_week[end] <- first(ActivityLeaveArea);
			}	
			
			}
			
			}	
	}
}



