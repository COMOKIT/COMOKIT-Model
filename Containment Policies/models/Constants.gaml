/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Constants

global {
	string susceptible <- "susceptible";
	string exposed <- "exposed";
	string asymptomatic <- "asymptomatic";
	string infected <- "infected";
	string recovered <- "recovered";
	string death <- "death";

	// Building types
	string t_school 		<- "school";
	string t_industry 		<- "industry";	
	string t_shop 			<- "shop";
	string t_market 		<- "market";
	string t_supermarket 	<- "supermarket";
	string t_bookstore 		<- "bookstore";
	string t_cinema 		<- "cinema";
	string t_gamecenter 	<- "gamecenter";
	string t_karaoke 		<- "karaoke";
	string t_restaurant 	<- "restaurant";
	string t_coffeeshop 	<- "coffeeshop";
	string t_farm 			<- "farm";
	string t_playground 	<- "playground";
	string t_hospital 		<- "hospital";
	string t_supplypoint 	<- "supplypoint";
	string t_park 			<- "park";
	string t_meeting 		<- "meeting";
	string t_repairshop 	<- "repairshop";
	list<string>
	building_types <- [t_school, t_industry, t_shop, t_market, t_supermarket, t_bookstore, t_cinema, t_gamecenter, t_karaoke, t_restaurant, t_coffeeshop, t_farm, t_playground, t_hospital, t_supplypoint, t_park, t_meeting, t_repairshop];
}