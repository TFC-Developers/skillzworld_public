skillsrank.sma for Dummies
==========================

I thought i write this file as an addition to the skillsrank plugin.
This text is basically the code and what happens when it runs.
Some sort of translation from code to human language :).


<< ----- >>
public plugin_init() {
	1 The plugin creates the cvars used for the difficulty setting and the coords for the goal and start models.
	2 It registers functions which checks if any of the models are touched.
	3 The user commands are created
	4 The admin commands are added
	5 It tries to connect to the database for the rank points and create a table.
	6 It tries to connect to the database for the maps and create a table.
	7 It spawns the goal model
	8 It spawns the start model
}
<< ----- >>
public client_disconnect(id) {
	This function cleans the stored info from a player who disconnected so his id is free to use for the next one
	who connects.
}
<< ----- >>
public plugin_end() {
	Just some resetting of cvars and closing of the database.
}
<< ----- >>
public adminnoclip(id,level,cid){
	Toggles noclip to admin who are adding coords.
}
<< ----- >>
public diffimenu(id) { 
	Admin menu to select the difficulty of the map
}
<< ----- >>
public diffimenuenter(id,key){ 
	Admin choices of the difficulty setting
}
<< ----- >>
public skillsaddend(id,level,cid){
	The function which is used to add the end model.
}
<< ----- >>
public skillsaddstart(id,level,cid){
	The function which is used to add the start model.
}
<< ----- >>
public skilladd(id,level,cid){
	Binds the keys F7 and F5 used by admin to add coords and toggle noclip
}
<< ----- >>
public deletefile(){
	Deletes current cfg file.
}
<< ----- >>
public setfile(){
	Writes the new cfg file
}
<< ----- >>
public deletemodels(){
	Resets the models after new coords and difficulty have been added
}
<< ----- >>
public plugin_cfg() {
	Read the info in sql.cfg.
}
<< ----- >>
public sql_init_db() {
	Init of the database and create the tables 'skillrank' and 'skillmaps'
}
<< ----- >>
public client_authorized(id) {
	This function keeps track of people who have finnished the map. If they reconnect they cant finnish again.
	Only one time/map period.
}
<< ----- >>
public mapdifficulty (id) { 
	The say command /difficulty which shows how hard the map is.
}
<< ----- >>
public spawnStartModel() {
	1 If its not a dedicated server shut down plugin
	2 If all cvars exist in the map config spawn the start model
}
<< ----- >>
public spawnGoalModel() {
	1 If all cvars exist in the map config spawn the goal model
	2 If the cvars dont exist show a message that the map has no rank info
}
<< ----- >>
public noRankInfo() {
	Show "This map has no rank info added"
}
<< ----- >>
public start_touch(start,id) {
	Check if someone is touching the start model and save the start time.
}
<< ----- >>
public goal_touch(goal,id) {
	Most important function :). Check if someone toched the goal
	1 If its the first time someone run save info to databases
	2 If someone has started the timer add speed run time to db.
	3 If a person speedruns a second time only show the time but dont save to db
}
<< ----- >>
public msgToNewPlayer (id) {
	Welcome message to a new player
}
<< ----- >>
public msgToReconnect (id) {
	Welcome message to a reconnecting player
}
<< ----- >>
public msgToToManyId (id) {
	If the amount of stored players is to high show a message to the connecting player
}
<< ----- >>
public sql_insert_ranks(id) {
	Insert the player info and points in the ranks table
	This table has one row for each player and the row is updated
}
<< ----- >>
public sql_insert_maps(id) {
	Insert the player info, map info and speed run time in the maps table
	This table has one row for each time a player finish a map.
}
<< ----- >>
public showTopFive (id) {
	The say command /top5 which shows the top 5 players in the cathegories:
		1 Ubers (an uber is someone who have finished maps at least <uberCount> times.
		  On our server at least 10 maps.) When these players have been picked from the db
		  the function picks the 5 players with highest average difficulty of finished maps.
		2 Show the 5 players who collected most points
		3 Show the 5 players who have finished maps most times.
}
<< ----- >>
public showMapStats(id) {
	The say command /mapstats which shows personal stats on the current map and speedrun records
}
<< ----- >>
public showStats(id) {
	Shows first and last time the player finished maps on the server.
	The say command /skillme which shows players personal stats in three cathegories:
		1 UBER FACTOR. If the player has finished at least <uberCount> maps his position is compared
		  to the others who finished same amount of maps. The uber factor is average difficulty of
		  finished maps.
		2 FINISHED MAPS. Shows how many maps the player have finished and which position he has compared
		  to others in this cathegory.
		3 RANK POINTS. Shows how many points the player have collected and which position he has compared
		  to others in this cathegory.
}
<< ----- >>
public resetTimer(id) {
	Resets the speed run timer
}

/Lt Llama 2006-03-05