/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Constants

global {
	string susceptible <- "S";
	string exposed <- "E";
	string asymptomatic <- "A";
	string symptomatic_without_symptoms <- "Ua";
	string symptomatic_with_symptoms <- "Us";
	string recovered <- "R";
	string dead <- "D";
	
	string not_tested <- "Not tested";
	string tested_positive <- "Positive";
	string tested_negative <- "Negative";

	// Building types
	string t_home 		<- "home";
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
	string t_office 	<- "office";
	string t_admin 	<- "admin";
	string t_place_of_worship 	<- "place_of_worship";
	string t_university 	<- "university";
	string t_sport <- "sport";
	string t_hotel <- "hotel";
	list<string>
	building_types <- [t_school, t_industry, t_shop, t_market, t_supermarket, t_bookstore, t_cinema, t_gamecenter, t_karaoke, t_restaurant, t_coffeeshop, t_farm, t_playground, t_hospital, t_supplypoint, t_park, t_meeting, t_repairshop];
}