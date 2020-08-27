/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* This file contains experiments to track the number of actual contact
* and estimate according to a given R0 the beta parameters
* 
* Author: Chapuis Kevin, Philippon Damien
* Tags: covid19,epidemiology
******************************************************************/


model BetaCalibration

import "../Experiments/Baseline/No containment.gaml"

global {
	
	action _init_ {
		if _contact_tracking {
			do before_init;
			do init_epidemiological_parameters;
			do global_init;
			do create_authority;
			do after_init;
		} else {
			world.shape <- square(1000#m);
			do init_pseudo_outbreak;
		}
	}
	
	action create_uniform_indiv {
		create pseudo_individual number:noi
		{
			age <- rnd(max_age);
			do initialise_epidemio;
		}
	}
	
	action create_realistic_indiv {
		do read_mapping();
		create pseudo_individual from:csv_population with:[age::convert_age(get(age_var))] {
			do initialise_epidemio;
		}
	}
	
	/**************/
	/* PARAMETERS */
	/**************/
	
	// Expected R0 for both estimation and calibration of beta value
	float target_R0 <- 2.7 min:0.1;
	
	// Utilities output
	bool DEBUG <- true;
	string output_folder <- "../beta_output/";
	string output_contact_tracking_file <- "Contact_and_Beta.csv";
	string output_beta_calibration_file <- "Beta_calibration.csv";
	
	// Utilities simulation
	int nb_infected <- num_infected_init update: length(pseudo_individual where (each.is_infected));
	
	/********************/
	/* CONTACT TRACKING */
	/********************/
	
	// PARAMETERS
	float duration_xp <- 1#month min:#week; // Duration of a run for contact tracking
	
	// INNER VARIABLES
	bool _contact_tracking <- false;
	float _timeframe;
	float _cday;
	list<int> _contact_a_day <- [];
	
	reflex save_end when:_contact_tracking and step>0 and cycle=int(duration_xp/step)-1 {
		int idx <- 0;
		list<int> week_days <- [];
		list<int> week_ends <- [];
		loop cad over:_contact_a_day {
			if idx < 4 {
				week_days <+ cad;	
				idx <- idx + 1;
			} else if idx <= 6 {
				week_ends <+ cad;
				idx <- idx=6 ? 0 : idx+1;
			} 
		}
		float mn <- mean(_contact_a_day);
		int md <- median(_contact_a_day); 
		float average_contact_nb_per_step <- mn/2/#day*step;
		float median_contact_nb_per_step <- md/2/#day*step;
		
		save [name,mn,mean(week_days),mean(week_ends),
			average_contact_nb_per_step,median_contact_nb_per_step,
			target_R0/global_infectious_period()/average_contact_nb_per_step*nb_step_for_one_day,
			target_R0/global_infectious_period()/median_contact_nb_per_step*nb_step_for_one_day
		] 
		type:csv to:output_folder+output_contact_tracking_file header:false rewrite:false;
	}
	
	/*
	 * Track the average number of contact per days  
	 */
	reflex nb_contact_per_day when:_contact_tracking {
		_cday <- _cday + mean(all_individuals collect nb_contacts(each));
		_timeframe <- _timeframe+step;
		if _timeframe>=#day { _timeframe <- 0.0; _contact_a_day <+ _cday; _cday <- 0.0; }
	}
	
	float nb_contacts(Individual indiv) {
		float contacts <- 0.0;
		ask indiv {
			if is_at_home { 
				contacts <- contacts + relatives count each.is_at_home; 
				contacts <- contacts + (length(current_place.individuals)-contacts)*reduction_coeff_all_buildings_inhabitants;
			} else { 
				contacts <- contacts + length(activity_fellows); 
				contacts <- contacts + (length(current_place.individuals)-contacts)*reduction_coeff_all_buildings_individuals;
			}
		}
		return contacts;
	}
	
	/*
	 * Gives the theoretical global infectious period taking into 
	 * account distribution from age and symptomatic/asymptomatic and
	 * actual demographic distribution of the population 
	 */
	float global_infectious_period {
		float gip;
		
		map<int,int> demography;
		ask all_individuals { 
			if demography contains_key age {demography[age] <- demography[age]+1;}
			else {demography[age] <- 1;}
		}
		
		loop i over:demography.keys { 
			float prop_ia <- float(map_epidemiological_parameters[i][epidemiological_proportion_asymptomatic][1]);
			gip <- gip + get_infectious_period_symptomatic(i)*demography[i]*(1-prop_ia) +
					get_infectious_period_asymptomatic(i)*demography[i]*prop_ia;
		}
		
		return gip/length(all_individuals);
	}
	
	/********************/
	/* BETA CALIBRATION */
	/********************/
	
	// PARAMETERS
	bool from_real_population <- false; // If you want agent population to be launch from a file
	int noi <- 1000; // Otherwise create 'noi' random individuals
	bool init_from_contact_tracking <- true; // Take average number of contact and initial beta from 'batch_Contact_Tracking' outputs
	float inc; // Increment of beta value for calibration purpose
	float actual_contact_rate; // The average contact rate per step
	float Re; // The actual average number of infected agent per infectious agent
	float Re_fitness -> abs(target_R0 - Re); // Difference between Re and expected R0 for calibration (fitness)
	
	// INNER VARIABLES
	int _incidence;
	float _estimated_beta;
	
	// COMOKIT PARAMETERS
	file csv_parameters <- file_exists(epidemiological_parameters)?csv_file(epidemiological_parameters):nil;
	int num_infected_init <- 1;
	bool load_epidemiological_parameter_from_file <- true;
	
	// Stop batch simulation
	bool stop_sim { return nb_infected=0 and cycle>1; }
	
	/*
	 * Track the actual number of agent infected by other infectious agent to compute Re
	 */ 
	reflex inspect_indexes {
		total_number_of_infected <- total_number_of_infected + _incidence;
		_incidence <- 0;
		Re <- mean(pseudo_individual where (each.nb_trans>0) collect (each.nb_trans));
		if every(#month) {do console_output(string(int(cycle*step/#day))+" days = "
			+sample(Re)+" | "+sample(total_number_of_infected),
			string(self),first(levelList)
		);}
	}
	
	/*
	 * Initialization of a pseudo simulation without any buildings and constraints contact rate
	 * to calibrate beta
	 */
	action init_pseudo_outbreak {
		float t <- machine_time;
		do console_output("start beta calibration initialization",string(self));
		
		do create_authority;
		do init_epidemiological_parameters;
		
		if init_from_contact_tracking and file_exists(output_folder+output_contact_tracking_file) {
			csv_file contact_csv <- csv_file(output_folder+output_contact_tracking_file,true);
			
			int idx <- contact_csv.attributes index_of "average contacts per step";
			list<float> contact <- range(contact_csv.contents.rows-1) collect 
				float(contact_csv.contents[idx,each]);
			actual_contact_rate <- mean(contact);
			do console_output("-- estimated number of contact per step is "+actual_contact_rate,string(self));
			
			idx  <- contact_csv.attributes index_of "estimated beta from average contacts";
			list<float> estimated_betas <- range(1,contact_csv.contents.rows-1) collect 
				float(contact_csv.contents[idx,each]);
			_estimated_beta <- mean(estimated_betas);
			
			loop aYear from:0 to: max_age {
				map_epidemiological_parameters[aYear][epidemiological_successful_contact_rate_human][1] <- string(_estimated_beta);
			}
			do console_output("-- estimated beta is "+_estimated_beta,string(self));
		} else if actual_contact_rate=0 {
			error "You must specify a contact rate (or run batch_Contact_Tracking first) when launching beta calibration";
		}
				
		if from_real_population {do create_realistic_indiv();}
		else {do create_uniform_indiv();}
		
		ask pseudo_individual { contact_rate <- contact_rate+inc;}
		
		do console_output("create pseudo individual with beta "
			+any(pseudo_individual).contact_rate+" and "+actual_contact_rate+" contact rate",string(self)
		);
		
		ask num_infected_init among pseudo_individual { do define_new_case; }
		do console_output("Population pseudo_individual "+length(pseudo_individual), string(self));
		do console_output("end of init ("+with_precision((machine_time-t)*1000,2)+"s)",string(self));
	}
	
}

/*
 * 
 * A simplified version of COMOKIT Individuals agent to mimic an unhindered outbreak 
 */
species pseudo_individual parent:BiologicalEntity {
	
	int nb_trans;
	
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: is_infectious {
		//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		float reduction_factor <- 1.0;
		if is_asymptomatic { reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic; }
		
		//Perform human to human transmission
		if allow_transmission_human {
			float proba <- contact_rate*reduction_factor;
			int acr <- int(actual_contact_rate)+(flip(actual_contact_rate-int(actual_contact_rate))?1:0);
			list<pseudo_individual> fellows <- (acr among pseudo_individual) where (flip(proba) and (each.state = susceptible));
			nb_trans <- nb_trans + length(fellows);
			_incidence <- _incidence + length(fellows);
			ask fellows { do define_new_case; }
	 	}
		
	}
	
}

/*
 * The batch experiment that makes it possible to track the average number of contact
 * in a model setup (given an agenda, type of buildings, weights on activity x building types, etc.)
 */ 
experiment batch_Contact_Tracking parent:"Abstract Experiment" type:batch 
	repeat:12 until:cycle>=duration_xp/step keep_simulations:false {

	parameter "experiment length" var:duration_xp init:#month min:#day max:31536000.0;
	parameter "estimated R0" var:target_R0 init:2.7 min:0.1;

	// string DEFAULT_DATASETS_FOLDER_NAME <- "your_datasets_folder_name";
	// string DEFAULT_CASE_STUDY_FOLDER_NAME <- "your_case_study_folder_name";
	string output_folder <- "../beta_output/"; // WARNING: should be the same as in above model
	string output_contact_tracking_file <- "Contact_and_Beta.csv"; // WARNING: should be the same as in above model

	init {
		dataset_path <- build_dataset_path();
		_contact_tracking <- true;
		save ["name","average contacts a day","average contacts a day of week",
			"average contacts a day of weekend", "average contacts per step",
			"median contacts per step", "estimated beta from average contacts",
			"estimated beta from median contacts"
		] type:csv to:output_folder+output_contact_tracking_file header:false rewrite:true;
	}
}

/*
 * Calibration of beta according to a given R0 and contact rate
 */
experiment estimate_beta type:batch until:world.stop_sim() repeat:4 keep_seed:true {
	
	parameter 'increment contact rate' var: inc init: 0.0 min:0.0 max: 0.01 step:0.001;
	method exhaustive minimize: Re_fitness;
		
	//the permanent section allows to define a output section that will be kept during all the batch experiment
	permanent {
		display Comparison {
			chart "Post estimated transmission (Re)" type: series {
				//we can access to all the simulations of a run (here composed of 5 simulation -> repeat: 5) by the variable "simulations" of the experiment.
				//here we display for the 5 simulations, the mean, min and max values of the nb_infected variable.
				data "Mean" value: mean(simulations collect each.Re ) style: spline color: #blue ;
				data "Min" value:  min(simulations collect each.Re ) style: spline color: #darkgreen ;
				data "Max" value:  max(simulations collect each.Re ) style: spline color: #red ;
			}
		}	
	}
	
	reflex save_result {
		if int(first(simulations))=0 {
			save ["simulation","beta","Re","Fitness"] 
				type:csv to:output_folder+output_beta_calibration_file header:false rewrite:true;
		}
		ask simulations {
			save [string(self),inc+_estimated_beta,Re,Re_fitness] 
				type:csv to:output_folder+output_beta_calibration_file header:false rewrite:false;
		}
	}
	
}

