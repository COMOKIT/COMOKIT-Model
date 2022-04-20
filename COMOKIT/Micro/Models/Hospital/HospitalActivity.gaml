/**
* Name: HospitalActivity
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


model HospitalActivity

import "Hospital Experiments.gaml"

 

// Activities of Doctors
species ActivityGoToOffice parent: BuildingActivity {
	map get_destination(BuildingIndividual p) {
		Worker w <- Worker(p);
		Room r <- w.working_place;
		map results;
		results[key_room] <- r;
		return results; 
	}
}

species ActivityVisitInpatient parent: BuildingActivity {
	float wandering_in_room <- 5#mn;
	map get_destination(BuildingIndividual p) {
		Inpatient patient_to_visit <- one_of(Inpatient);
		Room r <- patient_to_visit.assigned_ward;
		map results;
		results[key_room] <- r;
		return results; 
	}
}



species ActivityGoToAdmissionRoom parent: ActivityGotoRoom {
	string type <-ADMISSION_ROOM;
	float wandering_in_room <- 5#mn;
	
}

species ActivityGoToMeeting parent: ActivityGotoRoom {
	string type <-MEETING_ROOM;
	float wandering_in_room <- 5#mn;
	
}

species ActivityGoToInjecting  parent: ActivityGotoRoom {
	float wandering_in_room <- 5#mn;
	string type <-INJECT;
}
species ActivityGoToMinorOperation  parent: ActivityGotoRoom {
	float wandering_in_room <- 5#mn;
	string type <-MINOPERATION;
}

// Activities of Nurses

species ActivityGetMedicine parent: ActivityGotoRoom {
	string type <-MEDICINE;
	bool closest <-true;
}
	

// Activities of Staffs

species ActivityWander parent: ActivityGotoRoom{
	float wandering_between_room <- 15#mn;
	
}

// Activities of inpatients

species ActivityRest parent: BuildingActivity{
	map get_destination(BuildingIndividual p) {
		Inpatient w <- Inpatient(p);
		Room r <- w.assigned_ward;
		map results;
		results[key_room] <- r;
		return results; 
	}
}

species ActivityWanderInWardI parent: ActivityRest{
	float wandering_in_room <- 10#mn;
}

// Activities of outpatients
species ActivityMeetDoctor parent: BuildingActivity{
	map get_destination(BuildingIndividual p) {
		Room r <-Outpatient(p).doc.working_place;
		map results;
		results[key_room] <- r;
		return results; 
	}
}
// Activities of caregivers
species ActivityTakeCare parent: BuildingActivity{
	map get_destination(BuildingIndividual p) {
		Room r <-Caregiver(p).sicker.assigned_ward;
		map results;
		results[key_room] <- r;
		return results; 
	}
}


species ActivityWanderInWardC parent: BuildingActivity{
	float wandering_in_room <- 10#mn;
	map get_destination(BuildingIndividual p) {
		Room r <-Caregiver(p).sicker.assigned_ward;
		map results;
		results[key_room] <- r;
		return results; 
	}
	
}