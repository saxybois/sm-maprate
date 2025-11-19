public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("MapRate_AskToRate", NativeAskToRate);
	CreateNative("MapRate_GetAverage", NativeGetAverage);
	CreateNative("MapRate_SetDisplayName", NativeSetDisplayName);
	CreateNative("MapRate_IsWorking", NativeIsWorking);

	gOnSuccessInit = CreateGlobalForward("MapRate_OnSuccessInit", ET_Ignore);

	RegPluginLibrary("maprate");

	return APLRes_Success;
}

int NativeAskToRate(Handle plugin, int numParams)
{
	RateMenu(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
	
	return 0;
}

any NativeGetAverage(Handle plugin, int numParams)
{
	char mapName[MAX_NAME_LENGTH];
	GetNativeString(1, mapName, sizeof(mapName));

	Rating rating;
	if(gMaps.GetValue(mapName, rating))
		return rating.Average;

	return 0.0;
}

int NativeSetDisplayName(Handle plugin, int numParams)
{
	char mapName[MAX_NAME_LENGTH];
	GetNativeString(1, mapName, sizeof(mapName));

	Rating rating;
	if(gMaps.GetValue(mapName, rating))
	{
		char display[MAX_MAP_NAME_LENGTH];
		GetNativeString(2, display, sizeof(display));
		rating.SetDisplayName(display);
	}

	return 0;
}

any NativeIsWorking(Handle plugin, int numParams)
{
	return gWorking;
}