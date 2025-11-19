#include <morecolors>

#pragma semicolon 1

#define MAX_QUERY_LENGTH	256
#define MAX_MAP_NAME_LENGTH 96
#define MAX_BARS			8

#define INVALID_RATING view_as<Rating>(INVALID_HANDLE)

enum RateType
{
	None = 0,
	Terrible,
	Poor,
	Average,
	Good,
	Excellent
}

stock const char gRatePhrases[RateType][] = {"None", "Terrible", "Poor", "Average", "Good", "Excellent"};

Database gDatabase;
StringMap gMaps;

bool gWorking;
GlobalForward gOnSuccessInit;

ArrayList gCurrentRates[RateType];
RateType gPlayerCurrentRate[MAXPLAYERS] = { None, ... };

methodmap Rating < StringMap
{
	public Rating(const char[] mapName)
	{
		StringMap rating = new StringMap();

		rating.SetString("map", mapName); 
		rating.SetValue("avg", 0.0);

		return view_as<Rating>(rating);
	}

	public void GetRating()
	{
		char map[MAX_MAP_NAME_LENGTH];
		this.GetString("map", map, sizeof(map));

		char query[MAX_QUERY_LENGTH];
		if(IsCurrentMap(map))
		{
			FormatEx(query, sizeof(query), "SELECT `rating`, `steamid` FROM map_ratings WHERE `map` = '%s'", map);
			gDatabase.Query(OnMapRatesQuery, query, this);
		}
		else
		{
			FormatEx(query, sizeof(query), "SELECT AVG(`rating`) AS `average` FROM `map_ratings` WHERE `map` = '%s'", map);
			gDatabase.Query(OnMapAverageQuery, query, this);
		}
	}

	public void SetDisplayName(const char[] display)
	{
		this.SetString("display", display);
	}

	public bool GetDisplayName(char[] buffer, int maxLength)
	{
		return this.GetString("display", buffer, maxLength);
	}

	property float Average
	{
		public get()
		{
			float avg;
			if(this.GetValue("avg", avg))
				return avg;

			char mapName[MAX_MAP_NAME_LENGTH];
			if(!this.GetDisplayName(mapName, sizeof(mapName)))
				this.GetString("map", mapName, sizeof(mapName));
			
			LogError("Rating.Average.get() :: Couldn\'t get the average score of the map %s", mapName);
			return 0.0;
		}
		public set(float avg)
		{
			this.SetValue("avg", avg);
		}
	}

	public void Rate(int client, RateType rate)
	{
		if(rate == None)
			return;
		
		char auth[32], map[MAX_MAP_NAME_LENGTH];
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
		this.GetString("map", map, sizeof(map));

		DataPack pack = new DataPack();
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(auth);
		pack.WriteCell(view_as<int>(rate));
		pack.WriteCell(this);

		char query[MAX_QUERY_LENGTH];
		if(gPlayerCurrentRate[client] != None)
			FormatEx(query, sizeof(query), "UPDATE `map_ratings` SET `rating` = %i, `rated` = NOW() WHERE `map` = '%s' AND `steamid` = '%s';", view_as<int>(rate), map, auth);
		else
			FormatEx(query, sizeof(query), "INSERT INTO `map_ratings` (`map`, `steamid`, `rating`, `rated`) VALUES ('%s', '%s', %i, NOW());", map, auth, view_as<int>(rate));
	
		gDatabase.Query(OnClientMapRate, query, pack);
	}

	public void PrintInfo()
	{
		char map[MAX_MAP_NAME_LENGTH];
		this.GetString("map", map, sizeof(map));
		PrintToServer("%s\'s average rate: %.2f", map, this.Average);
	}

	public void Destroy()
	{
		this.Close();
	}
}

Rating gCurrentRating;

#include "maprate/database.sp"
#include "maprate/menu.sp"
#include "maprate/commands.sp"
#include "maprate/api.sp"
#include "maprate/helpers.sp"

public Plugin myinfo =
{
	name = "Map Rating",
	author = "saxyboi",
	description = "Plugin that allows to rate maps",
	version = "1.0"
};

public void OnPluginStart()
{
	gMaps = new StringMap();

	for(RateType rate = Excellent; rate > None; rate--)
		gCurrentRates[rate] = new ArrayList(32);

	DatabaseInit();
	CommandsInit();

	LoadTranslations("maprate.phrases");
}

public void OnMapInit(const char[] mapName)
{
	if(gDatabase == null)
		return;

	if(!gMaps.GetValue(mapName, gCurrentRating))
	{
		LogMessage("OnMapInit() :: New map on the server, let\'s check rating of it...");
		gCurrentRating = new Rating(mapName);
		gMaps.SetValue(mapName, gCurrentRating);
	}
	
	gCurrentRating.GetRating();
}

public void OnClientPostAdminCheck(int client)
{
	gPlayerCurrentRate[client] = GetClientMapRate(client);
}

public void OnClientDisconnect_Post(int client)
{
	gPlayerCurrentRate[client] = None;
}

void RatingsInit()
{
	char path[PLATFORM_MAX_PATH];
	FileType type;
	
	DirectoryListing dir = OpenDirectory("maps/", true);
	while(ReadDirEntry(dir, path, sizeof(path), type))
	{
		if(type != FileType_File)
			continue;
		
		int bspPos = StrContains(path, ".bsp");
		if(bspPos == -1)
			continue;

		path[bspPos] = '\0';
		
		if(!gMaps.ContainsKey(path))
			gMaps.SetValue(path, GetRating(path));
	}

	gWorking = true;

	if(gOnSuccessInit.FunctionCount > 0)
	{
		Call_StartForward(gOnSuccessInit);
		int result;
		Call_Finish(result);

		if(result)
			LogError("RatingsInit() :: There were problems when calling the global forward MapRate_OnSuccessInit() (error code: %i)", result);
	}
}

Rating GetRating(const char[] mapName)
{
	Rating rating = new Rating(mapName);
	rating.GetRating();

	return rating;
}