/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Benoit Gaudou
* Tags: covid19,epidemiology
******************************************************************/

@no_experiment
model ActivitiesMonitor

import "Authority.gaml"

global {
	float decrease_act_study <- 0.0 
		update: (first(Authority).act_monitor != nil) ? (first(Authority).act_monitor.get_activity_decrease(act_studying)) : 0.0;
	float decrease_act_work <- 0.0 
		update: (first(Authority).act_monitor != nil) ? (first(Authority).act_monitor.get_activity_decrease(act_working)) : 0.0;
	float decrease_act_eat <- 0.0 
		update: (first(Authority).act_monitor != nil) ? (first(Authority).act_monitor.get_activity_decrease(act_eating)) : 0.0;
	float decrease_act_shopping <- 0.0 
		update: (first(Authority).act_monitor != nil) ? (first(Authority).act_monitor.get_activity_decrease(act_shopping)) : 0.0;
}

species ActivitiesMonitor schedules: [] {
	map<string,list<int>> stat_activities;
	
	action restart_day {
		stat_activities <- map([]);
	}
	
	action update_stat(Activity act, bool allowed) {
		
		if(stat_activities[act.name] = nil) {
			stat_activities[act.name] <- [0,0];
		}
		stat_activities[act.name][0] <- stat_activities[act.name][0] + 1;
		if(allowed) {
			stat_activities[act.name][1] <- stat_activities[act.name][1] + 1;		
		}		
	}	
	
	int get_activity_done(string activity_type) {
		return (stat_activities[activity_type] != nil) ? stat_activities[activity_type][1] : -1;
	}
	
	int get_activity_expected(string activity_type) {
		return (stat_activities[activity_type] != nil) ? stat_activities[activity_type][0] : -1;
	}
	
	float get_activity_decrease(string activity_type) {
		return (get_activity_expected(activity_type) > 0) 
				? (get_activity_done(activity_type) / get_activity_expected(activity_type)) - 1
				: 0.0;
	}
}


