
public Action CommandSetLevels(int client, int args)
{
	if (rs_enable.BoolValue)
	{
		if (args < 2)
		{
			ReplyToCommand(client, "[RPG Fortress] Usage: rpg_setlvl <target> <lvl>");
			return Plugin_Handled;
		}
		char s2[16];
		char targetname[32];
		GetCmdArg(1, targetname, sizeof(targetname));
		GetCmdArg(2, s2, sizeof(s2));
		int points = StringToInt(s2);

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ( (target_count = ProcessTargetString(
				targetname,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		CRPGClass player;
		for (int i = 0; i < target_count; i++)
		{
			if (!IsValidClient(target_list[i])) continue;

			player = CRPGClass(target_list[i]);
			player.iCookyLevel = points;
			player.DoLevelUp(points);
			//SetPlayerLevel(target_list[i], points);
			//LevelUp(target_list[i], points);
		}
	}
	return Plugin_Handled;
}
public Action RPGFortressMenu(int client, int args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && rs_enable.BoolValue)
	{
		Menu main = new Menu(MenuHandler_RPGFortress);

		main.SetTitle("Main Menu - Choose Category:");
		main.AddItem("pick_weapon", "Choose a Weapon");
		main.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

