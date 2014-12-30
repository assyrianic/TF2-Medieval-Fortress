#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>
#include <clientprefs>
#include <tf2attributes>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

/*
C R E D I T S
---------------
props to mitch for the spells coding
arkarr for suggestions and help, and magic spell timer
Flamin' Sarge for various code snippets from his plugins
noodleboy347 for level mod
Zephyreus for help
TAZ - for LOADS OF help lol
IF IT WEREN'T FOR THESE GUYS, THIS PLUGIN WOULDN'T EXIST.
Props to uberpirates for supporting and giving ideas for this mod :>
*/

/*
I D E A S
----------

*/

#define PLUGIN_VERSION			"1.12 BETA"
#define CLIENTS				MAXPLAYERS+1
#pragma newdecls			required

//non-cvar handles-------------------------------------------------------------------------------------------------------------
Handle hudLevel;
Handle hudEXP;
Handle hudPlus1;
Handle hudPlus2;
Handle hudLevelUp;
//Handle Prayertext;
Handle LvlCookie;

//cvar handles----------------------------------------------------------------------------------------------------------------
ConVar rs_enable = null;
ConVar cvar_fireball_recharge = null;
ConVar cvar_hellfire_recharge = null;
ConVar cvar_electric_recharge = null;
//ConVar cvar_exp_levelup;
ConVar cvar_level_max;
ConVar cvar_exp_default;
ConVar cvar_exp_onkill;
ConVar cvar_exp_ondmg;
ConVar player_speed_sniper = null;
ConVar player_speed_soldier = null;
ConVar advert_timer = null;
ConVar player_speed_medic = null;
//Handle cvar_level_default;
//Handle prayer_charge_timer = null;
//Handle PrayerCharge = null;
//Handle cvar_prayer_melee_dmgreduce = null;
//Handle cvar_prayer_ranged_dmgreduce = null;
//Handle cvar_prayer_magic_dmgreduce = null;
//Handle player_speed_engineer = null;

//floats--------------------------------------------------------------------------------------------------------
float flSpell[CLIENTS];
//float flPrayerCharge[MAXPLAYERS+1];

//ints----------------------------------------------------------------------------------------------------------
//new PrayerCond[MAXPLAYERS+1];
int iPlayerLevel[CLIENTS];
int iPlayerExp[CLIENTS];
int iPlayerExpMax[CLIENTS];
int iWepSelection[CLIENTS];
int iRemoveItems[] = {
	241, //various action items
	280,
	281,
	282,
	283,
	284,
	286,
	288,
	362,
	364,
	365,
	489, //mvm canteen
	493,
	1069, //spellbooks
	1070,
	1132,
	5604,
	30015, //more canteens
	30535
};

#if defined _steamtools_included
bool steamtools = false;
#endif
//bool spellsregen[CLIENTS];
 
public Plugin myinfo = {
        name = "RPG Fortress",
        author = "Assyrian/Nergal & others",
        description = "RPG Fortress for Medieval Mode",
        version = PLUGIN_VERSION,
        url = "http://steamcommunity.com/groups/acvsh | http://forums.alliedmods.net/showthread.php?t=230178"
};
 
public void OnPluginStart()
{
        CreateConVar("rpg_version", PLUGIN_VERSION, "RPG Fortress Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
        rs_enable = CreateConVar("rpg_enabled", "1", "Enables RPG Fortress mod", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	//prayer_charge_timer = CreateConVar("rpg_prayercharge_timer", "3.0", "this cvar will give players a set amount of prayer charge every  seconds", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//PrayerCharge = CreateConVar("rpg_prayer_charge_amount", "1.0", "this cvar adds prayer charge every second that is set by rs_prayercharge_timer", FCVAR_PLUGIN|FCVAR_NOTIFY);

	cvar_fireball_recharge = CreateConVar("rpg_fireball_recharge", "4.0", "Every x seconds, 1 fireball spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);
        cvar_hellfire_recharge = CreateConVar("rpg_hellfire_recharge", "3.0", "Every x seconds, 1 hellfire spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);
        cvar_electric_recharge = CreateConVar("rpg_electric_recharge", "8.0", "Every x seconds, 1 electrical bolt spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);

	//cvar_prayer_melee_dmgreduce = CreateConVar("rpg_melee_dmgreduce", "0.75", "damage multiplier if player has Protect from Melee activated", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//cvar_prayer_ranged_dmgreduce = CreateConVar("rpg_ranged_dmgreduce", "0.7", "damage multiplier if player has Protect from Ranged activated", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//cvar_prayer_magic_dmgreduce = CreateConVar("rpg_magic_dmgreduce", "0.6", "damage multiplier if player has Protect from Magic activated", FCVAR_PLUGIN|FCVAR_NOTIFY);

        advert_timer = CreateConVar("rpg_advert_timer", "90.0", "amount of time the plugin advert will pop up", FCVAR_PLUGIN|FCVAR_NOTIFY);

        HookConVarChange(FindConVar("sv_tags"), cvarChange_Tags); //props to Flamin' Sarge
#if defined _steamtools_included
        steamtools = LibraryExists("SteamTools");
#endif
	//cvar_level_default = CreateConVar("rpg_level_default", "1", "Default level for players when they join");
	cvar_level_max = CreateConVar("rpg_level_max", "99", "Maximum level players can reach");
	cvar_exp_default = CreateConVar("rpg_exp_default", "83", "Default max experience for players when they join");
	cvar_exp_onkill = CreateConVar("rpg_exp_onkill", "50", "Experience to gain on kill");
	//cvar_exp_levelup = CreateConVar("rpg_exp_levelup", "0.833", "Experience increase on level up");
	cvar_exp_ondmg = CreateConVar("rpg_exp_damage_mult", "1.25", "Experience multiplier for damage");

	player_speed_medic = CreateConVar("rpg_playerspeed_medic", "350.0", "speed of Medics in Hammer units");
	//player_speed_engineer = CreateConVar("rpg_playerspeed_engie", "350.0", "speed of Engineers in Hammer units");
	player_speed_sniper = CreateConVar("rpg_playerspeed_sniper", "350.0", "speed of Snipers in Hammer units");
	player_speed_soldier = CreateConVar("rpg_playerspeed_soldier", "400.0", "speed of Soldiers in Hammer units");
	
	LvlCookie = RegClientCookie("rpgfortress_levels", "RPG Fortress Player Levels cookie", CookieAccess_Protected);

        AutoExecConfig(true, "RPG_Fortress");
       
        // = CreateConVar("", "0", "", FCVAR_PLUGIN, true, 0.0, true, 1.0);

        hudLevel = CreateHudSynchronizer();
        hudEXP = CreateHudSynchronizer();
	//Prayertext = CreateHudSynchronizer();
        hudPlus1 = CreateHudSynchronizer();
        hudPlus2 = CreateHudSynchronizer();
        hudLevelUp = CreateHudSynchronizer();

        HookEvent("player_spawn", PlayerSpawn);
	HookEvent("post_inventory_application", EventInventApp);
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
        HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
        HookEvent("player_changeclass", EventClassChange);
	//HookEvent("player_builtobject", Event_player_builtobject);

        RegConsoleCmd("sm_rpg", RS_Menu, "RPG Fortress menu");
	RegAdminCmd("sm_rpg_setlvl", CommandSetLevels, ADMFLAG_KICK, "reset all player levels");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
}
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	//PrayerCond[client] = -1;
	//flPrayerCharge[client] = 0.0;
	iPlayerExp[client] = 0;
	iPlayerExpMax[client] = cvar_exp_default.IntValue;
	if (GetPlayerLevel(client) < 1)
	{
		SetPlayerLevel(client, 1);
		LevelUp(client, GetPlayerLevel(client));
	}
	iWepSelection[client] = 0;
}
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	//PrayerCond[client] = -1;
	//flPrayerCharge[client] = 0.0;
	iPlayerLevel[client] = 0;
	iWepSelection[client] = 0;
	if (IsValidEntity(client)) TF2Attrib_RemoveAll(client);
}
public void OnMapStart()
{
	CreateTimer(advert_timer.FloatValue, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, RegenSpells, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, PlayerTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public void OnClientCookiesCached(int client)
{
	if (!IsFakeClient(client) && IsClientInGame(client)) LevelUp(client, GetPlayerLevel(client));
}
public int GetPlayerLevel(int client)
{
	if (IsFakeClient(client)) return 0;
	char playerlevelz[32];
	GetClientCookie(client, LvlCookie, playerlevelz, sizeof(playerlevelz));
	return StringToInt(playerlevelz);
}
public void SetPlayerLevel(int client, int lvl)
{
	if (IsFakeClient(client)) return;
	char playerlevl[32];
	IntToString(lvl, playerlevl, sizeof(playerlevl));
	SetClientCookie(client, LvlCookie, playerlevl);
}

public Action Timer_Announce(Handle hTimer)
{
	if (rs_enable.BoolValue) CPrintToChatAll("{orange}[RPG Fortress] {default}type {green}!rpg{default} to access menu");
        return Plugin_Continue;
}
public void OnConfigsExecuted()
{
	if (rs_enable.BoolValue) 
	{
		TagsCheck("runescape, rs, rpg", true);
#if defined _steamtools_included
        	if (steamtools)
        	{
			char gameDesc[64];
			Format(gameDesc, sizeof(gameDesc), "RPG Fortress (%s)", PLUGIN_VERSION);
			Steam_SetGameDescription(gameDesc);
        	}
#endif
	}
}
public void cvarChange_Tags(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (rs_enable.BoolValue) TagsCheck("runescape, rs, rpg", false);
}
public void OnLibraryAdded(const char[] name)
{
#if defined _steamtools_included
	if (strcmp(name, "SteamTools", false) == 0)
                steamtools = true;
#endif
}
public void OnLibraryRemoved(const char[] name)
{
#if defined _steamtools_included
	if (!strcmp(name, "SteamTools", false)) steamtools = false;
#endif
}
/*
new sgShieldProp = CreateEntityByName("prop_dynamic");
float tempVec[3] = {0.0,...}; //vector to teleport it to
DispatchKeyValue(sgShieldProp, "model", "models/buildables/sentry_shield.mdl");
DispatchKeyValue(sgShieldProp, "skin", "0"); //0 is red, 1 is blu
DispatchSpawn(sgShieldProp);
TeleportEntity(sgShieldProp, tempVec, NULL_VECTOR, NULL_VECTOR);
AcceptEntityInput(sgShieldProp, "TurnOn");
*/
public void OnPreThink(int client) //powers the HUD
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || !rs_enable.BoolValue) return;
	UpdateHud(client);
}
public void UpdateHud(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (iPlayerExp[client] >= iPlayerExpMax[client] && iPlayerLevel[client] < cvar_level_max.IntValue)
			LevelUp(client, iPlayerLevel[client]+1);

		SetHudTextParams(0.14, 0.80, 1.0, 100, 200, 255, 150);
		ShowSyncHudText(client, hudLevel, "Level: %i", iPlayerLevel[client]);
		SetHudTextParams(0.14, 0.83, 1.0, 255, 200, 100, 150);

		if (iPlayerLevel[client] >= cvar_level_max.IntValue)
			ShowSyncHudText(client, hudEXP, "Max Level Reached");

		else ShowSyncHudText(client, hudEXP, "Exp: %i/%i", iPlayerExp[client], iPlayerExpMax[client]);

		//SetHudTextParams(0.14, 0.75, 1.0, 100, 200, 255, 150);
		//new showpray = RoundFloat(flPrayerCharge[client]);
		//ShowSyncHudText(client, Prayertext, "Prayer Charge: %i", showpray);
	}
}
public Action CommandSetLevels(int client, int args)
{
	if (rs_enable.BoolValue)
	{
		if (args < 2)
		{
			ReplyToCommand(client, "[VSH Engine] Usage: rpg_setlvl <target> <lvl>");
			return Plugin_Handled;
		}
		char s2[80];
		char targetname[PLATFORM_MAX_PATH];
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
		for (int i = 0; i < target_count; i++)
		{
			if (!IsValidClient(target_list[i])) continue;
			SetPlayerLevel(target_list[i], points);
			LevelUp(target_list[i], points);
		}
	}
	return Plugin_Handled;
}
public Action RS_Menu(int client, int args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && rs_enable.BoolValue)
	{
		Menu mainmenu = new Menu(MenuHandler_RS1);
		//Handle MainMenu = CreateMenu(MenuHandler_RS1);

		mainmenu.SetTitle("Main Menu - Choose Category:");
		mainmenu.AddItem("pick_weapon", "Choose a Weapon");
		//AddMenuItem(MainMenu, "pick_prayer", "Choose a Prayer");
	       
		mainmenu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}
public int MenuHandler_RS1(Menu menu, MenuAction action, int client, int param2)
{  
	char info[32];
	menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select) MenuChooseWeapon(client);
	else if (action == MenuAction_End) delete menu;
}
/*public Action Prayer_Menu(client, args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && rs_enable.BoolValue)
        {
		Handle prayMenu = CreateMenu(MenuHandler_Prayer);
 
                SetMenuTitle(prayMenu, "Select Your Prayer; press +attack3 to activate Prayer!");
                AddMenuItem(prayMenu, "none", "Select No Prayer");
                AddMenuItem(prayMenu, "meleeprtct", "Protect from Melee");
                AddMenuItem(prayMenu, "rangedprtct", "Protect from Ranged");
                AddMenuItem(prayMenu, "magicprtct", "Protect from Magic");
                AddMenuItem(prayMenu, "critimmunity", "Immunity from Crits");
		SetMenuExitBackButton(prayMenu, true);
               
                DisplayMenu(prayMenu, client, MENU_TIME_FOREVER);
        }
	return Plugin_Handled;
}
public MenuHandler_Prayer(Handle:menu, MenuAction action, client, param2)
{
	new String:info6[32];
	GetMenuItem(menu, param2, info6, sizeof(info6));
	if (action == MenuAction_Select)
        {
                param2++;
		switch (param2)
		{
			case 1: PrayerCond[client] = -1;
			case 2: PrayerCond[client] = int:TFCond_SmallBulletResist;
			case 3: PrayerCond[client] = int:TFCond_SmallBlastResist;
			case 4: PrayerCond[client] = int:TFCond_SmallFireResist;
			case 5: PrayerCond[client] = int:TFCond_DefenseBuffed;
		}
        }
	else if (action == MenuAction_End)
        {
                CloseHandle(menu);
        }
}*/
public void MenuChooseWeapon(int client)
{
        if (client && IsValidClient(client) && IsPlayerAlive(client))
        {
		TFClassType class = TF2_GetPlayerClass(client);
		switch (class)
		{
			case TFClass_Sniper:
			{
				Menu WepMenu = new Menu(MenuHandler_GiveRangeWep);
				WepMenu.SetTitle("Choose Your Ranged Weapon: ");
				WepMenu.AddItem("huntsman", "Huntsman: Headshottable Arrows");
				WepMenu.AddItem("cleaver", "Cleavers: Fast Fire Rate Throwables");
				WepMenu.AddItem("crossbow", "Crossbow: X-bow that can heal teammates");
				WepMenu.AddItem("cannon", "Cannon: Arced, High Damage Cannonballs");
				WepMenu.Display(client, MENU_TIME_FOREVER);
			}
			case TFClass_Soldier:
			{
				Menu WepMenu = new Menu(MenuHandler_GiveMeleeWep);    
				WepMenu.SetTitle("Choose Your Melee Weapon:");
				WepMenu.AddItem("bbasher", "Boston Basher: +20% firing speed, 3+ hp regen");
				WepMenu.AddItem("pan", "Frying Pan: -20% damage penalty, +50% fire rate");
				WepMenu.AddItem("3rune", "Three-Rune Blade: +25% damage bonus");
				WepMenu.AddItem("ham", "Ham Shank (Pan Reskin): -20% damage penalty, +60% fire rate");
				WepMenu.AddItem("equalizer", "The Equalizer: deal more damage as your health lowers");
				WepMenu.AddItem("katana", "Half-Katana: On Hit: +40 hp");
				WepMenu.AddItem("maul", "Obsidian Maul: +125% damage bonus, 70% slower fire rate");
				WepMenu.AddItem("scimmy", "Scimitar: +30% fire rate");
				WepMenu.AddItem("axting", "Axtinguisher: On Hit: Ignite enemy");
				WepMenu.Display(client, MENU_TIME_FOREVER);
			}
			case TFClass_Medic:
		        {
				Menu WepMenu = new Menu(MenuHandler_GiveMageWep);
				WepMenu.SetTitle("Choose Your Magic Spell:");
				WepMenu.AddItem("banner", "Fireballs");
				WepMenu.AddItem("shrtcrcuit", "Electric Bolts");
				WepMenu.AddItem("backup", "Hellfire Missiles");
				WepMenu.Display(client, MENU_TIME_FOREVER);
		        }
		}
        }
}
public int MenuHandler_GiveRangeWep(Menu menu, MenuAction action, int client, int param2)
{
        char info2[32];
	menu.GetItem(param2, info2, sizeof(info2));
        if (action == MenuAction_Select)
        {
		int weapon = -1;
		TF2_RemoveAllWeapons2(client);
		switch (param2)
		{
			case 0:
			{
				weapon = SpawnWeapon(client, "tf_weapon_compound_bow", 56, 100, 5, "6 ; 0.75 ; 2 ; 1.50");
				SetWeaponAmmo(weapon, 100);
		        }
		        case 1:
		        {
		                weapon = SpawnWeapon(client, "tf_weapon_cleaver", 812, 100, 5, "6 ; 0.8");
		                SetWeaponAmmo(weapon, 100);
		        }
			case 2:
		        {
				weapon = SpawnWeapon(client, "tf_weapon_crossbow", 305, 100, 5, "2 ; 2.0");
				SetWeaponAmmo(weapon, 100);
		        }
		        case 3:
		        {
				weapon = SpawnWeapon(client, "tf_weapon_cannon", 996, 100, 5, "466 ; 1 ; 477 ; 1.0 ; 97 ; 0.6 ; 3 ; 0.25 ; 103 ; 3.0 ; 2 ; 1.50");
				SetWeaponAmmo(weapon, 100);
		        }
		}
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		iWepSelection[client] = param2;
                SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 75 ; 252 ; 0");
        }
        else if (action == MenuAction_End) delete menu;
}
public int MenuHandler_GiveMeleeWep(Menu menu, MenuAction action, int client, int param2)
{
        char info3[32];
	menu.GetItem( param2, info3, sizeof(info3) );
        if (action == MenuAction_Select)
        {
                TF2_RemoveAllWeapons2(client);
		switch (param2)
		{
			case 0: SpawnWeapon(client, "tf_weapon_shovel", 325, 100, 5, "6 ; 0.80 ; 57 ; 3.0");//boston basher
			case 1: SpawnWeapon(client, "tf_weapon_shovel", 264, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//pan
			case 2: SpawnWeapon(client, "tf_weapon_shovel", 452, 100, 5, "2 ; 1.25");//3-rune blade
			case 3: SpawnWeapon(client, "tf_weapon_shovel", 1013, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//ham
			case 4: SpawnWeapon(client, "tf_weapon_shovel", 128, 100, 5, "115 ; 1.0");//equalizer
			case 5: SpawnWeapon(client, "tf_weapon_shovel", 357, 100, 5, "16 ; 40");//katana
			case 6: SpawnWeapon(client, "tf_weapon_shovel", 466, 100, 5, "2 ; 2.25 ; 5 ; 1.70");//maul
			case 7: SpawnWeapon(client, "tf_weapon_shovel", 404, 100, 5, "6 ; 0.70");//persian persuader
			case 8: SpawnWeapon(client, "tf_weapon_shovel", 38, 100, 5, "208 ; 1.0");//axtinguisher
		}
		iWepSelection[client] = param2;
                SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 252 ; 0");
        }
        else if (action == MenuAction_End) delete menu;
}
public int MenuHandler_GiveMageWep(Menu menu, MenuAction action, int client, int param2)
{
        char info4[32];
	menu.GetItem( param2, info4, sizeof(info4) );
	if (action == MenuAction_Select)
	{
/*
spell list
0 Fireball
1 Missile thingy (bats)
2 Ubercharge - healing aura
3 Bomb
4 Super Jump
5 Invisible
6 Teleport
7 Electric Bolt
8 Small body, big head, speed
9 TEAM MONOCULUS
10 Meteor Shower
11 Skeleton Army (Spawns 3)
*/
		TF2_RemoveAllWeapons2(client);
		if (IsValidEntity( FindPlayerBack(client, iRemoveItems, sizeof(iRemoveItems)) ))
			RemovePlayerBack(client, iRemoveItems, sizeof(iRemoveItems));

		int weapon = -1;
		switch (param2)
		{
			case 0:
			{
				SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
				SetSpell(client, 0, 0); //fireball
				weapon=SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
			}
			case 1:
			{
				SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
				SetSpell(client, 7, 0); //electrical orb
				weapon=SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
			}
			case 2:
			{
				SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
				SetSpell(client, 1, 0); //hellfire missiles
				weapon=SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
			}
		}
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		iWepSelection[client] = param2;
		SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 2.0 ; 26 ; 25 ; 252 ; 0");
	}
	else if (action == MenuAction_End) delete menu;
}
public Action PlayerTimer(Handle hTimer)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsPlayerAlive(client)) continue;
		if (TF2_IsPlayerInCondition(client, TFCond_Bleeding)) TF2_RemoveCondition(client, TFCond_Bleeding);
		TFClassType class = TF2_GetPlayerClass(client);
		switch (class)
		{
			//case TFClass_Engineer: SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(player_speed_engineer));
			case TFClass_Medic: SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", player_speed_medic.FloatValue);
			case TFClass_Sniper: SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", player_speed_sniper.FloatValue);
			case TFClass_Soldier: SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", player_speed_soldier.FloatValue);
		}
		//new buttons = GetClientButtons(client);
		//if ((buttons & IN_ATTACK3) && !IsFakeClient(client)) ActivatePrayer(GetClientUserId(client));
		//else if (!(buttons & IN_ATTACK3) || !IsPlayerAlive(client)) DeactivatePrayer(GetClientUserId(client));
	}
	return Plugin_Continue;
}
stock void TF2_RemoveWeaponSlot2(int client, int slot)
{
	int ew, weaponIndex;
	while ((weaponIndex = GetPlayerWeaponSlot(client, slot)) != -1)
	{ 
		ew = GetEntPropEnt(weaponIndex, Prop_Send, "m_hExtraWearable");
		if (IsValidEntity(ew)) TF2_RemoveWearable(client, ew);
		ew = GetEntPropEnt(weaponIndex, Prop_Send, "m_hExtraWearableViewModel");
		if (IsValidEntity(ew)) TF2_RemoveWearable(client, ew);
		RemovePlayerItem(client, weaponIndex);
		AcceptEntityInput(weaponIndex, "Kill");
	} 
}
stock void TF2_RemoveAllWeapons2(int client)
{
	for (int i = 0; i <= 5; i++)
	{
		TF2_RemoveWeaponSlot2(client, i);
	}
}
public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (rs_enable.BoolValue)
	{
		int client = GetClientOfUserId( event.GetInt("userid") );
		if (client && IsClientInGame(client))
		{
			TF2Attrib_RemoveAll(client);
			TFClassType playerclass = TF2_GetPlayerClass(client);
			switch (playerclass)
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
				case TFClass_Soldier: TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
				//case TFClass_Engineer:
				//{
				//	TF2_SetPlayerClass(client, TFClass_Engineer, _, false);
				//	SetEntProp(client, Prop_Data, "m_iAmmo", 500, 4, 3);
				//}

		                case TFClass_Medic: TF2_SetPlayerClass(client, TFClass_Medic, _, false);
		                case TFClass_Sniper: TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
		        }
		        TF2_RemoveAllWeapons2(client);
			TFClassType equipclass = TF2_GetPlayerClass(client);
			int weapon = -1;
			switch (equipclass)
			{
				case TFClass_Soldier:
				{
					switch (iWepSelection[client])
					{
						case 0: weapon=SpawnWeapon(client, "tf_weapon_shovel", 325, 100, 5, "6 ; 0.80 ; 57 ; 3.0");//boston basher
						case 1: weapon=SpawnWeapon(client, "tf_weapon_shovel", 264, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//pan
						case 2: weapon=SpawnWeapon(client, "tf_weapon_shovel", 452, 100, 5, "2 ; 1.25");//3-rune blade
						case 3: weapon=SpawnWeapon(client, "tf_weapon_shovel", 1013, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//ham
						case 4: weapon=SpawnWeapon(client, "tf_weapon_shovel", 128, 100, 5, "115 ; 1.0");//equalizer
						case 5: weapon=SpawnWeapon(client, "tf_weapon_shovel", 357, 100, 5, "16 ; 40");//katana
						case 6: weapon=SpawnWeapon(client, "tf_weapon_shovel", 466, 100, 5, "2 ; 2.25 ; 5 ; 1.70");//maul
						case 7: weapon=SpawnWeapon(client, "tf_weapon_shovel", 404, 100, 5, "6 ; 0.70");//persian persuader
						case 8: weapon=SpawnWeapon(client, "tf_weapon_shovel", 38, 100, 5, "208 ; 1.0");//axtinguisher
					}
					TF2Attrib_SetByDefIndex( client, 57, 5.0 );
					TF2Attrib_SetByDefIndex( client, 252, 0.0 );
				}

				//case TFClass_Engineer:
				//{
				//	SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 50 ; 252 ; 0 ; 80 ; 2.5");
				//	SpawnWeapon(client, "tf_weapon_wrench", 7, 100, 5, "1 ; 0.7 ; 6 ; 0.50 ; 92 ; 1.50"); //wrench
				//}
				case TFClass_Medic:
				{
					if (IsValidEntity( FindPlayerBack(client, iRemoveItems, sizeof(iRemoveItems)) ))
						RemovePlayerBack(client, iRemoveItems, sizeof(iRemoveItems));
					switch (iWepSelection[client])
					{
						case 0:
						{
							SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
							SetSpell(client, 0, 0); //fireball
							weapon=SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
						}
						case 1:
						{
							SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
							SetSpell(client, 7, 0); //electrical orb
							weapon=SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
						}
						case 2:
						{
							SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
							SetSpell(client, 1, 0); //hellfire missiles
							weapon=SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
						}
					}
					TF2Attrib_SetByDefIndex( client, 26, 50.0 );
					TF2Attrib_SetByDefIndex( client, 57, 2.0 );
					TF2Attrib_SetByDefIndex( client, 252, 0.0 );
				}
				case TFClass_Sniper:
				{
					switch (iWepSelection[client])
					{
						case 0:
						{
							weapon = SpawnWeapon(client, "tf_weapon_compound_bow", 56, 100, 5, "6 ; 0.75 ; 2 ; 1.50");
							SetWeaponAmmo(weapon, 100);
						}
						case 1:
						{
							weapon = SpawnWeapon(client, "tf_weapon_cleaver", 812, 100, 5, "6 ; 0.8");
							SetWeaponAmmo(weapon, 100);
						}
						case 2:
						{
							weapon = SpawnWeapon(client, "tf_weapon_crossbow", 305, 100, 5, "2 ; 2.0");
							SetWeaponAmmo(weapon, 100);
						}
						case 3:
						{
							weapon = SpawnWeapon(client, "tf_weapon_cannon", 996, 100, 5, "466 ; 1 ; 477 ; 1.0 ; 97 ; 0.6 ; 3 ; 0.25 ; 103 ; 3.0 ; 2 ; 1.50");
							SetWeaponAmmo(weapon, 100);
						}
					}
					TF2Attrib_SetByDefIndex( client, 26, 75.0 );
					TF2Attrib_SetByDefIndex( client, 57, 5.0 );
					TF2Attrib_SetByDefIndex( client, 252, 0.0 );
				}
			}
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
			TF2_AddCondition(client, TFCond_Ubercharged, 3.0);
			SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth"));
			//flPrayerCharge[client] = 100.0;
			//CreateTimer(0.1, PlayerTimer, GetClientUserId(client), TIMER_REPEAT);
			//CreateTimer(GetConVarFloat(prayer_charge_timer), Timer_PrayerRegen, GetClientUserId(client), TIMER_REPEAT);
			RS_Menu(client, -1);
		}
        }
        return Plugin_Continue;
}
public Action EventClassChange(Event event, const char[] name, bool dontBroadcast)
{
        if (rs_enable.BoolValue)
        {
                int client = GetClientOfUserId( event.GetInt("userid") );
		if (client && IsClientInGame(client))
		{
		        TFClassType changeclass = TF2_GetPlayerClass(client);
		        switch (changeclass)
		        {
		                case TFClass_Scout, TFClass_Pyro, TFClass_Heavy, TFClass_DemoMan, TFClass_Spy, TFClass_Engineer:
					switch ( GetRandomInt(0, 2) )
					{
						case 0: TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
						case 1: TF2_SetPlayerClass(client, TFClass_Medic, _, false);
						case 2: TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
					}
				case TFClass_Soldier:
					if (TF2_GetPlayerClass(client) != TFClass_Soldier)
						TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
		                case TFClass_Sniper:
		                        if (TF2_GetPlayerClass(client) != TFClass_Sniper)
		                                TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
		                case TFClass_Medic:
		                        if (TF2_GetPlayerClass(client) != TFClass_Medic)
		                                TF2_SetPlayerClass(client, TFClass_Medic, _, false);
		        }
			TF2_RemovePlayerDisguise(client);
		}
        }
        return Plugin_Continue;
}
public Action EventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (rs_enable.BoolValue)
	{
		int client = GetClientOfUserId( event.GetInt("userid") );
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (!client || !attacker) return Plugin_Continue;

		//flPrayerCharge[client] = 0.0;

		if (attacker != client && cvar_exp_onkill.IntValue >= 1 && iPlayerLevel[attacker] < cvar_level_max.IntValue)
		{
			iPlayerExp[attacker] += cvar_exp_onkill.IntValue;
			SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
			ShowSyncHudText(attacker, hudPlus2, "+%i", cvar_exp_onkill.IntValue);
		}
	}
        return Plugin_Continue;
}
public Action EventPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (rs_enable.BoolValue)
	{
                int client = GetClientOfUserId( event.GetInt("userid") );
                int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int rawDamage = event.GetInt("damageamount");
                if (!client || !attacker || client == attacker) return Plugin_Continue;

		float percent = cvar_exp_ondmg.FloatValue;
		float dmg = rawDamage*percent;
		
		if ( !(dmg <= 0.0) && attacker != client && iPlayerLevel[attacker] < cvar_level_max.IntValue )
		{
			iPlayerExp[attacker] += RoundFloat(dmg);
			SetHudTextParams(0.24, 0.93, 1.0, 255, 100, 100, 150, 1);
			ShowSyncHudText(attacker, hudPlus1, "+%i", RoundFloat(dmg));
		}
	}
        return Plugin_Continue;
}
public Action EventInventApp(Event event, const char[] name, bool dontBroadcast)
{
	if (rs_enable.BoolValue)
	{
		int client = GetClientOfUserId( event.GetInt("userid") );
		if (client && IsClientInGame(client))
		{
			TF2Attrib_RemoveAll(client);
			TF2_RemoveAllWeapons2(client);
			int weapon = -1;
			TFClassType equipclass = TF2_GetPlayerClass(client);
			switch (equipclass)
			{
				case TFClass_Soldier:
				{
					switch (iWepSelection[client])
					{
						case 0: weapon=SpawnWeapon(client, "tf_weapon_shovel", 325, 100, 5, "6 ; 0.80 ; 57 ; 3.0");//boston basher
						case 1: weapon=SpawnWeapon(client, "tf_weapon_shovel", 264, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//pan
						case 2: weapon=SpawnWeapon(client, "tf_weapon_shovel", 452, 100, 5, "2 ; 1.25");//3-rune blade
						case 3: weapon=SpawnWeapon(client, "tf_weapon_shovel", 1013, 100, 5, "1 ; 0.8 ; 6 ; 0.50");//ham
						case 4: weapon=SpawnWeapon(client, "tf_weapon_shovel", 128, 100, 5, "115 ; 1.0");//equalizer
						case 5: weapon=SpawnWeapon(client, "tf_weapon_shovel", 357, 100, 5, "16 ; 40");//katana
						case 6: weapon=SpawnWeapon(client, "tf_weapon_shovel", 466, 100, 5, "2 ; 2.25 ; 5 ; 1.70");//maul
						case 7: weapon=SpawnWeapon(client, "tf_weapon_shovel", 404, 100, 5, "6 ; 0.70");//persian persuader
						case 8: weapon=SpawnWeapon(client, "tf_weapon_shovel", 38, 100, 5, "208 ; 1.0");//axtinguisher
					}
					TF2Attrib_SetByDefIndex( client, 57, 5.0 );
					TF2Attrib_SetByDefIndex( client, 252, 0.0 );
				}

				//case TFClass_Engineer:
				//{
				//	SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 50 ; 252 ; 0 ; 80 ; 2.5");
				//	SpawnWeapon(client, "tf_weapon_wrench", 7, 100, 5, "1 ; 0.7 ; 6 ; 0.50 ; 92 ; 1.50"); //wrench
				//}
				case TFClass_Medic:
				{
					if (IsValidEntity( FindPlayerBack(client, iRemoveItems, sizeof(iRemoveItems)) ))
						RemovePlayerBack(client, iRemoveItems, sizeof(iRemoveItems));
					switch (iWepSelection[client])
					{
						case 0:
						{
							SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
							SetSpell(client, 0, 0); //fireball
							weapon=SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
						}
						case 1:
						{
							SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
							SetSpell(client, 7, 0); //electrical orb
							weapon=SpawnWeapon(client, "tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
						}
						case 2:
						{
							SpawnWeapon(client, "tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
							SetSpell(client, 1, 0); //hellfire missiles
							weapon=SpawnWeapon(client, "tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
						}
					}
					TF2Attrib_SetByDefIndex( client, 26, 50.0 );
					TF2Attrib_SetByDefIndex( client, 57, 2.0 );
					TF2Attrib_SetByDefIndex( client, 252, 0.0 );
				}
				case TFClass_Sniper:
				{
					switch (iWepSelection[client])
					{
						case 0:
						{
							weapon = SpawnWeapon(client, "tf_weapon_compound_bow", 56, 100, 5, "6 ; 0.75 ; 2 ; 1.50");
							SetWeaponAmmo(weapon, 100);
						}
						case 1:
						{
							weapon = SpawnWeapon(client, "tf_weapon_cleaver", 812, 100, 5, "6 ; 0.8");
							SetWeaponAmmo(weapon, 100);
						}
						case 2:
						{
							weapon = SpawnWeapon(client, "tf_weapon_crossbow", 305, 100, 5, "2 ; 2.0");
							SetWeaponAmmo(weapon, 100);
						}
						case 3:
						{
							weapon = SpawnWeapon(client, "tf_weapon_cannon", 996, 100, 5, "466 ; 1 ; 477 ; 1.0 ; 97 ; 0.6 ; 3 ; 0.25 ; 103 ; 3.0 ; 2 ; 1.50");
							SetWeaponAmmo(weapon, 100);
						}
					}
					TF2Attrib_SetByDefIndex( client, 26, 75.0 );
					TF2Attrib_SetByDefIndex( client, 57, 5.0 );
					TF2Attrib_SetByDefIndex( client, 252, 0.0 );
				}
			}
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
			SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth"));
		}
	}
	return Plugin_Continue;
}
/*public Action Event_player_builtobject(Event event, const char[] name, bool dontBroadcast)
{
        if (rs_enable.BoolValue)
        {
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
        }
        return Plugin_Continue;
}*/

/*public Action Timer_PrayerRegen(Handle:hTimer, any:userid) //prayer
{
	new client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) return Plugin_Stop;
	if (!IsPlayerAlive(client)) return Plugin_Stop;

	if (!TF2_IsPlayerInCondition(client, TFCond_SmallBulletResist) || !TF2_IsPlayerInCondition(client, TFCond_SmallBlastResist) || !TF2_IsPlayerInCondition(client, TFCond_SmallFireResist) || !TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
	{
		flPrayerCharge[client] += GetConVarFloat(PrayerCharge);
		if (flPrayerCharge[client] > 100.0) flPrayerCharge[client] = 100.0;
	}
        return Plugin_Continue;
}
public ActivatePrayer(userid) //activates prayer
{
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (PrayerCond[client] != -1)
		{
			TF2_AddCondition(client, TFCond:PrayerCond[client], 0.3);
			flPrayerCharge[client] -= 0.3;
			if (flPrayerCharge[client] <= 0.0)
			{
				DeactivatePrayer(userid);
				CPrintToChat(client, "{red}Prayer Charge Depleted!");
				return;
			}
		}
		else if (PrayerCond[client] == -1)
		{
			CPrintToChat(client, "{red}You do not have a Prayer set! type !rpg to set it");
			return;
		}
	}
        return;
}
public DeactivatePrayer(userid) //deactivates prayer obviously
{
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && PrayerCond[client] != -1)
	{
		TF2_RemoveCondition(client, TFCond:PrayerCond[client]);
		if (flPrayerCharge[client] <= 0.0) flPrayerCharge[client] = 0.0;
	}
	return;
}*/
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (rs_enable.BoolValue && attacker > 0 && victim != attacker)
        {
                if (damagetype & DMG_CRIT)
		{
			damage /= 1.5;
			return Plugin_Changed;
		}
		if (TF2_GetPlayerClass(attacker) == TFClass_Medic)
		{
			int spellbook = FindSpellbook(attacker);
			if (GetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex") != 1)
			{
				damage *= 0.7;
				return Plugin_Changed;
			}
		}
		/*if (TF2_IsPlayerInCondition(victim, TFCond_SmallBulletResist) && weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
		{
			damage *= GetConVarFloat(cvar_prayer_melee_dmgreduce);
			return Plugin_Changed;
		}
		else if (TF2_IsPlayerInCondition(victim, TFCond_SmallBlastResist) && TF2_GetPlayerClass(attacker) == TFClass_Sniper)
		{
			damage *= GetConVarFloat(cvar_prayer_ranged_dmgreduce);
			return Plugin_Changed;
		}
		else if (TF2_IsPlayerInCondition(victim, TFCond_SmallFireResist) && TF2_GetPlayerClass(attacker) == TFClass_Medic)
		{
			damage *= GetConVarFloat(cvar_prayer_magic_dmgreduce);
			return Plugin_Changed;
		}
		else if (TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) && !(damagetype & DMG_CRIT))
		{
			damage *= 1.54; //forces player to take normal damage if not crit
			return Plugin_Changed;
		}*/

                /*decl Float:vec1[3]; this is for other crap
                decl Float:vec2[3];
                GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", vec1); //Spot of attacker
                GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vec2); //Spot of victim
                float dist = GetVectorDistance(vec1, vec2, false); //Calculates the distance between target and attacker*/
 
		//new String:classname[64];
		//if (IsValidEdict(weapon)) GetEdictClassname(weapon, classname, sizeof(classname));
 
/*
----range damage formula used in runescape

ES is the effective strength
R = range level after potions if there are potions
P = prayer bonuses (e.g. hawk eye)
O = other bonuses, focus sight or full slayer helm
V = void bonuses (if ur using void range)
V = floor(R/5+1.6)
ES = floor(R*P*O)+V
RS = ranged strength (I replace this variable with damage)
Max Hit = 5+((ES+8)*(RS+64)/64)
 
----melee damage formula used in runescape

S = strength level (if your strenght is 95 and u used a potion and ur strength is 102, use S=102)
P = prayer bonuses (e.g. burst of strength)
O = other bonuses(void melee, black mask, salve amulet)
ES = func(S*P*O)
SB = strength bonus
Max Hit = 13+ES+(SB/8)+(ES*SB/64)
*/
        }
	return Plugin_Continue;
}
stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2 = 0;
		for (int i = 0; i < count; i+= 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon == null) return -1;
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	hWeapon.Close();
	EquipPlayerWeapon(client, entity);
	return entity;
}
public Action RegenSpells(Handle lTimer)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || TF2_GetPlayerClass(client) != TFClass_Medic) continue;
		int spellbook = FindSpellbook(client);

		//Adds 1 spell
		if ( IsValidEntity(spellbook) && flSpell[client] < GetGameTime() )
		{
			if (GetSpellCharges(spellbook) == 1) continue;
			float flCooldown;
			int warlock = GetSpellIndex(spellbook);
			switch (warlock)
			{
				case 0: flCooldown = cvar_fireball_recharge.FloatValue;
				case 7: flCooldown = cvar_electric_recharge.FloatValue;
				case 1: flCooldown = cvar_hellfire_recharge.FloatValue;
			}
			flSpell[client] = GetGameTime() + flCooldown;
		        SetSpellCharges(spellbook, GetSpellCharges(spellbook)+1);
		        if ( GetSpellCharges(spellbook) > 1 ) SetSpellCharges(spellbook, 1);
		}
	}
        return Plugin_Continue;
}
stock int GetSpellIndex(int book)
{
	if (IsValidEntity(book)) return GetEntProp(book, Prop_Send, "m_iSelectedSpellIndex");
	return 0;
}
stock void SetSpellIndex(int book, int spell)
{
	if (IsValidEntity(book)) SetEntProp(book, Prop_Send, "m_iSelectedSpellIndex", spell);
}

stock int GetSpellCharges(int book)
{
	if (IsValidEntity(book)) return GetEntProp(book, Prop_Send, "m_iSpellCharges");
	return 0;
}
stock void SetSpellCharges(int book, int amount)
{
	if (IsValidEntity(book)) SetEntProp(book, Prop_Send, "m_iSpellCharges", amount);
}
stock void SetSpell(int client, int spell, int charge)
{
	int spellbook = FindSpellbook(client);
	if (spellbook == -1) LogError("[RPG Fortress] ErMac: Spellbook Assignment Failure!");
	else
        {
		SetSpellCharges(spellbook, charge);
		if (spell >= 0) SetSpellIndex(spellbook, spell);
        }
}
stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck) if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
stock void RemovePlayerBack(int client, int[] indices, int len)
{
	if (len <= 0) return;
	int edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int idx = GetItemIndex(edict);
			if (GetOwner(edict) == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (int i = 0; i < len; i++)
				{
					if (idx == indices[i]) TF2_RemoveWearable(client, edict);
				}
			}
		}
	}
	edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_powerup_bottle")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
		{
			int idx = GetItemIndex(edict);
			if (GetOwner(edict) == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (int i = 0; i < len; i++)
				{
					if (idx == indices[i]) TF2_RemoveWearable(client, edict);
				}
			}
		}
	}
}
stock int FindPlayerBack(int client, int[] indices, int len)
{
	if (len <= 0) return -1;
	int edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int idx = GetItemIndex(edict);
			if (GetOwner(edict) == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (int i = 0; i < len; i++)
				{
					if (idx == indices[i]) return edict;
				}
			}
		}
	}
	edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_powerup_bottle")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFPowerupBottle"))
		{
			int idx = GetItemIndex(edict);
			if (GetOwner(edict) == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (int i = 0; i < len; i++)
				{
					if (idx == indices[i]) return edict;
				}
			}
		}
	}
	return -1;
}
stock int GetItemIndex(int item)
{
	if (IsValidEdict(item) && IsValidEntity(item)) return GetEntProp(item, Prop_Send, "m_iItemDefinitionIndex");
	return -1;
}
stock int GetOwner(int ent)
{
	if ( IsValidEdict(ent) && IsValidEntity(ent) ) return GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	return -1;
}
stock void TagsCheck(const char[] tag, bool remove = false) //DarthNinja
{
        ConVar hTags = FindConVar("sv_tags");
        char tags[255];
        hTags.GetString(tags, sizeof(tags)); //GetConVarString(hTags, tags, sizeof(tags));
 
        if (StrContains(tags, tag, false) == -1 && !remove)
        {
		char newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		ReplaceString(newTags, sizeof(newTags), ",,", ",", false);
		hTags.SetString(newTags); //SetConVarString(hTags, newTags);
		hTags.GetString(tags, sizeof(tags)); //GetConVarString(hTags, tags, sizeof(tags));
        }
        else if (StrContains(tags, tag, false) > -1 && remove)
        {
                ReplaceString(tags, sizeof(tags), tag, "", false);
                ReplaceString(tags, sizeof(tags), ",,", ",", false);
                hTags.SetString(tags); //SetConVarString(hTags, tags);
        }
	hTags.Close();
//      CloseHandle(hTags);
}
stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
stock int FindSpellbook(int client)
{
        int i = -1;
        while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1)
        {
                if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon")) return i;
        }
        return -1;
}
stock void ClearTimer(Handle &Timer)
{
	if (Timer != null)
	{
		Timer.Close();
		Timer = null;
	}
}
stock void LevelUp(int client, int level)
{
	iPlayerLevel[client] = level;
	SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
	ShowSyncHudText(client, hudLevelUp, "LEVEL UP!");
	SetPlayerLevel(client, level);
	//int total = cvar_exp_default.IntValue;
	int total = 0;
	for (int i = 1; i < level; i++)
	{
		total += RoundToFloor(i+75.0 * Pow(2.0, i/7.0));
	}
	iPlayerExpMax[client] = total;
	if (level >= cvar_level_max.IntValue) iPlayerExpMax[client] = 0;
}
stock int GetWeaponAmmo(int armament)
{
	int owner = GetEntPropEnt(armament, Prop_Send, "m_hOwnerEntity");
	if (owner <= 0) return 0;
	if (IsValidEntity(armament))
	{
		int iOffset = GetEntProp(armament, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(owner, iAmmoTable+iOffset, 4);
	}
	return 0;
}
stock int GetWeaponClip(int armament)
{
	if (IsValidEntity(armament))
	{
		int AmmoClipTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		return GetEntData(armament, AmmoClipTable);
	}
	return 0;
}
stock void SetWeaponAmmo(int armament, int ammo)
{
	int owner = GetEntPropEnt(armament, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	if (IsValidEntity(armament))
	{
		int iOffset = GetEntProp(armament, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(owner, iAmmoTable+iOffset, ammo, 4, true);
	}
	return;
}
stock void SetWeaponClip(int armament, int ammo)
{
	if (IsValidEntity(armament))
	{
		int iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(armament, iAmmoTable, ammo, 4, true);
	}
	return;
}
stock int GetMaxAmmo(int client, int slot)
{
	if (!IsValidClient(client)) return 0;
	int armament = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(armament))
	{
		switch (slot)
		{
			case TFWeaponSlot_Primary: return GetEntData(client, FindDataMapOffs(client, "m_iAmmo")+4);
			case TFWeaponSlot_Secondary: return GetEntData(client, FindDataMapOffs(client, "m_iAmmo")+8);
			case TFWeaponSlot_Melee: return GetEntData(client, FindDataMapOffs(client, "m_iAmmo")+12);
		}
	}
	return 0;
}