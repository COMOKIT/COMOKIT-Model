/***
* Name: NewModel
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model NewModel

global {
 init{
 		write gama.pref_gis_auto_crs;
 		write  bool(experiment get "pref_gis" );
 		gama.pref_gis_auto_crs <- bool(experiment get "pref_gis" );
		gama.pref_gis_default_crs <- int(experiment get "crs");
 }
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
bool pref_gis <- gama.pref_gis_auto_crs ;
		int crs <- gama.pref_gis_default_crs;
	
		action _init_ {
		
		gama.pref_gis_auto_crs <- false;
		gama.pref_gis_default_crs <- 3857;
		create simulation;
		
		}
		output {}
}
