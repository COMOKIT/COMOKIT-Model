/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/

@no_experiment

model Policy

import "Individual.gaml"
species Policy {
	map<string, bool> allowed_activities;
	bool is_allowed (Individual i, Activity activity) {
		if (allowed_activities[activity.name] != nil) {
			return allowed_activities[activity.name];
		} else {
			return true;
		}

	}

}

/**
 * Same as Policy but a proportion of normally forbidden activities are allowed
 */
species PartialPolicy parent: Policy {
	
	float tolerance; // between 0 (no tolerance) and 1.0
	
	bool is_allowed (Individual i, Activity activity) {
		
		bool allowed <- super.is_allowed(i, activity);
		if (!allowed) {
			allowed <- flip(tolerance);
		} 
	return allowed;
	}
}

species SpatialPolicy parent: Policy {
	geometry application_area;
	bool is_allowed (Individual i, Activity activity) {
		if (application_area overlaps i) {
			if (allowed_activities[activity.name] != nil) {
				return allowed_activities[activity.name];
			} else {
				return true;
			}

		}else{
			return true;
		}

	}
}

species DetectionPolicy parent:Policy {
	int nb_individual_tested_per_step;
	bool symptomatic_only;
	bool not_tested_only;
	
	reflex applyPolicy
	{
		list<Individual> individual_to_test <- symptomatic_only?(not_tested_only?Individual where(each.status=symptomatic_with_symptoms and each.report_status=not_tested)
			:Individual where(each.status=symptomatic_with_symptoms)):(not_tested_only?Individual where(each.status!=dead and each.report_status=not_tested):Individual where(each.status!=dead));
		ask nb_individual_tested_per_step among individual_to_test
		{
			do testIndividual;
		}
	}
}
species TemporaryWithDetectedPolicy parent: Policy {
	float time_applied;
	int min_reported;
	bool applied;
	bool applying; 
	
	reflex applyPolicy
	{
		if(applying)
		{
			time_applied <- time_applied - step;
			if(time_applied<=0)
			{
				applying <- false;
				applied <- true;
			}
		}
		if(total_number_reported>min_reported)and(applying=false)and(applied=false)
		{
			applying <- true;
		}
	}
	bool is_allowed (Individual i, Activity activity){
		bool allowed <- applying? false:super.is_allowed(i, activity);
		return allowed;
	}
}