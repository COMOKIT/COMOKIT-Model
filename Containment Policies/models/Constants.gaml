/***
* Name: Corona
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model Constants

global {
	string susceptible<-"susceptible";
	string exposed<-"exposed";
	string asymptomatic<-"asymptomatic";
	string infected<-"infected";
	string recovered<-"recovered";
	string death<-"death";
	string schooling<-"schooling";
	string working<-"working";
	
	string staying_at_home<-"at_home";
	
	
	// Building types
	string shop <- "shop";
	string market <- "market";
	string supermarket <- "supermarket";
	string bookstore <- "bookstore";
	string cinema <- "cinema";
	string gamecenter <- "gamecenter";
	string karaoke <- "karaoke";
	string restaurant <- "restaurant";
	string coffeeshop <- "coffeeshop";
	string farm <- "farm";
	string playground <- "playground";
	string hospital <- "hospital";
	string supplypoint <- "supplypoint";
	string park <- "park";
	string meeting <- "meeting";
	string repairshop <- "repairshop";
	
}