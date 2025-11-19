void DatabaseInit()
{
	Database.Connect(OnDatabaseConnect, "MapRate");
}

void OnDatabaseConnect(Database db, const char[] error, any data)
{
	if(db == null)
	{
		SetFailState("OnDatabaseConnect() :: %s", error);
		
		return;
	}

	gDatabase = db;

	SQL_LockDatabase(gDatabase);

	gDatabase.Query(OnCheckErrors, "CREATE TABLE IF NOT EXISTS `map_ratings` (`id` INT(11) NOT NULL AUTO_INCREMENT,\
																			  `steamid` VARCHAR(32) NOT NULL,\
																			  `map` VARCHAR(64) NOT NULL,\
																			  `rating` INT(4) NOT NULL,\
																			  `rated` DATETIME NOT NULL,\
																			  PRIMARY KEY (`id`));");

	SQL_UnlockDatabase(gDatabase);

	gDatabase.SetCharset("utf8");

	RatingsInit();
}

void OnMapRatesQuery(Database db, DBResultSet results, const char[] error, Rating rating)
{
	for(RateType rate = Excellent; rate > None; rate--)
		gCurrentRates[rate].Clear();
	
	if(error[0])
	{
		LogError("OnMapRatesQuery() :: %s", error);

		return;
	}

	while(results.FetchRow())
	{
		RateType rate = view_as<RateType>(results.FetchInt(0));
		
		char auth[32];
		results.FetchString(1, auth, sizeof(auth));

		gCurrentRates[rate].PushString(auth);
	}

	rating.Average = GetCurrentRatesAverage();
	gCurrentRating = rating;

	// цикл ниже на случай, если запрос будет идти дольше, чем подключаются игроки.
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
			gPlayerCurrentRate[i] = GetClientMapRate(i);
	}
}

void OnClientMapRate(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	if(error[0])
	{
		LogError("OnClientRate() :: %s", error);

		delete pack;
		return;
	}

	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	
	char auth[32];
	pack.ReadString(auth, sizeof(auth));

	RateType newRate = view_as<RateType>(pack.ReadCell());
	Rating rating = view_as<Rating>(pack.ReadCell());

	if(client)
	{
		RateType oldRate = gPlayerCurrentRate[client];
		gPlayerCurrentRate[client] = newRate;
	
		if(oldRate != None)
		{
			int index = gCurrentRates[oldRate].FindString(auth);
			if(index != -1)
				gCurrentRates[oldRate].Erase(index);
		}
		
		gCurrentRates[gPlayerCurrentRate[client]].PushString(auth);
		
		char mapName[MAX_MAP_NAME_LENGTH];
		if(!rating.GetDisplayName(mapName, sizeof(mapName)))
			rating.GetString("map", mapName, sizeof(mapName));

		CPrintToChat(client, "%t %t", "Tag", "Success Map Rate", mapName, gRatePhrases[gPlayerCurrentRate[client]], client);
	}
	else
	{
		for(RateType rate = Excellent; rate > None; rate--)
		{
			int index = gCurrentRates[rate].FindString(auth);
			if(index != -1)
				gCurrentRates[rate].Erase(index);
		}
	}

	rating.Average = GetCurrentRatesAverage();

	delete pack;
}

void OnMapAverageQuery(Database db, DBResultSet results, const char[] error, Rating rating)
{
	if(error[0])
	{
		LogError("OnMapAverageQuery() :: %s", error);

		return;
	}

	if(results.FetchRow())
		rating.Average = results.FetchFloat(0);
	
	// rating.PrintInfo();
}

void OnCheckErrors(Database db, DBResultSet results, const char[] error, any data)
{
	if(error[0])
		LogError("OnCheckErrors() :: %s", error);
}