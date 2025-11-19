bool IsCurrentMap(const char[] map)
{
	char currentMap[MAX_MAP_NAME_LENGTH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	return !strcmp(map, currentMap);
}

float GetCurrentRatesAverage()
{
	int sum, amount;

	for(RateType rate = Excellent; rate > None; rate--)
	{
		int length = gCurrentRates[rate].Length;

		sum += (gCurrentRates[rate].Length * view_as<int>(rate));
		amount += length;
	}

	if(amount)
		return (float(sum) / float(amount));
	else
		return 0.0;
}

RateType GetClientMapRate(int client)
{
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	for(RateType rate = Excellent; rate > None; rate--)
	{
		if(gCurrentRates[rate].FindString(auth) != -1)
			return rate;
	}

	return None;
}

int GetCurrentMapRateSum()
{
	int sum;
	
	for(RateType rate = Excellent; rate > None; rate--)
		sum += gCurrentRates[rate].Length;

	return sum;
}

void GetCountedBars(int barsSum, char[] buffer, int maxLength)
{
	for(int i = 0; i < MAX_BARS; i++)
	{
		if(i < barsSum)
			StrCat(buffer, maxLength, "▓");
		else
			StrCat(buffer, maxLength, "░");
	}
}

stock bool IsEntityPlayer(int entity)
{
	return IsValidEntity(entity) && (1 <= entity <= MaxClients);
}

stock bool IsValidClient(int client)
{
	if(!IsEntityPlayer(client))
		return false;

	if(!IsClientConnected(client) || !IsClientInGame(client))
		return false;

	return true;
}