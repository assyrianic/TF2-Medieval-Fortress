
public Action PlayerSpawn (Event event, const char[] name, bool dontBroadcast)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

	CRPGClass spawn = CRPGClass( event.GetInt("userid"), true );
	if (spawn.index && IsClientInGame(spawn.index))
	{
		TFClassType tfclass = TF2_GetPlayerClass(spawn.index);
		switch (tfclass)
	        {
	                case TFClass_Scout, TFClass_Pyro, TFClass_Heavy, TFClass_DemoMan, TFClass_Spy, TFClass_Engineer:
			{
				switch ( GetRandomInt(0, 2) )
				{
					case 0: TF2_SetPlayerClass(spawn.index, TFClass_Soldier, _, false);
					case 1: TF2_SetPlayerClass(spawn.index, TFClass_Medic, _, false);
					case 2: TF2_SetPlayerClass(spawn.index, TFClass_Sniper, _, false);
				}
			}
			case TFClass_Soldier: TF2_SetPlayerClass(spawn.index, TFClass_Soldier, _, false);

	                case TFClass_Medic: TF2_SetPlayerClass(spawn.index, TFClass_Medic, _, false);
	                case TFClass_Sniper: TF2_SetPlayerClass(spawn.index, TFClass_Sniper, _, false);
	        }

	        TF2_RemoveAllWeapons2(spawn.index);

		switch (tfclass)
		{
			case TFClass_Soldier:
			{
				CKnightClass knight = CKnightClass(spawn.userid, true);
				knight.Equip();
			}
			case TFClass_Medic:
			{
				CMageClass mage = CMageClass(spawn.userid, true);
				mage.Equip();
			}
			case TFClass_Sniper:
			{
				CRangerClass ranger = CRangerClass(spawn.userid, true);
				ranger.Equip();
			}
		}
		TF2_AddCondition(spawn.index, TFCond_Ubercharged, 3.0); //ghetto spawn protection.
		SetEntityHealth(spawn.index, GetEntProp(spawn.index, Prop_Data, "m_iMaxHealth"));
		RPGFortressMenu (spawn.index, -1);
	}

        return Plugin_Continue;
}
public Action EventClassChange (Event event, const char[] name, bool dontBroadcast)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

        int client = GetClientOfUserId( event.GetInt("userid") );
	if ( client && IsClientInGame(client) )
	{
		switch (TF2_GetPlayerClass(client))
	        {
	                case TFClass_Scout, TFClass_Pyro, TFClass_Heavy, TFClass_DemoMan, TFClass_Spy, TFClass_Engineer:
			{
				switch ( GetRandomInt(0, 2) )
				{
					case 0: TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
					case 1: TF2_SetPlayerClass(client, TFClass_Medic, _, false);
					case 2: TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
				}
			}
	        }

		switch ( TF2_GetPlayerClass(client) )
		{
			case TFClass_Soldier:
			{
				CKnightClass knight = CKnightClass(client);
				knight.Equip();
			}
			case TFClass_Medic:
			{
				CMageClass mage = CMageClass(client);
				mage.Equip();
			}
			case TFClass_Sniper:
			{
				CRangerClass ranger = CRangerClass(client);
				ranger.Equip();
			}
		}
		TF2_RemovePlayerDisguise(client);
	}
        return Plugin_Continue;
}
public Action EventPlayerDeath (Event event, const char[] name, bool dontBroadcast)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

	CRPGClass victim = CRPGClass( event.GetInt("userid"), true );
	CRPGClass attacker = CRPGClass( event.GetInt("attacker"), true );
	if (victim.index <= 0 || attacker.index <= 0) return Plugin_Continue;


	if (attacker.userid != victim.userid && cvar_exp_onkill.IntValue >= 0 && attacker.iLevel < cvar_level_max.IntValue)
	{
		attacker.iExp += cvar_exp_onkill.IntValue;
		SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
		ShowSyncHudText(attacker.index, hudPlus2, "+%i", cvar_exp_onkill.IntValue);
	}

        return Plugin_Continue;
}
public Action EventPlayerHurt (Event event, const char[] name, bool dontBroadcast)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

	CRPGClass victim = CRPGClass( event.GetInt("userid"), true );
	CRPGClass attacker = CRPGClass( event.GetInt("attacker"), true );
        if ( victim.index <= 0 || attacker.index <= 0 || victim.userid == attacker.userid ) return Plugin_Continue;

	int rawDamage = event.GetInt("damageamount");
	float dmg = rawDamage*cvar_exp_ondmg.FloatValue;
	
	if ( (dmg > 0.0) && attacker.iLevel < cvar_level_max.IntValue )
	{
		attacker.iExp += RoundFloat(dmg);
		SetHudTextParams(0.24, 0.93, 1.0, 255, 100, 100, 150, 1);
		ShowSyncHudText(attacker.index, hudPlus1, "+%i", RoundFloat(dmg));
	}

        return Plugin_Continue;
}
public Action EventInventApp(Event event, const char[] name, bool dontBroadcast)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

	CRPGClass respply = CRPGClass( event.GetInt("userid"), true );

	if (respply.index && IsClientInGame(respply.index))
	{
		TF2_RemoveAllWeapons2(respply.index);

		switch ( TF2_GetPlayerClass(respply.index) )
		{
			case TFClass_Soldier:
			{
				CKnightClass knight = CKnightClass(respply.userid, true);
				knight.Equip();
			}
			case TFClass_Medic:
			{
				CMageClass mage = CMageClass(respply.userid, true);
				mage.Equip();
			}
			case TFClass_Sniper:
			{
				CRangerClass ranger = CRangerClass(respply.userid, true);
				ranger.Equip();
			}
		}
		SetEntityHealth(respply.index, GetEntProp(respply.index, Prop_Data, "m_iMaxHealth"));
	}

	return Plugin_Continue;
}
/*public Action Event_player_builtobject (Event event, const char[] name, bool dontBroadcast)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

        new engie = GetClientOfUserId(event.GetInt("userid"));
	new iTeam = GetClientTeam(engie);
	new index = -1;
	while ((index = FindEntityByClassname(index, "obj_sentrygun")) != -1)
	{
		new ammunition = GetEntProp(index, Prop_Send, "m_iAmmoShells", 0);
		if (ammunition > 0)
			SetEntProp(index, Prop_Send, "m_iAmmoShells", 0);

		SetEntProp(index, Prop_Send, "m_iHealth", 200);
		SetEntProp(index, Prop_Send, "m_iMaxHealth", 200);
		SetEntProp(index, Prop_Send, "m_iObjectType", _:TFObject_Sentry);
		SetEntProp(index, Prop_Send, "m_iState", 1);
			
		SetEntProp(index, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(index, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(index, Prop_Send, "m_iUpgradeLevel", 3);
		SetEntProp(index, Prop_Send, "m_iAmmoRockets", 300);
			
		SetEntPropEnt(index, Prop_Send, "m_hBuilder", engie);
			
		SetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 3);
		SetEntProp(index, Prop_Send, "m_bPlayerControlled", 0);
		SetEntProp(index, Prop_Send, "m_bHasSapper", 0);
	}
	while ((index = FindEntityByClassname(index, "obj_dispenser")) != -1)
	{
		SetEntProp(index, Prop_Send, "m_iAmmoMetal", 500);
		SetEntProp(index, Prop_Send, "m_iHealth", 200);
		SetEntProp(index, Prop_Send, "m_iMaxHealth", 200);
		SetEntProp(index, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
		SetEntProp(index, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(index, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 1);
		SetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntPropEnt(index, Prop_Send, "m_hBuilder", engie);
	}

        return Plugin_Continue;
}*/

