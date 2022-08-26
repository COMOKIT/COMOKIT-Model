/**
* Name: Evaluate
* 
* These experiments sort the output .csv file of headless experiment from
* "./Sensitivity_experiments.gaml" depending on seed.
* Then they compute Sobol and Morris indices the corresponding simulations.
* 
* Author: Raphaël Dupont
* Tags: Sensitivity
*/

model Evaluate

global{
	
	//----------------------------------------//
	//    Parameters for sobol and morris     //
	//----------------------------------------//
	int nb_param <- 8;												// Number of variable in the model
	string input_path <- "./Results/Results_COMOKIT.csv"; 			// Path to evaluated model
	string sobol_report <- "./Results/COMOKIT_sobol_report.txt"; 	// Path to report for sobol
	string morris_report <- "./Results/COMOKIT_morris_report.txt"; 	// Path to report for morris
	
	
	
	
	// Sort the input file depending on seed
	string sorted_path <- "./Results/final_results_COMOKIT.csv";
	init{
		write "Sorting the input file..";
		csv_file my_csv_file <- csv_file(input_path, "," ,string, false);
		matrix<string> data <- matrix<string>(my_csv_file);
		list<list<string>> values;
		
		loop i from:1 to: data.rows - 1 {
			add list<string>(data row_at i) to:values;
		}
						
		list<list<string>> sorted_values <- values sort_by (int(each[data.columns - 1]));
		matrix<string> sorted_data <- matrix<string>(sorted_values);
		matrix<string> headers <- matrix<string>(data row_at 0);	
		sorted_data <- (append_vertically(headers, reverse(sorted_data)));
		
		string s <- "";
		loop i from:0 to: sorted_data.rows - 1{
			loop j from:0 to: sorted_data.columns - 2 {
				s <- s + sorted_data[j,i];
				if(j != sorted_data.columns - 2){
					s <- s + ",";
				}
			}
			if(i != sorted_data.rows - 1){
				s <- s + "\n";
			}
		}
		save s to:sorted_path type:csv header:false;
		write "Done. \"" + sorted_path + "\" created.\n";
	}
	
	reflex{
		do pause;
	}
}

experiment Sobol type:gui autorun:true{
	reflex{
		write "Start analysis.." color:rgb(150,0,0);
		write sobolAnalysis(
			sorted_path,		// Path to evaluated model
			sobol_report, 		// Path to report
			nb_param			// Number of variable in the model
		) color:rgb(150,0,0);
		write "Done." color:rgb(150,0,0);
	}
}

experiment Morris type:gui autorun:true{
	reflex{
		write "Start analysis.." color:rgb(150,0,0);
		string s <- morrisAnalysis(
			sorted_path,	// Path to evaluated model
			4,				// Number of level
			nb_param		// Number of variable in the model
		);
		write s color:rgb(150,0,0);
		save s to: morris_report;
		write "Done" color:rgb(150,0,0);
	}
}