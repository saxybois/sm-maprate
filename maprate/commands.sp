void CommandsInit()
{
	RegConsoleCmd("sm_maprate", OpenRateMenu, "Opens the menu for rating the current map");
	RegConsoleCmd("sm_maprating", OpenRateMenu, "Opens the menu for rating the current map");

	RegAdminCmd("sm_maprate_reset", ResetData, ADMFLAG_CHEATS, "Clear the plugin's memory and retrieve the data again");
	RegServerCmd("sm_maprates", ShowMapRates);
}

Action OpenRateMenu(int client, int args)
{
	RateMenu(client);
	
	return Plugin_Handled;
}

Action ShowMapRates(int args)
{
	StringMapSnapshot snapshot = gMaps.Snapshot();

	int maps = snapshot.Length;

	for(int i = 0; i < maps; i++)
	{
		char map[MAX_MAP_NAME_LENGTH];
		snapshot.GetKey(i, map, sizeof(map));

		if(IsCurrentMap(map))
		{
			gCurrentRating.PrintInfo();

			PrintToServer("rates:");
			for(RateType rate = Excellent; rate > None; rate--)
			{
				int amount = gCurrentRates[rate].Length;
				PrintToServer("\t%i (%i):", view_as<int>(rate), amount);
				for(int j = 0; j < amount; j++)
				{
					char auth[32];
					gCurrentRates[rate].GetString(j, auth, sizeof(auth));
					PrintToServer("\t\t%s", auth);
				}
			}
		}
		else
		{
			Rating rating;
			gMaps.GetValue(map, rating);
			rating.PrintInfo();
		}
	} 

	delete snapshot;
	
	return Plugin_Handled;
}

Action ResetData(int client, int args)
{
	gWorking = false;
	
	ReplyToCommand(client, "Clearing average map ratings...");
	StringMapSnapshot snapshot = gMaps.Snapshot();
	
	int length = snapshot.Length;
	for(int i = 0; i < length; i++)
	{
		Rating map;
		char mapName[MAX_MAP_NAME_LENGTH];
		snapshot.GetKey(i, mapName, sizeof(mapName));
		if(gMaps.GetValue(mapName, map))
		{
			map.Destroy();
			ReplyToCommand(client, "\tCleared the average rating of the map %s", mapName);
		}
		else
		{
			ReplyToCommand(client, "\tThere were problems when cleaning the average rating of the map %s...", mapName);
			LogError("ResetData() :: Rating pseudo-class object could not be retrieved by the map name %s", mapName);
		}
	}

	delete snapshot;
	gMaps.Clear();

	ReplyToCommand(client, "Clearing the ratings of the current map...");
	for(RateType rate = Excellent; rate > None; rate--)
		gCurrentRates[rate].Clear();

	ReplyToCommand(client, "Clearing current player ratings...");
	for(int i = 1; i <= MaxClients; i++)
		gPlayerCurrentRate[i] = None;

	ReplyToCommand(client, "Clearing the link to the current map\'s average rating...");
	gCurrentRating = INVALID_RATING;

	ReplyToCommand(client, "Filling the memory with fresh data...");
	RatingsInit();

	ReplyToCommand(client, "Done!");

	return Plugin_Handled;
}