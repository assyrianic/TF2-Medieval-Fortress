
public Action Timer_Announce(Handle hTimer)
{
	if (rs_enable.BoolValue) CPrintToChatAll("{orange}[RPG Fortress] {default}type {green}!rpg{default} to access menu");
        return Plugin_Continue;
}

public Action PlayerTimer(Handle hTimer)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

	for (int client = 1 ; client <= MaxClients ; ++client)
	{
		if ( !IsValidClient(client) ) continue;
		if ( !IsPlayerAlive(client) ) continue;

		if ( TF2_IsPlayerInCondition(client, TFCond_Bleeding) ) { 
			TF2_RemoveCondition(client, TFCond_Bleeding); //remove bleeding from cleavers
		}

		switch ( TF2_GetPlayerClass(client) )
		{
			case TFClass_Medic:	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", player_speed_medic.FloatValue);
			case TFClass_Sniper:	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", player_speed_sniper.FloatValue);
			case TFClass_Soldier:	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", player_speed_soldier.FloatValue);
		}
	}
	return Plugin_Continue;
}

public Action RegenSpells(Handle lTimer)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

	CMageClass mage;
	for ( int client = 0 ; client <= MaxClients ; ++client )
	{
		if (!IsValidClient(client) || TF2_GetPlayerClass(client) != TFClass_Medic) continue;
		mage = CMageClass(client);
		int spellbook = FindSpellbook(client);

		//Adds a single spell
		if ( IsValidEntity(spellbook) && mage.flSpell < GetGameTime() )
		{
			if ( GetSpellCharges(spellbook) == 1 ) continue;

			float flCooldown;
			switch ( GetSpellIndex(spellbook) )
			{
				case 0: flCooldown = cvar_fireball_recharge.FloatValue;
				case 7: flCooldown = cvar_electric_recharge.FloatValue;
				case 1: flCooldown = cvar_hellfire_recharge.FloatValue;
			}
			mage.flSpell = GetGameTime() + flCooldown;
		        SetSpellCharges(spellbook, GetSpellCharges(spellbook)+1);
		        if ( GetSpellCharges(spellbook) > 1 ) SetSpellCharges(spellbook, 1);
		}
	}
        return Plugin_Continue;
}

