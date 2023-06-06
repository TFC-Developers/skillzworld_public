/*
*  AMX Mod X script
*
*	TFC Skills Player Rank with Speed Run Timer
*
*	by Lt Llama
*
*
*	Thanks to:
*	- NL)Ramon(NL:  For adding various cool functions to the plugin.
*       - Slurpy [COF]: sql_init and sql_insert functions
*	- team06:	Pointing out "Your not even calling the function" :D
*	- Watch		Looking over the code and making trigger model
*	- Forgot who :(	The part which reads db results and append it to an motd (gotta find out)
*	- The code bank and all info and the community at www.amxmodx.org
*	- Concs r us (http://www.concs-r-us.com/)
* 	- Team Project (http://www.team-project.org)
*
*  WHAT IS THIS?
*  ====================
*	The TFC skills community has never had an ingame ranking system, like other mods
*	where you can count how many frags you got by using what. Skillsrank solves
*	this by using a difficulty setting for each map. This is added to a map cfg which
*	is read by this plugin, When a player finish a map with a difficulty setting he 
*	triggers a goal model and data is saved to two SQL tables.
*	
*	If the map config has coords for the start model it spawns it and you have a
*	speedrun timer.
*
*	Skillsrank is designed so you can only finish and collect points ONE time during
*	the current loaded map. This is to not get a skewed collection of points because
*	someone continuosly collects points on an easy map.
*
*  WHAT IS CALCULATED?
*  ===================
*	- How many maps you finished and compared to others
*	- Which class you finished with
*	- How many points you have collected and compared to others
*	- First and last time you finished a map on the server
*	- Your best speedrun on the current map
*	- The all time high speed run on the current map
*	- The average difficulty of finished map (UBER factor)
*	- The top 5 players in 3 cathegories 1. Ubers, 2. Finished maps, 3. Collected
*	  points.
*
*  WHAT IS AN UBER?
*  ================
*	UBER is someone who have finished at least the amount of maps defined by: 
*	#define uberCount 10. When someone finished in this case 10 maps the plugin
*	divides <sum of collected points>/<number of finished maps>. It then compares
*	these players average difficulty and sort it. The top 5 gets into the /top 5 list. 
*	This is to encourage playing harder maps. If you play easier maps your average
*	drops.
*
* 	CONTENT OF SQL TABLES
*	=====================
*		Table skillranks (1 row for each player)
*		================
*		- steam id
*		- nickname
*		- number of times finished the map
*		- total collected points
*		- average of all points collected
*		Table skillmaps (1 row each time someone finish a map)
*		================
*		- steam id
*		- nickname
*		- map name
*		- player class (all TFC classes)
*		-.date
*		- time
*		- difficulty
*		- speedrun time
*
* 	MAP CONFIGS
*	===========
*	Map configs goes in addons/amxmodx/configs/maps
* 	Map configs is added by admins with ADMIN_CFG access.
*	Use amx_skillsmenu to add or manipulate current map config data.
*
*  THIS PLUGIN NEEDS AN SQL DATABASE TO WORK
*  =========================================
*	If you don't have SQL forget this. If you have it then see to that you have set
*	amx_sql_host, amx_sql_user, amx_sql_pass and amx_sql_db which are set in
*	$moddir/addons/amxx/configs/sql.cfg
*
*  INSTALLATION
*  ============
*	_ Create the folder addons/amxmodx/configs/maps and put all cfg files there
*	_ Put the concmaporb.mdl in tfc/models
*	_ Put the clocktag.spr in tfc/sprites
*	_ Put the afktag.spr in tfc/sprites
*
*  SETTINGS YOU MAY CHANGE
*  =======================
*  	Change to whatever you like under "// Customizable globals" below and recompile.
*
*  FUTURE PLANS FOR THIS PLUGIN
*  ============================
*	- Leet custom stuff attached to top5 players on 4 cathegories: Ubers, High rankers,
*	  most finished maps and speed runners (on current map)
*	- Allow players to keep speed running the current map and update db. Now only the first
*	  run i saved.
*	- Ability to say YES or NO to if you want the ranks to be saved on the current map.
*	  If NO you can speed run but it wont be saved.
*
*  USER COMMANDS
*  =============
*  	- say '/difficulty' to show difficulty (number between 1-100)
*  	- say '/top5' to show top 5 players in 3 cathegories (finished times, total points, average difficulty)
*  	- say '/mapstats' to show your stats on the current map.
*  	- say '/skillme' to see your overall stats.
*  	- say '/pause' pause speedrunning
*  	- say '/unpause' unpause speedrunning
*  	- 'amx_stoptimer' = Client command to stop speed run timer
*  	- 'amx_skillsmenu' = Admin tool to add coords and difficulty
*
*  VERSIONS
*  ========
*  1.4.4  	- Yes another crash fix with 1.75. Still crashed when using /top5. Fixed!
*  1.4.3  	- Fixed a crash problem when used with amxmodx 1.75.
*  1.4.2  	- Added pcvar, fixed timer not synchronized between on-screen timer
*		  and timer for touchings goal and end.
*  1.4.1  	- Added amx_skillsmenu and on screen timer. By NL)Ramon(NL
*  1.3.0  	- Added ingame coord and difficulty adder. By NL)Ramon(NL
*  1.2.3  	- Added a check and reward if someone broke the speed run record
*  1.2.2  	- Changed trigger models to one made by Watch and added skin changing in plugin
*		- Change welcome message so connecting player sees speed run records
*		- Added amx_stoptimer (2006-02-15)
*  1.2.1  	- Changed from two db connections to one (2006-02-14)
*  1.2.0  	- Added support for speedrun timing (2006-02-12)
*  1.1.0  	- Added /skillme
*  1.0.0  	- First working version (2006-02-05)
*/


#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <dbi>


// Customizable globals
#define RECORD_SOUND "Trumpet1.wav" 		// The sound played when the all time speedrun record is broken
#define FINISH_SOUND "misc/party1.wav" 		// The sound played when map is finished
#define START_MODEL "models/concmaporb.mdl" 	// The model used as trigger for the timer
#define GOAL_MODEL "models/concmaporb.mdl" 	// The model used to trigger when map is finished
#define	CLOCK_SPRITE "sprites/clocktag.spr"	// Sprite showing a player is speedrunning
#define uberCount 10 				// How many times you have to finish maps until average difficulty starts to count (so noone can come and finish 1 map and become an uber)
#define maxUserid 64 				// Set a max of id's in the array (max amount of players who can finish during map period)
#define maxPlayersInDB 400 			// When you have more than 400 unique visitors in your maps table.you need to increase this or delete posts in the 
// db. But be aware of stack error. You see how many players there are in the db by saying
// /skillme.
#define maxFinishedMaps 164			// This is used when selecting all lines in the maps table which
// match the current map loaded and a certain player. Maybe noone
// will finish same map 64 times or more, but in case increse.
#define keysTimerMenu (1<<0)|(1<<1) 		// Shown when a speedrunner stops the clock

// Non Customizable globals
#define PLUGIN "skillsrank" 
#define VERSION "1.4.4"
#define AUTHOR "Lt Llama" 

// Debug messages
new debugSkills

// The entity names for the goal and the start
#define GOAL_NAME "goal"
#define START_NAME "start"

new finishContainer[maxUserid][33]
new bool:hasTimer[33]
new bool:hasFinished[33]
new curId
new totalFinnish
new bestFinishedTotal
new bestRankTotal
new playersUberPosition
new rankIncr1
new rankIncr2
new float:topFinish
new float:topRank
new startTime[33]
new stopTime[33]
new models[2]
new clockmodel
new menunumber = 1
new allowteams[30]
new path[63]
new bool:dontspam[33]

// Database globals
new Sql:dbcSkills
new Result:resultRanks
new Result:resultMaps

// cvars
new y_goal
new x_goal
new z_goal
new y_start
new x_start
new z_start
new sv_diff
new sv_gteam
new amx_stimer

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR) 
	sv_diff = register_cvar("sv_difficulty","0") 
	sv_gteam = register_cvar("sv_goalteams","bryg")
	amx_stimer = register_cvar("amx_skilltimer","1")
	x_goal = register_cvar("x_goal","0") 
	y_goal = register_cvar("y_goal","0") 
	z_goal = register_cvar("z_goal","0") 
	x_start = register_cvar("x_start","0") 
	y_start = register_cvar("y_start","0") 
	z_start = register_cvar("z_start","0") 
	register_touch(GOAL_NAME,"player", "goal_touch")
	register_touch(START_NAME,"player", "start_touch")
	register_clcmd("say /difficulty","mapdifficulty",0,"- shows the difficulty of the map") 
	register_clcmd("say /skillme","showStats",0,"- shows the rank for the current player") 
	register_clcmd("say /mapstats","showMapStats",0,"- shows the rank for the current player") 
	register_clcmd("say /top5","showTopFive",0,"- shows the stats for the top 5 players") 
	register_concmd("amx_stoptimer","showTimerMenu",0,"- Stops the speed run timer")
	register_concmd("amx_skillsmenu","adminmenu", ADMIN_CFG,"")
	register_menucmd(register_menuid("timerMenu"), keysTimerMenu, "resetTimer")
	register_menucmd(register_menuid("diffmenu"),((1<<0)|(1<<1)|(1<<2)|(1<<4)|(1<<5)|(1<<6)|(1<<9)), "diffimenuenter") 
	register_menucmd(register_menuid("teammenu"),((1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<8)|(1<<9)), "blockteammenuenter") 
	register_menucmd(register_menuid("adminmenu"),((1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<9)), "adminmenuenter") 
	register_menucmd(register_menuid("skillsaddmenu"),((1<<0)|(1<<1)|(1<<4)|(1<<9)), "skillmenuenter")  
	register_menucmd(register_menuid("modelmenu"),((1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<8)|(1<<9)), "modelmenuenter")  
	models[0] = -10
	models[1] = -10
	
	// Debug messages
	// Set this to 1 in plugin_init to get debug messages in the log files
	debugSkills = 0
	
	// Connect to dabatase and init tables
	set_task(7.0, "sql_init_db")
	
	// If everything is ok with the db try and spawn the start and goal model
	set_task(10.0, "spawnStartModel")
	set_task(14.0, "spawnGoalModel")
	return PLUGIN_CONTINUE
}

// Clear the tasks and cvars attached to id's
public client_disconnect(id) {
	new authid[32] ; get_user_authid(id,authid,31)
	if (task_exists(id)) remove_task(id)
	hasTimer[id] = false
	hasFinished[id] = false
}

// Reset the cvars before map change
public plugin_end() {
	set_pcvar_num(sv_diff,0)
	set_pcvar_num(x_goal,0)
	set_pcvar_num(y_goal,0)
	set_pcvar_num(z_goal,0)
	set_pcvar_num(x_start,0)
	set_pcvar_num(y_start,0)
	set_pcvar_num(z_start,0)
	dbi_close(Sql:dbcSkills)
}

// Precache resources
public plugin_precache() { 
	precache_model(GOAL_MODEL) 
	precache_model(START_MODEL) 
	precache_sound(FINISH_SOUND) 
	precache_sound(RECORD_SOUND) 
	clockmodel = precache_model(CLOCK_SPRITE)
} 

// Exec sql.cfg
public plugin_cfg()
	{
	new folderName[32] ; get_configsdir(folderName, 31)
	server_cmd("exec %s/sql.cfg", folderName)
}

// Connect to the database and create tables if they dont exist
public sql_init_db() {
	// Connect to db
	new host[64], username[32], password[32], dbname[32], error[32]
	get_cvar_string("amx_sql_host",host,64)
	get_cvar_string("amx_sql_user",username,32)
	get_cvar_string("amx_sql_pass",password,32)
	get_cvar_string("amx_sql_db",dbname,32)
	
	// Create table skillrank if it dont exist
	dbcSkills = dbi_connect(host,username,password,dbname,error,32)
	if (dbcSkills == SQL_FAILED) {
		log_amx("[AMXX: skillrank] SQL Connection Failed to table skillrank")
		return PLUGIN_HANDLED
		} else {
		dbi_query(dbcSkills,"CREATE TABLE IF NOT EXISTS `skillrank` ( `steamId` VARCHAR(32) NOT NULL,`nickNames` VARCHAR(32) NOT NULL, `nFinnished` INT NOT NULL, `rankTotal` INT NOT NULL, `primaryRank` INT NOT NULL, PRIMARY KEY(`steamId`))")
	}
	dbi_free_result(resultRanks)
	
	// Create table skillmaps if it dont exist
	dbcSkills = dbi_connect(host,username,password,dbname,error,32)
	if (dbcSkills == SQL_FAILED) {
		log_amx("[AMXX: skillrank] SQL Connection Failed to table skillmaps")
		return PLUGIN_HANDLED
		} else {
		dbi_query(dbcSkills,"CREATE TABLE IF NOT EXISTS `skillmaps` ( `id` int(11) NOT NULL auto_increment, `steamId` VARCHAR(32) NOT NULL,`nickNames` VARCHAR(32) NOT NULL, `mapName` VARCHAR(32) NOT NULL, `playerClass` INT NOT NULL, `curDate` VARCHAR(10) NOT NULL, `curTime` VARCHAR(8) NOT NULL, `difficulty` INT NOT NULL, `runTime` INT NOT NULL, PRIMARY KEY(`id`))")
	}
	dbi_free_result(resultMaps)
	return PLUGIN_CONTINUE
}

// Check if its the first time before a map change a player connects
// and if the player has already triggered the goal.
public client_authorized(id) {
	new authid[32] ; get_user_authid(id,authid,31)
	
	// Loop through the array of id's
	new reconnected = 0
	// Check if a player who finished is coming back
	for (new loopId = 1; loopId <= curId; loopId++) {
		if (equali(finishContainer[loopId],authid) == 1) {
			set_task(30.0, "msgToReconnect",id)
			reconnected = 1
			hasFinished[id] = true
			if (debugSkills) log_amx("[AMXX: skillrank DEBUG] Player returned auth = %s finishcontainer = %s id = %i  loopid = % i curid = %i",authid,finishContainer[loopId],id,loopId,curId)
		}
	}
	if (reconnected == 0)
		set_task(30.0, "msgToNewPlayer",id)
	return PLUGIN_CONTINUE
}

// Show the current maps difficulty if the client types /difficulty 
public mapdifficulty (id) { 
	new sv_difficulty = get_pcvar_num(sv_diff)
	if ( get_pcvar_num(sv_diff) > 0) { 
		client_print(id,print_chat, "Map difficulty = %i of 100",sv_difficulty )
		} else { 
		client_print(id,print_chat, "The current map has no difficulty setting") 
	} 
	return PLUGIN_CONTINUE 
} 

// Spawn the start model
public spawnStartModel() {
	// Shut down if its not a dedicated server
	if (!is_dedicated_server()) {
		log_amx("[AMXX: skillrank] Connect without being a dedicated server")
		server_print("[AMXX: SKILLSRANK]: The skillsrank is turned off. Not a dedicated server!")
		return PLUGIN_HANDLED
	}
	// Check if all the cvars for difficulty setting and coords for start and
	// end model exists.
	if ( get_pcvar_num(sv_diff) > 0 && get_pcvar_num(x_goal) != 0 && get_pcvar_num(y_goal) != 0 && get_pcvar_num(z_goal) != 0 && get_pcvar_num(x_start) != 0 && get_pcvar_num(y_start) != 0 && get_pcvar_num(z_start) != 0) {
		// Create the the start entity and spawn it
		new start = create_entity("info_target")
		new Float:origin[3]
		entity_set_string(start, EV_SZ_classname, START_NAME)
		entity_set_int(start, EV_INT_solid, SOLID_TRIGGER)
		entity_set_int(start, EV_INT_skin, 2)
		entity_set_int(start, EV_INT_sequence, 0)
		entity_set_float(start,EV_FL_framerate,0.5)
		origin[0] = get_pcvar_float(x_start) 
		origin[1] = get_pcvar_float(y_start) 
		origin[2] = get_pcvar_float(z_start)
		entity_set_vector(start, EV_VEC_origin, origin)
		entity_set_model(start, START_MODEL)
		models[0] = start
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

// Spawn the goal model 
public spawnGoalModel() {
	// Check if the map cfg cvars exist, else print a message saying rank info is
	// missing.
	if ( get_pcvar_num(sv_diff) > 0) {
		if ( get_pcvar_num(x_goal) != 0 && get_pcvar_num(y_goal) != 0 && get_pcvar_num(z_goal) != 0) {
			// Create the the goal entity and spawn it
			new goal = create_entity("info_target") 
			new Float:origin[3]
			entity_set_string(goal, EV_SZ_classname, GOAL_NAME) 
			entity_set_int(goal, EV_INT_solid, SOLID_TRIGGER)
			entity_set_int(goal, EV_INT_skin, 1)
			entity_set_int(goal, EV_INT_sequence, 0)
			entity_set_float(goal,EV_FL_framerate,0.5)
			origin[0] = get_pcvar_float(x_goal) 
			origin[1] = get_pcvar_float(y_goal) 
			origin[2] = get_pcvar_float(z_goal)
			entity_set_vector(goal, EV_VEC_origin, origin)
			entity_set_model(goal, GOAL_MODEL)
			models[1] = goal
			} else {
			set_task(30.0, "noRankInfo")
			return PLUGIN_HANDLED
		}
		} else {
		set_task(30.0, "noRankInfo")
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}  

// Show a hud message if there is no cfg or wrong format in it
public noRankInfo() {
	set_hudmessage( 200, 100, 0, -1.0, 0.35, 0, 6.0, 12.0, 0.1, 0.2, 4 )
	show_hudmessage(0,"This map has no rank info added.")
}

// Events triggered when start model is touched
public start_touch(start,id) {
	if(dontspam[id] == true) return PLUGIN_HANDLED
	new name[32] ; get_user_name(id,name,31)
	
	// If someone touch the timer check if he has the timer running.
	// If not set the time and save his/hers start timer.
	new allowteam[5]
	get_pcvar_string(sv_gteam,allowteam,4)
	new team = get_user_team(id)
	if(team == 1 && containi(allowteam,"b") == -1)
		{ 
		shownot(id) 
	}
	else if(team == 2 && containi(allowteam,"r") == -1)
		{
		shownot(id) 
	}
	else if(team == 3 && containi(allowteam,"y") == -1)
		{ 
		shownot(id) 
	}
	else if(team == 4 && containi(allowteam,"g") == -1)
		{ 
		shownot(id) 
	}
	else
		{
		if(!hasTimer[id]) {
			set_hudmessage( 200, 100, 0, -1.0, 0.35, 0, 6.0, 12.0, 0.1, 0.2, 4 )
			show_hudmessage(id,"You have started the speedrun timer %s^nRun for the ball at end^nGO GO GO !!!^n^n(type amx_stoptimer in console to start over)^n^n(Only first run is saved in db)",name)
			client_cmd(id,"spk ^"one two three go^"")
			hasTimer[id] = true
			startTime[id] = get_systime()
			starttimer(id)
			showtimer(id)
		}
	}
	return PLUGIN_CONTINUE
}

// Events triggered when goal model is touched
public goal_touch(goal,id) {
	if(dontspam[id] == true) return PLUGIN_HANDLED
	new allowteam[5]
	get_pcvar_string(sv_gteam,allowteam,4)
	new team = get_user_team(id)
	if(team == 1 && containi(allowteam,"b") == -1)
		{ 
		shownot(id) 
	}
	else if(team == 2 && containi(allowteam,"r") == -1)
		{ 
		shownot(id) 
	}
	else if(team == 3 && containi(allowteam,"y") == -1)
		{ 
		shownot(id) 
	}
	else if(team == 4 && containi(allowteam,"g") == -1)
		{ 
		shownot(id) 
	}
	else
		{
		// set up vars for goal_touch function
		new authid[32] ; get_user_authid(id,authid,31)
		
		// Loop through the array of people who previously finished the map
		for (new loopFinnished = 0; loopFinnished < maxUserid ; loopFinnished++) {
			if (contain(finishContainer[loopFinnished],authid) != -1) {
				new name[32] ; get_user_name(id,name,31)
				// Check if the player has touched the timer
				if(hasTimer[id]) {
					new mapname[64] ; get_mapname(mapname,63)
					stopTime[id] = get_systime()
					new finishTime = stopTime[id] - startTime[id]
					new nHours = (finishTime / 3600) % 24 
					new nMinutes = (finishTime / 60) % 60 
					new nSeconds = finishTime % 60  
					set_hudmessage( 200, 100, 0, -1.0, 0.35, 0, 6.0, 12.0, 0.1, 0.2, 4 )
					show_hudmessage(0,"%s^n^nfinished %s in^n%i hours, %i minutes, %i seconds.^nOnly first run is saved in db ;)",name,mapname,nHours,nMinutes,nSeconds)
					client_print(id,print_chat, "Sorry %s. No more points but your time was %i hours, %i minutes, %i seconds.",name,nHours,nMinutes,nSeconds)
					show_menu(id, keysTimerMenu, "Want to be teleported back to start?^n^n1: Yes^n2: No^n^n", -1, "timerMenu") // Display menu 
					hasTimer[id] = false
				}
			}
		}
		// Save the steam id's of those who finished and give them a treat :)
		if (!hasFinished[id]) {
			if (curId == maxUserid) {
				new name[32] ; get_user_name(id,name,31)
				client_print(id,print_chat, "Sorry %s! Your ranks and time cant be saved. There are to many saved ranks atm",name)
				hasFinished[id] = true
				} else {
				new sv_difficulty = get_pcvar_num(sv_diff)
				new name[32] ; get_user_name(id,name,31)
				new mapname[64] ; get_mapname(mapname,63)
				client_print(id,print_chat, "Good Job %s. You have finished %s and gained %i rank points.",name,mapname,sv_difficulty)
				hasFinished[id] = true
				++curId
				finishContainer[curId] = authid
				set_hudmessage( 200, 100, 0, -1.0, 0.35, 0, 6.0, 12.0, 0.1, 0.2, 4 )
				// Check if the player has touched the timer
				// OneEyed showed the way of get_systime :)
				if(hasTimer[id]) {
					stopTime[id] = get_systime()
					new finishTime = stopTime[id] - startTime[id]
					new nHours = (finishTime / 3600) % 24
					new nMinutes = (finishTime / 60) % 60
					new nSeconds = finishTime % 60
					// Check if the player broke the all time speed run record
					// Check if anyone broke the speed run record or if it is the first time.
					resultMaps = dbi_query(dbcSkills,"SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime DESC",mapname,0)
					if (resultMaps <= RESULT_FAILED ) {
						log_amx("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.")
						dbi_free_result(resultMaps)
						return PLUGIN_HANDLED
						} else if (resultMaps == RESULT_NONE ) {
						client_cmd(0,"play %s",RECORD_SOUND)
						show_hudmessage(0,"%s^n^nBROKE THE SPEED RUN RECORD^n^n^nfor %s^nin^n%i hours, %i minutes, %i seconds^nand gained^n%i points^n^nsay /top5 for ranks^nsay /mapstats for personal map stats^nsay /skillme for all your stats",name,mapname,nHours,nMinutes,nSeconds,sv_difficulty)
						dbi_free_result(resultMaps)
						} else {
						new float:allTimeRecord
						while (resultMaps && dbi_nextrow(resultMaps) > 0) {
							dbi_result(resultMaps, "runTime", allTimeRecord)
							if (finishTime > floatround(Float:allTimeRecord))
								break
						}
						if (finishTime < floatround(Float:allTimeRecord)) {
							client_cmd(0,"play %s",RECORD_SOUND)
							show_hudmessage(0,"%s^n^nBROKE THE SPEED RUN RECORD^n^n^nfor %s^nin^n%i hours, %i minutes, %i seconds^nand gained^n%i points^n^nsay /top5 for ranks^nsay /mapstats for personal map stats^nsay /skillme for all your stats",name,mapname,nHours,nMinutes,nSeconds,sv_difficulty)
							} else {
							show_hudmessage(0,"%s^n^nfinished %s in^n%i hours, %i minutes, %i seconds^nand gained^n%i points^n^nsay /top5 for ranks^nsay /mapstats for personal map stats^nsay /skillme for all your stats",name,mapname,nHours,nMinutes,nSeconds,sv_difficulty)
							client_cmd(0,"spk %s",FINISH_SOUND)
						}
						dbi_free_result(resultMaps)
					}
					show_menu(id, keysTimerMenu, "Want to be teleported back to start?^n^n1: Yes^n2: No^n^n", -1, "timerMenu") // Display menu
					sql_insert_ranks(id)
					sql_insert_maps(id,finishTime)
					hasTimer[id] = false
					} else {
					client_cmd(0,"spk %s",FINISH_SOUND)
					show_hudmessage(0,"%s^n^nfinished %s and gained %i points^n^nsay /top5 for ranks^nsay /mapstats for personal map stats^nsay /skillme for all your stats",name,mapname,sv_difficulty)
					sql_insert_ranks(id)
					new finishTime = 0
					sql_insert_maps(id,finishTime)
					if (debugSkills) log_amx("[AMXX: skillrank DEBUG] Finished without touching timer Nickname = %s finishtime = %i sv_difficulty = %i",name,finishTime,sv_difficulty)
				}
				++totalFinnish
			}
		}
	}
	return PLUGIN_CONTINUE
}

public msgToNewPlayer (id) {
	new name[32] ; get_user_name(id,name,31)
	new sv_difficulty = get_pcvar_num(sv_diff)
	new mapname[64] ; get_mapname(mapname,63)
	if ( get_pcvar_num(sv_diff) > 0) { 
		if ( get_pcvar_num(x_goal) != 0 && get_pcvar_num(y_goal) != 0 && get_pcvar_num(z_goal) != 0) {
			new hostname[64] ; get_cvar_string("hostname",hostname,63)
			// Query for alltime speedrun record on current map
			resultMaps = dbi_query(dbcSkills,"SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",mapname,0)
			if (resultMaps <= RESULT_FAILED ) {
				log_amx("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.")
				dbi_free_result(resultMaps)
				return PLUGIN_HANDLED
				} else if (resultMaps == RESULT_NONE ) {
				set_hudmessage( 200, 100, 0, -1.0, 35.0, 0, 6.0, 20.0, 0.3, 0.3, 4 )
				show_hudmessage(id,"Welcome to %s %s.^nRank points if you finish = %i.^n^nSpeedrun record: No record set yet^n^nCOMMANDS: Say /top5 /skillme /mapstats or /difficulty",hostname,name,sv_difficulty,sv_difficulty)
				} else {
				new float:allTimeRecord, recordHolder[32], recordDate[32]
				dbi_nextrow(resultMaps)
				dbi_result(resultMaps, "runTime", allTimeRecord)
				dbi_result(resultMaps, "nickNames", recordHolder,31)
				dbi_result(resultMaps, "curDate", recordDate,31)
				new finishTime = allTimeRecord
				new nHours = (floatround(Float:finishTime) / 3600) % 24
				new nMinutes = (floatround(Float:finishTime) / 60) % 60
				new nSeconds = floatround(Float:finishTime) % 60
				set_hudmessage( 200, 100, 0, -1.0, 35.0, 0, 6.0, 20.0, 0.3, 0.3, 4 )
				show_hudmessage(id,"Welcome to %s %s.^nRank points if you finish = %i.^n^nSpeedrun record on %s^nSet by %s %s:^n%i hours, %i minutes, %i seconds^n^nCOMMANDS: Say /top5, /skillme /mapstats or /difficulty",hostname,name,sv_difficulty,mapname,recordHolder,recordDate,nHours,nMinutes,nSeconds)
			}
			dbi_free_result(resultMaps)
		}
	}
	return PLUGIN_CONTINUE
}

public msgToReconnect (id) {
	new name[32] ; get_user_name(id,name,31)
	if ( get_pcvar_num(sv_diff) > 0) { 
		if ( get_pcvar_num(x_goal) != 0 && get_pcvar_num(y_goal) != 0 && get_pcvar_num(z_goal) != 0) {
			client_print(id,print_chat, "Welcome back %s! Wait to map change before getting new points. You can still speed run.",name)
		}
	}
}

public msgToToManyId (id) {
	new name[32] ; get_user_name(id,name,31)
	new sv_difficulty = get_pcvar_num(sv_diff)
	if ( get_pcvar_num(sv_diff) > 0) { 
		if ( get_pcvar_num(x_goal) != 0 && get_pcvar_num(y_goal) != 0 && get_pcvar_num(z_goal) != 0) {
			new hostname[64]
			get_cvar_string("hostname",hostname,63)
			client_print(id,print_chat, "Welcome to %s %s. Currently your ranks can't be saved. Map difficulty is %i of 100.",hostname,name,sv_difficulty)
		}
	}
}

// Insert into table skillrank
public sql_insert_ranks(id) {
	if (dbcSkills == SQL_FAILED) return PLUGIN_CONTINUE
	new sv_difficulty = get_pcvar_num(sv_diff)
	new authid[32] ; get_user_authid(id,authid,31)
	new name[32] ; get_user_name(id,name,31)
	//Update user info when a map is finished
	resultRanks = dbi_query(dbcSkills,"SELECT * FROM skillrank where steamId ='%s'",authid)
	if (resultRanks <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt do the search in the database")
		return 0
		} else if (resultRanks == RESULT_NONE ) {
		resultRanks = dbi_query(dbcSkills,"INSERT INTO skillrank (steamId, nickNames, nFinnished, rankTotal, primaryRank) values ('%s','%s',%i,%i,%i)",authid,name,1,sv_difficulty,sv_difficulty)
		dbi_free_result(resultRanks)
		}else{
		resultRanks = dbi_query(dbcSkills,"UPDATE skillrank SET nickNames='%s',nFinnished=nFinnished+1,rankTotal=rankTotal+%i,primaryRank=((rankTotal+%i)/(nFinnished+1)) WHERE steamId='%s'",name,sv_difficulty,sv_difficulty,authid)
		dbi_free_result(resultRanks)
	}
	return PLUGIN_CONTINUE
}

// Insert into table skillmaps
// The 'runTime' column is a place holder for speed run times in future version. 0 is added until this is done.
public sql_insert_maps(id,finishTime) {
	if (dbcSkills == SQL_FAILED) return PLUGIN_CONTINUE
	new sv_difficulty = get_pcvar_num(sv_diff)
	new currentTime[9] ; get_time("%H:%M:%S",currentTime,10) 
	new currentDate[32] ; get_time("%Y/%m/%d",currentDate,10)
	new authid[32] ; get_user_authid(id,authid,31)
	new name[32] ; get_user_name(id,name,31)
	new mapname[64] ; get_mapname(mapname,63)
	new class = entity_get_int(id, EV_INT_playerclass)
	if (class == 1)
		class = 0
	//Insert finished maps and who finished them in table skillmaps
	resultMaps = dbi_query(dbcSkills,"INSERT INTO skillmaps (steamId, nickNames, mapName, playerClass, curDate,curTime,difficulty, runTime) values ('%s','%s','%s',%i,'%s','%s',%i,%i)",authid,name,mapname,class,currentDate,currentTime,sv_difficulty,finishTime)
	if (resultMaps <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt insert to table skillmaps")
		dbi_free_result(resultMaps)
		return PLUGIN_HANDLED
	}
	dbi_free_result(resultMaps)
	if (debugSkills) log_amx("[AMXX: skillrank DEBUG] Inserted into maps table: '%s','%s','%s',%i,'%s','%s',%i,%i",authid,name,mapname,class,currentDate,currentTime,sv_difficulty,finishTime)
	return PLUGIN_CONTINUE
}

// Pick the top five players of number of finished maps, total ranks and best average rank
// and show an MOTD to the player.
public showTopFive (id) {
	new qryNickname[32], qryPrimaryRank[32], qryFinnished[32], qryRankTotal[32], motd[2048],ln = 0
	new title[32], hostname[64]
	get_cvar_string("hostname",hostname,63)
	format(title,31,"TOP 5 LIST @ %s",hostname)
	// Search for top 5 players with best average difficulty
	resultRanks = dbi_query(dbcSkills,"SELECT nickNames, primaryRank,nFinnished FROM `skillrank` WHERE nFinnished>=%i ORDER BY primaryRank DESC LIMIT 5",uberCount)
	if (resultRanks <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt search for nickNames, primaryRank,nFinnished in table skillranks. Plugin cancelled.")
		return PLUGIN_HANDLED
	} else if (resultRanks == RESULT_NONE ) {
		client_print(id,print_chat, "Noone have finished %i maps yet. Do it an be the first UBER :)",uberCount)
		ln += format(motd[ln], 2047-ln,"<<<================= [ UBERS ] =================>>>^n")
		ln += format(motd[ln], 2047-ln,"Sorry we have no ubers yet. Finish more maps^n^n")
	} else {
		new incrUberCount = 0
		new incrPosition = 0
		//Loop through the result set
		ln += format(motd[ln], 2047-ln,"<<<================= [ UBERS ] =================>>>^n")
		while (resultRanks && dbi_nextrow(resultRanks) > 0) {
			dbi_result(resultRanks, "nFinnished", qryFinnished[incrUberCount],31)
			if (qryFinnished[incrUberCount] >= uberCount) {
				dbi_result(resultRanks, "nickNames", qryNickname, 31)
				dbi_result(resultRanks, "primaryRank", qryPrimaryRank, 31)
				ln += format(motd[ln], 2047-ln,"%i. %s = %s^n",++incrPosition,qryNickname, qryPrimaryRank)
			}

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nFinnished", qryFinnished) 
			if (qryFinnished[incrUberCount] >= uberCount) {
				dbi_result(resultRanks, "nickNames", qryNickname, 31) 
				dbi_result(resultRanks, "primaryRank", qryPrimaryRank, 31)
				ln += format(motd[ln], 2047-ln,"%i. %s = %s^n",++incrPosition,qryNickname, qryPrimaryRank)
			}

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nFinnished", qryFinnished) 
			if (qryFinnished[incrUberCount] >= uberCount) {
				dbi_result(resultRanks, "nickNames", qryNickname, 31) 
				dbi_result(resultRanks, "primaryRank", qryPrimaryRank, 31)
				ln += format(motd[ln], 2047-ln,"%i. %s = %s^n",++incrPosition,qryNickname, qryPrimaryRank)
			}

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nFinnished", qryFinnished) 
			if (qryFinnished[incrUberCount] >= uberCount) {
				dbi_result(resultRanks, "nickNames", qryNickname, 31) 
				dbi_result(resultRanks, "primaryRank", qryPrimaryRank, 31)
				ln += format(motd[ln], 2047-ln,"%i. %s = %s^n",++incrPosition,qryNickname, qryPrimaryRank)
			}

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nFinnished", qryFinnished) 
			if (qryFinnished[incrUberCount] >= uberCount) {
				dbi_result(resultRanks, "nickNames", qryNickname, 31) 
				dbi_result(resultRanks, "primaryRank", qryPrimaryRank, 31)
				ln += format(motd[ln], 2047-ln,"%i. %s = %s^n",++incrPosition,qryNickname, qryPrimaryRank)
			}
		}
		dbi_free_result(resultRanks)
	}
	resultRanks = dbi_query(dbcSkills,"SELECT nickNames, primaryRank FROM `skillrank` ORDER BY `primaryRank` DESC LIMIT 5")
	if (resultRanks <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt search for nickNames, primaryRank in table skillranks. Plugin cancelled.")
		return PLUGIN_HANDLED
	} else if (resultRanks == RESULT_NONE ) {
		client_print(id,print_chat, "Nothing added to the database yet. Finish 1 time and you will be first :)")
	} else {
		// Search for top 5 players with highest ranks
		resultRanks = dbi_query(dbcSkills,"SELECT nickNames, rankTotal FROM `skillrank` ORDER BY `rankTotal` DESC LIMIT 5")
		if (resultRanks <= RESULT_FAILED ) {
			log_amx("[AMXX: skillrank] Couldnt search for rankTotal in table skillranks. Plugin cancelled.")
			return PLUGIN_HANDLED
		}
		//Loop through the result set
		ln += format(motd[ln], 2047-ln,"^n<<<=============== [ HIGH RANKERS ] =============>>>")
		while (resultRanks && dbi_nextrow(resultRanks) > 0) { 
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "rankTotal", qryRankTotal, 31)
			ln += format(motd[ln], 2047-ln,"^n1. %s = %s",qryNickname, qryRankTotal)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "rankTotal", qryRankTotal, 31)
			ln += format(motd[ln], 2047-ln,"^n2. %s = %s",qryNickname, qryRankTotal)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "rankTotal", qryRankTotal, 31)
			ln += format(motd[ln], 2047-ln,"^n3. %s = %s",qryNickname, qryRankTotal)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "rankTotal", qryRankTotal, 31)
			ln += format(motd[ln], 2047-ln,"^n4. %s = %s",qryNickname, qryRankTotal)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "rankTotal", qryRankTotal, 31)
			ln += format(motd[ln], 2047-ln,"^n5. %s = %s^n",qryNickname, qryRankTotal)
		}
		dbi_free_result(resultRanks)
		
		// Search for top 5 players who finished most times
		resultRanks = dbi_query(dbcSkills,"SELECT nickNames, nFinnished FROM `skillrank` ORDER BY `nFinnished` DESC LIMIT 5")
		if (resultRanks <= RESULT_FAILED ) {
			log_amx("[AMXX: skillrank] Couldnt search for nFinnished in table skillranks. Plugin cancelled.")
			return PLUGIN_HANDLED
		}
		//Loop through the result set
		new qryFinnished2[32]
		ln += format(motd[ln], 2047-ln,"^n<<<=========== [ MOST FINISHED MAPS ] ===========>>>")
		while (resultRanks && dbi_nextrow(resultRanks) > 0) { 
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "nFinnished", qryFinnished2, 31)
			ln += format(motd[ln], 2047-ln,"^n1. %s = %s",qryNickname, qryFinnished2)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "nFinnished", qryFinnished2, 31)
			ln += format(motd[ln], 2047-ln,"^n2. %s = %s",qryNickname, qryFinnished2)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "nFinnished", qryFinnished2, 31)
			ln += format(motd[ln], 2047-ln,"^n3. %s = %s",qryNickname, qryFinnished2)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "nFinnished", qryFinnished2, 31)
			ln += format(motd[ln], 2047-ln,"^n4. %s = %s",qryNickname, qryFinnished2)

			if (dbi_nextrow(resultRanks) <= 0)
			    continue
			dbi_result(resultRanks, "nickNames", qryNickname, 31) 
			dbi_result(resultRanks, "nFinnished", qryFinnished2, 31)
			ln += format(motd[ln], 2047-ln,"^n5. %s = %s",qryNickname, qryFinnished2)
		}
		dbi_free_result(resultRanks)
		show_motd(id, motd, title)
	}
	return PLUGIN_CONTINUE
}

public showMapStats(id) {
	new name[32] ; get_user_name(id,name,31)
	new mapname[64] ; get_mapname(mapname,63)
	new authid[32] ; get_user_authid(id,authid,31)
	new mapStatsTitle[32]
	new sv_difficulty = get_pcvar_num(sv_diff)
	format(mapStatsTitle,31,"Map stats: %s",name)
	new mapStatsMotd[2048],len=0, foundFirstDate=0, totalFinnished=0,rankSum=0
	new scoutSum=0, sniperSum=0,soldierSum=0,demomanSum=0,medicSum=0,hwguySum=0,pyroSum=0,spySum=0,engineerSum=0,civilianSum=0
	
	// Query for player info on this map and show him speedrun record
	new qryDate[maxFinishedMaps]
	resultMaps = dbi_query(dbcSkills,"SELECT curDate FROM skillmaps where steamId='%s' AND mapName='%s' ORDER BY curDate ASC",authid,mapname)
	len += format(mapStatsMotd[len], 2047-len,"Map: %s || ",mapname)
	if (resultMaps <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt search for authid in table skillmaps. Plugin cancelled.")
		return PLUGIN_HANDLED
		} else if (resultMaps == RESULT_NONE ) {
		if (sv_difficulty != 0) 
			len += format(mapStatsMotd[len], 2047-len,"Difficulty: %i^n^n",sv_difficulty)
		len += format(mapStatsMotd[len], 2047-len,"First time finished: NEVER^n")
		dbi_free_result(resultMaps)
		
		// Query for alltime speedrun record on current map
		resultMaps = dbi_query(dbcSkills,"SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",mapname,0)
		if (resultMaps <= RESULT_FAILED ) {
			log_amx("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.")
			return PLUGIN_HANDLED
			} else if (resultMaps == RESULT_NONE ) {
			len += format(mapStatsMotd[len], 2047-len,"^nSpeedrun record: No record set yet^n")
			} else {
			new float:allTimeRecord, recordHolder[32], recordDate[32]
			dbi_nextrow(resultMaps)
			dbi_result(resultMaps, "runTime", allTimeRecord)
			dbi_result(resultMaps, "nickNames", recordHolder,31)
			dbi_result(resultMaps, "curDate", recordDate,31)
			new finishTime = allTimeRecord
			new nHours = (floatround(Float:finishTime) / 3600) % 24
			new nMinutes = (floatround(Float:finishTime) / 60) % 60 
			new nSeconds = floatround(Float:finishTime) % 60
			len += format(mapStatsMotd[len], 2047-len,"^nSpeedrun record: Set by %s %s: %i hours, %i minutes, %i seconds^n",recordHolder,recordDate,nHours,nMinutes,nSeconds)
		}
		dbi_free_result(resultMaps)
		} else {
		while (resultMaps && dbi_nextrow(resultMaps) > 0) {
			if (foundFirstDate == 0) {
				dbi_result(resultMaps, "curDate", qryDate, maxFinishedMaps-1)
				len += format(mapStatsMotd[len], 2047-len,"Difficulty: %i^n^n",sv_difficulty)
				len += format(mapStatsMotd[len], 2047-len,"First time finished: %s^n",qryDate)
				foundFirstDate = 1
			}
			totalFinnished++
		}
		
		len += format(mapStatsMotd[len], 2047-len,"Finished number of times: %i^n",totalFinnished)
		rankSum = sv_difficulty * totalFinnished
		len += format(mapStatsMotd[len], 2047-len,"Total collected points on %s: %i^n",mapname,rankSum)
		dbi_free_result(resultMaps)
		
		// Query for personal speedrun record
		resultMaps = dbi_query(dbcSkills,"SELECT runTime FROM skillmaps where steamId='%s' AND mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",authid,mapname,0)
		if (resultMaps <= RESULT_FAILED ) {
			log_amx("[AMXX: skillrank] Couldnt search for personal speed run record in table skillmaps. Plugin cancelled.")
			return PLUGIN_HANDLED
			} else if (resultMaps == RESULT_NONE ) {
			len += format(mapStatsMotd[len], 2047-len,"Your best speedrun: You have done no speedrun on this map yet^n")
			} else {
			new float:personalRecord
			dbi_nextrow(resultMaps)
			dbi_result(resultMaps, "runTime", personalRecord)
			new finishTime = personalRecord
			new nHours = (floatround(Float:finishTime) / 3600) % 24
			new nMinutes = (floatround(Float:finishTime) / 60) % 60 
			new nSeconds = floatround(Float:finishTime) % 60
			len += format(mapStatsMotd[len], 2047-len,"Your best speedrun: %i hours, %i minutes, %i seconds^n",nHours,nMinutes,nSeconds)
		}
		dbi_free_result(resultMaps)
		
		// Query for alltime speedrun record on current map
		resultMaps = dbi_query(dbcSkills,"SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",mapname,0)
		if (resultMaps <= RESULT_FAILED ) {
			log_amx("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.")
			return PLUGIN_HANDLED
			} else if (resultMaps == RESULT_NONE ) {
			len += format(mapStatsMotd[len], 2047-len,"^nSpeedrun record: No record set yet^n")
			} else {
			new float:allTimeRecord, recordHolder[32], recordDate[32]
			dbi_nextrow(resultMaps)
			dbi_result(resultMaps, "runTime", allTimeRecord)
			dbi_result(resultMaps, "nickNames", recordHolder,31)
			dbi_result(resultMaps, "curDate", recordDate,31)
			new finishTime = allTimeRecord
			new nHours = (floatround(Float:finishTime) / 3600) % 24
			new nMinutes = (floatround(Float:finishTime) / 60) % 60 
			new nSeconds = floatround(Float:finishTime) % 60
			len += format(mapStatsMotd[len], 2047-len,"^nSpeedrun record: Set by %s %s: %i hours, %i minutes, %i seconds^n",recordHolder,recordDate,nHours,nMinutes,nSeconds)
		}
		dbi_free_result(resultMaps)
		
		// Query for number of times finished of each class
		len += format(mapStatsMotd[len], 2047-len,"^nFinished with class: ^n")
		resultMaps = dbi_query(dbcSkills,"SELECT playerClass FROM skillmaps where steamId='%s' AND mapName='%s' ORDER BY curDate ASC",authid,mapname)
		if (resultMaps <= RESULT_FAILED ) {
			log_amx("[AMXX: skillrank] Couldnt search for player class in table  skillmaps. Plugin cancelled.")
			return PLUGIN_HANDLED
			} else {
			new qryClass[maxFinishedMaps]
			new incrQryClass = 0
			while (resultMaps && dbi_nextrow(resultMaps) > 0) {
				dbi_result(resultMaps, "playerClass", qryClass[incrQryClass], maxFinishedMaps-1)
				if (qryClass[incrQryClass] == '0')
					++scoutSum
				else if (qryClass[incrQryClass] == '2')
					++sniperSum
				else if (qryClass[incrQryClass] == '3')
					++soldierSum
				else if (qryClass[incrQryClass] == '4')
					++demomanSum
				else if (qryClass[incrQryClass] == '5')
					++medicSum
				else if (qryClass[incrQryClass] == '6')
					++hwguySum
				else if (qryClass[incrQryClass] == '7')
					++pyroSum
				else if (qryClass[incrQryClass] == '8')
					++spySum
				else if (qryClass[incrQryClass] == '9')
					++engineerSum
				else
					++civilianSum
				++incrQryClass
			}
		}
		len += format(mapStatsMotd[len], 2047-len,"Scout: %i^n",scoutSum)
		len += format(mapStatsMotd[len], 2047-len,"Sniper: %i^n",sniperSum)
		len += format(mapStatsMotd[len], 2047-len,"Soldier: %i^n",soldierSum)
		len += format(mapStatsMotd[len], 2047-len,"Demoman: %i^n",demomanSum)
		len += format(mapStatsMotd[len], 2047-len,"Medic: %i^n",medicSum)
		len += format(mapStatsMotd[len], 2047-len,"Hwguy: %i^n",hwguySum)
		len += format(mapStatsMotd[len], 2047-len,"Pyro: %i^n",pyroSum)
		len += format(mapStatsMotd[len], 2047-len,"Spy: %i^n",spySum)
		len += format(mapStatsMotd[len], 2047-len,"Engineer: %i^n",engineerSum)
		len += format(mapStatsMotd[len], 2047-len,"Civilian: %i^n",civilianSum)
		dbi_free_result(resultMaps)
	}
	show_motd(id, mapStatsMotd, mapStatsTitle)
	return PLUGIN_CONTINUE
}

public showStats(id) {
	new name[32] ; get_user_name(id,name,31)
	new authid[32] ; get_user_authid(id,authid,31)
	new statsMotd[2048],len1=0, statsTitle[32]
	
	format(statsTitle,31,"Personal stats for %s",name)
	
	// Query for the first and last time the player finished a map
	resultMaps = dbi_query(dbcSkills,"SELECT curDate FROM `skillmaps` WHERE steamId='%s' ORDER BY curDate ASC",authid)
	new qryFirstDate[maxFinishedMaps]
	if (resultMaps <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt search for date. Plugin cancelled.")
		return PLUGIN_HANDLED
	} else if (resultMaps == RESULT_NONE ) {
		len1 += format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.^n",name)
		show_motd(id, statsMotd, statsTitle)
		dbi_free_result(resultMaps)
		return PLUGIN_CONTINUE
	} else {
		dbi_nextrow(resultMaps)
		dbi_result(resultMaps, "curDate", qryFirstDate, maxFinishedMaps-1)
		new nRows = dbi_num_rows(resultMaps)
		new incrRows = 1
		len1 += format(statsMotd[len1], 2047-len1,"First time you finished a map: %s^n",qryFirstDate)
		while (incrRows < nRows) {
		    dbi_nextrow(resultMaps)
		    ++incrRows
		}
		dbi_result(resultMaps, "curDate", qryFirstDate, maxFinishedMaps-1)
		len1 += format(statsMotd[len1], 2047-len1,"Last time you finished a map: %s^n^n^n",qryFirstDate)
		dbi_free_result(resultMaps)
	}
	
	// Query current players uber factor
	resultRanks = dbi_query(dbcSkills,"SELECT steamId,nFinnished FROM `skillrank` where nFinnished>=%i AND steamId ='%s'",uberCount,authid)
	if (resultRanks <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt search for rankTotal in table skillranks. Plugin cancelled.")
		return PLUGIN_HANDLED
		} else if (resultRanks == RESULT_NONE ) {
		len1 += format(statsMotd[len1], 2047-len1,"<<<=========== [ UBER FACTOR ] ===========>>>^n")
		len1 += format(statsMotd[len1], 2047-len1,"You have to finish at least %i maps to have a chance to be an uber.^n^n",uberCount)
		dbi_free_result(resultRanks)
		} else {
		new incrUberCount = 0, incrUberPerson = 0, qryUber[maxFinishedMaps],qryRankPrimaryRank[32]
		
		playersUberPosition = 0
		resultRanks = dbi_query(dbcSkills,"SELECT steamId, primaryRank,nFinnished FROM `skillrank` WHERE nFinnished>=%i ORDER BY primaryRank DESC",uberCount)
		while (resultRanks && dbi_nextrow(resultRanks) > 0) {
			dbi_result(resultRanks, "steamId", qryUber[incrUberCount],maxFinishedMaps-1)
			if (incrUberPerson == 0) {
				if (containi(qryUber[incrUberCount],authid) != -1) {
					incrUberPerson = 1
					dbi_result(resultRanks, "primaryRank", qryRankPrimaryRank, 31)
				}
				playersUberPosition++
				incrUberCount++
			}
		}
		new nUbers = dbi_num_rows(resultRanks)
		dbi_free_result(resultRanks)
		len1 += format(statsMotd[len1], 2047-len1,"<<<=========== [ UBER FACTOR ] ===========>>>^n")
		len1 += format(statsMotd[len1], 2047-len1,"Your average difficulty of finished maps = %s^n",qryRankPrimaryRank)
		len1 += format(statsMotd[len1], 2047-len1,"Your on place [%i] of [%i] ubers.^nHarder maps = more uber :)^n^n^n",playersUberPosition,nUbers)
	}
	
	// Query current players rank in number of finished maps
	resultRanks = dbi_query(dbcSkills,"SELECT steamId,nFinnished FROM `skillrank` ORDER BY nFinnished DESC")
	new qryRankFinnish1[maxPlayersInDB]
	if (resultRanks <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt do rank search for players rank in number of finished maps. Plugin cancelled.")
		return PLUGIN_HANDLED
		} else if (resultRanks == RESULT_NONE ) {
		len1 += format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.^n",name)
		show_motd(id, statsMotd, statsTitle)
		dbi_free_result(resultRanks)
		return PLUGIN_CONTINUE
		} else {
		new numFinishTotal=0, foundPlayerFinish=0
		bestFinishedTotal=0, rankIncr1=0
		while (resultRanks && dbi_nextrow(resultRanks) > 0) {
			if (numFinishTotal != 1) {
				dbi_result(resultRanks,"nFinnished",topFinish)
				numFinishTotal=1
			}
			dbi_result(resultRanks, "steamId", qryRankFinnish1[rankIncr1], maxPlayersInDB-1)
			if (foundPlayerFinish != 1) {
				if (containi(qryRankFinnish1[rankIncr1],authid) != -1)
					foundPlayerFinish = 1
				rankIncr1++
			}
		}
		bestFinishedTotal = dbi_num_rows(resultRanks)
		dbi_free_result(resultRanks)
	}
	
	// Query current players rank in points collected
	resultRanks = dbi_query(dbcSkills,"SELECT steamId,rankTotal FROM `skillrank` ORDER BY rankTotal DESC")
	new qryRankTotal1[maxPlayersInDB]
	if (resultRanks <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt do rank search for players rank in collected points. Plugin cancelled.")
		return PLUGIN_HANDLED
		} else if (resultRanks == RESULT_NONE ) {
		len1 += format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.^n",name)
		show_motd(id, statsMotd, statsTitle)
		dbi_free_result(resultRanks)
		return PLUGIN_CONTINUE
		} else {
		new foundPlayerRank=0, numRankTotal=0
		rankIncr2=0
		while (resultRanks && dbi_nextrow(resultRanks) > 0) {
			if (numRankTotal != 1) {
				dbi_result(resultRanks,"rankTotal",topRank)
				numRankTotal=1
			}
			dbi_result(resultRanks, "steamId", qryRankTotal1[rankIncr2], maxPlayersInDB-1)
			if (foundPlayerRank != 1) {
				if (containi(qryRankTotal1[rankIncr2],authid) != -1)
					foundPlayerRank = 1
				rankIncr2++
			}
		}
		bestRankTotal = dbi_num_rows(resultRanks)
		dbi_free_result(resultRanks)
	}
	
	
	// Query for the players number of times finished maps, total points and average difficulty of finished maps
	new qryRankFinnished[32], qryRankTotal[32]
	resultRanks = dbi_query(dbcSkills,"SELECT nFinnished,rankTotal,primaryRank FROM  `skillrank` WHERE steamId='%s'",authid)
	if (resultRanks <= RESULT_FAILED ) {
		log_amx("[AMXX: skillrank] Couldnt do the rank search. Plugin cancelled.")
		return PLUGIN_HANDLED
		} else if (resultRanks == RESULT_NONE ) {
		len1 += format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.^n",name)
		show_motd(id, statsMotd, statsTitle)
		dbi_free_result(resultRanks)
		return PLUGIN_CONTINUE
		} else {
		dbi_nextrow(resultRanks)
		dbi_result(resultRanks, "nFinnished", qryRankFinnished, 31)
		dbi_result(resultRanks, "rankTotal", qryRankTotal, 31)
		len1 += format(statsMotd[len1], 2047-len1,"<<<=========== [ FINISHED MAPS ] ===========>>>^n")
		len1 += format(statsMotd[len1], 2047-len1,"You have finished %s maps^n",qryRankFinnished)
		len1 += format(statsMotd[len1], 2047-len1,"Your on place [%i] of [%i]. (%i finished maps is highest)^n^n^n",rankIncr1,bestFinishedTotal,floatround(Float:topFinish))
		len1 += format(statsMotd[len1], 2047-len1,"<<<=========== [ RANK POINTS ] ===========>>>^n")
		len1 += format(statsMotd[len1], 2047-len1,"You have collected %s points^n",qryRankTotal)
		len1 += format(statsMotd[len1], 2047-len1,"Your on place [%i] of [%i]. (%i collected points is highest)^n^n",rankIncr2,bestRankTotal,floatround(Float:topRank))
		show_motd(id, statsMotd, statsTitle)
		dbi_free_result(resultRanks)
	}
	return PLUGIN_CONTINUE
}

// Menu when someone stops timer
public showTimerMenu(id) { 
	// Show the user a menu and ask if he wants to teleport back
	if (hasTimer[id]) {
		show_menu(id, keysTimerMenu, "Timer stopped! Teleport to start?^n^n1: Yes^n2: No^n^n", -1, "timerMenu") // Display menu
		dontspam[id] = true
		set_task(3.0,"canshow",id)
		} else {
		client_print(id,print_chat,"You cant use amx_stoptimer if you havent started timer silly ;)")
	}
} 

// Resets the timer and asks if the player wants to teleport back
public resetTimer(id,key) {
	switch (key) { 
		case 0: 
		{
			new origin[3]
			origin[0] = get_pcvar_num(x_start) - 40
			origin[1] = get_pcvar_num(y_start)
			origin[2] = get_pcvar_num(z_start) + 20
			set_user_origin(id,origin)
		}
	}
	client_print(id,print_chat, "Your timer has stopped. Touch the timer again to do another try.")
	hasTimer[id] = false
	return PLUGIN_CONTINUE
}

// Admin menu for adding and manipulating map configs
public skillsmenu(id){
	show_menu(id,((1<<0)|(1<<1)|(1<<4)|(1<<9)),"Pick a task^n1: Add start model^n2: Add end model^n5: Noclip me^n0: Done", -1, "skillsaddmenu") 
}

// called when menu choices have been done for adding and manipulating map configs
public skillmenuenter(id,key){ // 
	switch (key)
	{
		case 0: // key 1
		{
			new origin[3]
			get_user_origin(id,origin)
			set_pcvar_num(x_start,origin[0])
			set_pcvar_num(y_start,origin[1])
			set_pcvar_num(z_start,origin[2])
			client_print(id,print_chat,"Start added")
			skillsmenu(id)
		}
		case 1: // key 2
		{
			new origin[3]
			get_user_origin(id,origin)
			set_pcvar_num(x_goal,origin[0])
			set_pcvar_num(y_goal,origin[1])
			set_pcvar_num(z_goal,origin[2])
			client_print(id,print_chat,"End added")
			skillsmenu(id)
		}
		case 4:  // key 5
		{
			switch (get_user_noclip(id))
			{
				case 0: 
				{
					set_user_noclip(id,1)
					client_print(id,print_chat,"Noclip on")
				}
				case 1: 
				{
					set_user_noclip(id,0)
					client_print(id,print_chat,"Noclip off")
				}
			}
			skillsmenu(id)
		}
		case 9:  // key 0
		{
			diffimenu(id)
		}
	}
}

// Menu for adding or deletin start and goal models.
public modelmenu(id){ // modelmenu
	new menumsg[200] = "Pick a task^n1: "
	if(models[0] == -10) // if start model isnt alive
		{
		format(menumsg,199,"%sSpawn start model^n2: ",menumsg)
	}
	else
		{
		format(menumsg,199,"%sRemove start model^n2: ",menumsg)
	}
	if(models[1] == -10) // if end model isnt alive
		{
		format(menumsg,199,"%sSpawn goal model^n3: Move start model to my location^n4: Move goal model to my location^n9: Back^n^n0: Exit",menumsg)
	}
	else
		{
		format(menumsg,199,"%sRemove goal model^n3: Move start model to my location^n4: Move goal model to my location^n9: Back^n^n0: Exit",menumsg)
	}
	show_menu(id,((1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<8)|(1<<9)),menumsg, -1, "modelmenu") // showmenu
}

// Executed when choices done in the model menu
public modelmenuenter(id,key){
	switch (key)
	{
		case 0: // key 1
		{
			if(models[0] == -10)
				{
				spawnStartModel()
			}
			else
				{
				remove_entity(models[0])
				models[0] = -10
			}
			modelmenu(id)
		}
		case 1: // key 2
		{
			if(models[1] == -10)
				{
				spawnGoalModel()
			}
			else
				{
				remove_entity(models[1])
				models[1] = -10
			}
			modelmenu(id)
		}
		case 2: // key 2
		{
			new origin[3]
			get_user_origin(id,origin)
			set_pcvar_num(x_start,origin[0])
			set_pcvar_num(y_start,origin[1])
			set_pcvar_num(z_start,origin[2])
			if(models[0] != -10) 
				{
				remove_entity(models[0])
				spawnStartModel()
			}
			deletefile()
			modelmenu(id)
		}
		case 3: // key 4
		{
			new origin[3]
			get_user_origin(id,origin)
			set_pcvar_num(x_goal,origin[0])
			set_pcvar_num(y_goal,origin[1])
			set_pcvar_num(z_goal,origin[2])
			if(models[1] != -10) 
				{
				remove_entity(models[1])
				origin[0] = origin[0] - 40
				origin[2] = origin[2] + 20
				set_user_origin(id,origin)
				client_print(id,print_chat,"Moving you so you dont touch the end.")
				spawnGoalModel()
			}
			deletefile()
			modelmenu(id)
		}
		case 8: // key 9
		{
			client_cmd(id,"amx_skillsmenu")
		}
	}	
}

// Menu for admin to move/remove/spawn start & goal/set difficulty and teams allowed to finish & make map config
public adminmenu(id,level,cid){ 
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED // check acces
	show_menu(id,((1<<0)|(1<<1)|(1<<2)|(1<<9)),"Pick a task^n1: Move/Remove/Spawn start and goal^n2: Set difficulty & goalteams^n3: Make mapconfig^n^n0: Exit", -1, "adminmenu") // show menu
	return PLUGIN_CONTINUE 
}

// Executed when choices done in the adminmenu
public adminmenuenter(id,key){
	switch (key)
	{
		case 0: // key 1
		{
			modelmenu(id) // show other menu
		}
		case 1: // key 2
		{
			diffimenu(id) // show other menu
		}
		case 2: // key 3
		{
			skillsmenu(id) // show other menu
		}
	}
}

// Starts the timer when speed running
public starttimer(id){
	if(is_user_connected(id)) // if connected
		{
		if(is_user_alive(id)) // if alive
			{
			showspr(id) // show clock above head
		}
	}
}

// Show speedrun sprite
public showspr(id){ 
	if(hasTimer[id] == false || !is_user_connected(id) || !get_pcvar_num(amx_stimer)) return PLUGIN_HANDLED
	new i
	new players = get_maxplayers()
	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(125)
	write_byte(id)
	message_end()
	for (i = 0 ; i < players ; i++)
		{
		if(i != id && is_user_connected(i))
			{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,{0,0,0},i)
			write_byte(124) 
			write_byte(id) 
			write_coord(65)
			write_short(clockmodel)
			write_short(9) 
			message_end()
		}
	}
	set_task(0.8,"showspr",id)
	return PLUGIN_CONTINUE
}

// Show on screen timer
public showtimer(id){
	if(hasTimer[id] == false || !is_user_connected(id) || !get_pcvar_num(amx_stimer)) return PLUGIN_HANDLED
	if(is_user_alive(id) == 0)
		{
		hasTimer[id] = false
		return PLUGIN_HANDLED
	}
	new now = get_systime() - startTime[id]
	new hour = (now / 3600) % 24
	new minute = (now / 60) % 60
	new second = now % 60
	set_hudmessage(200, 100, 0, -1.0, 0.94, 0, 6.0, 1.0,0.0,0.0,3)
	show_hudmessage(id,"Your time: %d:%d:%d",hour,minute,second)
	set_task(1.0,"showtimer",id)
	return PLUGIN_CONTINUE
}

// Menu options to select difficulty when admin is adding map config
public diffimenu(id) { 
	new menumsg[130] 
	format(menumsg,129,"Please select a difficulty^nDifficulty now is: %d^n1: 10 up^n2: 5 up^n3: 1 up^n5: 10 down^n6: 5 down ^n7: 1 down ^n^n0: Done",menunumber) 
	show_menu(id,((1<<0)|(1<<1)|(1<<2)|(1<<4)|(1<<5)|(1<<6)|(1<<9)),menumsg, -1, "diffmenu") 
	return PLUGIN_CONTINUE
} 

// Menu to select difficulty when admin is adding map config
public diffimenuenter(id,key){ 
	switch (key) {  
		case 0:  
		{ 
			menunumber = menunumber + 10 
			if(menunumber > 100) menunumber = 100 
			diffimenu(id)
		} 
		case 1:  
		{ 
			menunumber = menunumber + 5 
			if(menunumber > 100) menunumber = 100 
			diffimenu(id) 
		} 
		case 2:  
		{ 
			menunumber = menunumber + 1 
			if(menunumber > 100) menunumber = 100 
			diffimenu(id) 
		} 
		case 4:  
		{ 
			menunumber = menunumber - 10 
			if(menunumber < 1) menunumber = 1 
			diffimenu(id) 
		} 
		case 5:  
		{ 
			menunumber = menunumber - 5 
			if(menunumber < 1) menunumber = 1 
			diffimenu(id) 
		} 
		case 6:  
		{ 
			menunumber = menunumber - 1 
			if(menunumber < 1) menunumber = 1 
			diffimenu(id) 
		} 
		case 9:  
		{ 
			set_pcvar_num(sv_diff,menunumber) 
			new name[32] 
			get_user_name(id,name,32) 
			client_print(0,print_chat,"Admin: %s has set the difficulty to %d",name,menunumber) 
			allowteams = ""
			blockteammenu(id)
		} 
	} 
}  

// Menu to select which teams are allowed to finish the map.
public blockteammenu(id){ 
	new menumsg[150] 
	format(menumsg,149,"Please select a goalteam(s)^nAllowed teams now are: %s^n1: Blue^n2: Red^n3: Yellow^n4: Green^n9: Redo^n^n0: Done",allowteams) 
	show_menu(id,((1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<8)|(1<<9)),menumsg, -1, "teammenu") 
}

// Exectuted when choices done in blockteammenu
public blockteammenuenter(id,key){ 
	switch (key) {  
		case 0:  
		{ 
			if(containi(allowteams,"b") == -1)
				{
				if(equal(allowteams,""))
					{
					format(allowteams,29,"B")
				}
				else
					{
					format(allowteams,29,"%sB",allowteams)
				}
			}
			blockteammenu(id) 
		} 
		case 1:  
		{ 
			if(containi(allowteams,"r") == -1)
				{
				if(equal(allowteams,""))
					{
					format(allowteams,29,"R")
				}
				else
					{
					format(allowteams,29,"%sR",allowteams)
				}
			}
			blockteammenu(id) 
		} 
		case 2:  
		{ 
			if(containi(allowteams,"y") == -1)
				{
				if(equal(allowteams,""))
					{
					format(allowteams,29,"Y")
				}
				else
					{
					format(allowteams,29,"%sY",allowteams)
				}
			}
			blockteammenu(id)
		} 
		case 3:  
		{ 
			if(containi(allowteams,"g") == -1)
				{
				if(equal(allowteams,""))
					{
					format(allowteams,29,"G")
				}
				else
					{
					format(allowteams,29,"%sG",allowteams)
				}
			}
			blockteammenu(id)
		} 
		case 8:  
		{ 
			allowteams = ""
			blockteammenu(id)
		} 
		case 9:  
		{ 
			set_cvar_string("sv_goalteams",allowteams)
			deletefile()
		} 
	} 
}  

// old map config deleted when admin is adding map config
public deletefile(){
	new mapname[32]
	get_mapname(mapname,31)
	format(path,61,"addons/amxmodx/configs/maps/%s.cfg",mapname)
	if (file_exists(path))
		{
		delete_file(path)
	}
	set_task(0.5,"setfile")
}

// New map config is written when admin is adding map config
public setfile(){
	new mapname[32]
	get_mapname(mapname,31)
	new mapfilestart[76]
	format(mapfilestart,75,"/*** START OF SKILLSRANK MAPFILE OF MAP %s ***\",mapname)
	write_file(path,mapfilestart,0)
	
	new x_cstart[32]
	format(x_cstart,31,"x_start %d",get_pcvar_num(x_start))
	write_file(path, x_cstart,1)
	
	new y_cstart[32]
	format(y_cstart,31,"y_start %d",get_pcvar_num(y_start))
	write_file(path, y_cstart,2)
	
	new z_cstart[32]
	format(z_cstart,31,"z_start %d",get_pcvar_num(z_start))
	write_file (path, z_cstart,3)
	
	new x_cgoal[32]
	format(x_cgoal,31,"x_goal %d",get_pcvar_num(x_goal))
	write_file(path, x_cgoal,4)
	
	new y_cgoal[32]
	format(y_cgoal,31,"y_goal %d",get_pcvar_num(y_goal))
	write_file (path, y_cgoal,5)
	
	new z_cgoal[32]
	format(z_cgoal,31,"z_goal %d",get_pcvar_num(z_goal))
	write_file(path, z_cgoal,6)
	
	new sv_cdifficulty[32]
	format(sv_cdifficulty,31,"sv_difficulty %d",get_pcvar_num(sv_diff))
	write_file(path, sv_cdifficulty,7)
	
	new sv_cgoalteams[32]
	get_pcvar_string(sv_gteam,sv_cgoalteams,31)
	format(sv_cgoalteams,31,"sv_goalteams %s",sv_cgoalteams)
	write_file(path, sv_cgoalteams,8)
	
	new mapfileend[76]
	format(mapfileend,75,"/*** END OF SKILLSRANK MAPFILE OF MAP %s ***\",mapname)
	write_file(path,mapfileend,9)
	
	set_task(2.0, "spawnStartModel")
	set_task(2.0, "spawnGoalModel")
	set_task(1.0, "deletemodels")
}

// Old start and end entities deleted when admin has added new map config
public deletemodels(){
	remove_entity(models[0])
	remove_entity(models[1])
	models[0] = 0
	models[1] = 0
}

// Shown to team disalloed to touch end
public shownot(id){
	set_hudmessage( 200, 100, 0, -1.0, 0.35, 0, 6.0, 12.0, 0.1, 0.2, 4 )
	show_hudmessage(id,"Your team is not allowed to do this.")
	client_cmd(id,"spk no")
	set_task(3.0,"canshow",id)
	dontspam[id] = true
}

// Allow user to touch end 
public canshow(id) dontspam[id] = false
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1053\\ f0\\ fs16 \n\\ par }
*/
