/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Rooms represent in COMOKIT spatial entities where Individuals gather 
* to undertake their Activities. They are provided with a viral load to
* enable environmental transmission. 
* 
* Authors:Patrick Taillandier, Arnaud Grignard and Tri Huu Nguyen
* Tags: covid19,epidemiology,proxymix
******************************************************************/

@no_experiment
model Constants

global {
	
	string layer <- "layer";
	string walls <- "Walls";
	string windows <- "Windows";	
	string entrance <-"Entrance";
	string offices <- "Offices";
	string meeting_rooms <- "Meeting rooms";
	string library<-"Library";
	string lab<-"Labs";
	string sanitation<-"Sanitation";	
	string coffee <- "Coffee";
	string supermarket <-"Supermarket";	
	string furnitures <- "Furniture";
	string toilets <- "Toilets";
	string elevators <- "Elevators";
	string stairs <- "Stairs";
	string doors <- "Doors";
	string chairs <- "Chair";
	string rooms <- "Rooms";
	string entrances <- "Entrances";
	string classe <- "classe";
	string multi_act <- "multi-act";
	string going_home <- "going home";
	string eating_outside <-"eating outside";
	
	string moving_skill <- "moving skill";
	string pedestrian_skill <- "pedestrian skill";
	
	string SFM <- "SFM";
	string simple <- "simple";
}
