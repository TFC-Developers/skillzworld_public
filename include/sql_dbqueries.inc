#if defined _sql_queries_included
  #endinput
#endif
#define _sql_queries_included

//requires %/ranks %s/ranks %s/runs %s/runs %s/runs %s/ranks %s/steamid
new const sql_oldStatsme[] = "SELECT sr.steamId, sr.primaryRank, sr.nFinnished, ( SELECT COUNT(*) + 1 FROM %s WHERE nFinnished >= 100 AND primaryRank > sr.primaryRank \
  ) as position, ( SELECT COUNT(*) FROM %s WHERE nFinnished >= 100 ) as posmax, ( SELECT COUNT(*) FROM %s WHERE steamId = sr.steamId ) as mapFinishes, ( \
    SELECT COUNT(*) FROM %s WHERE steamId = ( SELECT steamId FROM %s GROUP BY steamId ORDER BY COUNT(*) DESC LIMIT 1  )  ) as mostMapFinishes FROM %s as sr WHERE sr.nFinnished >= 100 AND sr.steamId = \'%s\';"