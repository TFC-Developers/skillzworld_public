
//requires %/ranks %s/ranks %s/runs %s/runs %s/runs %s/ranks %s/steamid
new const sql_oldStatsme[] = "SELECT sr.steamId, sr.primaryRank, sr.nFinnished, ( SELECT COUNT(*) + 1 FROM %s WHERE nFinnished >= 100 AND primaryRank > sr.primaryRank \
  ) as position, ( SELECT COUNT(*) FROM %s WHERE nFinnished >= 100 ) as posmax, ( SELECT COUNT(*) FROM %s WHERE steamId = sr.steamId ) as mapFinishes, ( \
    SELECT COUNT(*) FROM %s WHERE steamId = ( SELECT steamId FROM %s GROUP BY steamId ORDER BY COUNT(*) DESC LIMIT 1  )  ) as mostMapFinishes FROM %s as sr WHERE sr.nFinnished >= 100 AND sr.steamId = \'%s\';"

// Insert the map if it does not exist
new const sql_insertmap[] = "INSERT IGNORE INTO maps (name) VALUES ('%s');";

//requires %s/mapname(string) %i/createrid(int) %s/coursename(string) %s/coursedescription(string) %i/legacy(bool) %i/difficulty(int) %i/active(bool) %i/flags(int)
new const sql_insertcourse[] = "INSERT INTO courses (map_id, creator_id, name, description, legacy, difficulty, active, flags) \
VALUES ((SELECT id FROM maps WHERE name = '%s'), %d, '%s', '%s', %d, %d, %d, %d);"

//requires %s/mapname
new const sql_selectcourses[] = "SELECT c.*, p.firstnick AS creator_name FROM courses c JOIN maps m ON m.id = c.map_id JOIN players p ON p.id = c.creator_id WHERE m.name = '%s';"

//requires %s/mapname %f/x %f/y %f/z %d/type
new const sql_insertlegacycps[] = "INSERT INTO checkpoints(course_id, x, y, z, checkpoint_type) VALUES ( (SELECT c.id FROM courses c JOIN maps m ON m.id = c.map_id WHERE m.name = '%s' AND c.legacy = TRUE), %f, %f, %f, %d);"

//requires %s/mapname
new const sql_loadcps[] = "SELECT cp.* FROM checkpoints cp JOIN courses c ON cp.course_id = c.id JOIN maps m ON m.id = c.map_id WHERE m.name = '%s';"

//requires %s/steamid %s/nickname
new const sql_insertplayer[] = "INSERT INTO players (steamid, userlevel, firstnick, timer, totaltime, userflags) VALUES ('%s', 0, '%s', 0, 0, 0) ON DUPLICATE KEY UPDATE id = id;"

//requires %s/steamid
new const sql_loadplayer[] = "SELECT * FROM players WHERE steamid = '%s';"

//requires %f/time %s/steamid
new const sql_updatetime[] = "UPDATE players SET totaltime = totaltime + %f WHERE steamid = '%s';"

//require %s/steamid %s/ip %s/nickname %server %/map %s/action_type %s/steamid
new const sql_serverlog[] = "INSERT INTO server_logs (steamid, time, ip, nickname, server, map, userid, action_type) SELECT '%s', CURRENT_TIMESTAMP, '%s', '%s', '%s', '%s', id, '%s' FROM players WHERE steamid = '%s';"

//require %s/steamid %s/ip %s/nickname %server %/map %s/action_type %s/steamid
new const sql_serverlogdata[] = "INSERT INTO server_logs (steamid, time, ip, nickname, server, map, userid, action_type, data) SELECT '%s', CURRENT_TIMESTAMP, '%s', '%s', '%s', '%s', id, '%s', '%s' FROM players WHERE steamid = '%s';"

//requires %d/courseid %f/runtime %d/class %d/cps used %s/steamid
new const sql_insertrunquery[] = "INSERT INTO runs (course_id, player_id, time, player_class, cps_used) SELECT %d, players.id, %f, %d, %d FROM players WHERE players.steamid = '%s';"

//requires %s/steamid %s/nickname
new const sql_updatenamequery[] = "INSERT INTO nicknames (steamid, nickname, usage_count) VALUES ('%s', '%s', 1) ON DUPLICATE KEY UPDATE usage_count = usage_count + 1;"

//requires %s/mapname
new const sql_getrunsformap[] = "SELECT runs.*, players.steamid, (SELECT nickname FROM nicknames WHERE \
nicknames.steamid = players.steamid ORDER BY usage_count DESC LIMIT 1) as most_used_nickname FROM runs JOIN courses ON runs.course_id = courses.id \
JOIN maps ON courses.map_id = maps.id JOIN players ON runs.player_id = players.id WHERE maps.name = '%s' AND runs.time != 0 ORDER BY runs.time ASC LIMIT 5000;";

//requires %s/mapname
new const sql_getgroupedrunsformap[] = "WITH best_runs AS (SELECT players.steamid, runs.player_class, MIN(runs.time) as best_time FROM runs JOIN courses ON runs.course_id = courses.id \ 
JOIN maps ON courses.map_id = maps.id JOIN players ON runs.player_id = players.id WHERE maps.name = '%s' AND runs.time != 0 GROUP BY players.steamid, runs.player_class) \
SELECT runs.*, best_runs.steamid, (SELECT nickname FROM nicknames WHERE nicknames.steamid = best_runs.steamid ORDER BY usage_count DESC LIMIT 1) as most_used_nickname \
FROM runs JOIN best_runs ON runs.time = best_runs.best_time AND runs.player_class = best_runs.player_class JOIN players ON players.steamid = best_runs.steamid ORDER BY runs.time ASC LIMIT 5000;"

//requires %s/name
new const sql_get_common_name[] = "SELECT nickname, usage_count FROM nicknames WHERE steamid = '%s' ORDER BY usage_count DESC LIMIT 10;";

//requires %s/mapname
new const sql_updatemapflags[] = "UPDATE maps SET flags = %d WHERE name = '%s';"

//requires %s/mapname
new const sql_retrievemapflags[] = "SELECT flags FROM maps WHERE name = '%s';"