#if defined _maprate_included_
  #endinput
#endif
#define _maprate_included_

/**
 * Open map rating menu for client
 * @param client      Client's index
 * @param forceRate   Forcing client rate a map even when they've already rated it
 * @param display     How long will the menu be displayed (0 - forever)  
 */
native void MapRate_AskToRate(int client, bool forceRate = false, int display = 0);

/**
 * Get the average of all ratings for a specified map
 * @param mapName  Map name (no .bsp)
 * @return  Average map rating
 */
native float MapRate_GetAverage(const char[] mapName);

/**
 * Set the map viewable (in menu and response) name
 * @param mapName      The name of the map where the viewable name will be set
 * @param displayName  Viewable name
 */
native void MapRate_SetDisplayName(const char[] mapName, const char[] displayName);

/**
 * Returns the plugin's status (whether all the ratings have been received)
 * @return  true if all location ratings have been received, otherwise false (also false will be returned during plugin data cleaning)
 */
native bool MapRate_IsWorking();

/**
 * Forward, called after successful launch and getting all ratings
 */
forward void MapRate_OnSuccessInit();

public SharedPlugin __pl_maprate = 
{
	name = "maprate",
	file = "maprate.smx",

	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_maprate_SetNTVOptional()
{
	MarkNativeAsOptional("MapRate_AskToRate");
	MarkNativeAsOptional("MapRate_GetAverage");
	MarkNativeAsOptional("MapRate_SetDisplayName");
	MarkNativeAsOptional("MapRate_IsWorking");
}
#endif