
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

