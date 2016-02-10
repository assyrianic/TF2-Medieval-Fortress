#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>
#include <clientprefs>

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#pragma newdecls			required

/*
**** C R E D I T S ****
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
use levels to add unlockable weapons, spells, and weapon upgrades/additions.

make unlockables use a level percentage depending on the max level attainable

format - "unlocked lvl # - upgrades: lvl #-effect"

knight melees and their upgrades

	boston basher	- unlocked lvl 0 - upgrades: lvl 15-poison, 
	pan		- unlocked lvl 0 - upgrades: lvl #-effect
	3-rune blade	- unlocked lvl # - upgrades: lvl #-effect
	ham		- unlocked lvl # - upgrades: lvl #-effect
	equalizer	- unlocked lvl # - upgrades: lvl #-effect
	katana		- unlocked lvl # - upgrades: lvl #-effect
	maul		- unlocked lvl # - upgrades: lvl #-effect
	pars persuade	- unlocked lvl 40 - upgrades: lvl 50-slowdown on crit, 
	axtinguisher	- unlocked lvl # - upgrades: lvl #-effect

	"Boston Basher: +20% firing speed"
	"Frying Pan: -20% damage penalty, +50% fire rate"
	"Three-Rune Blade: +25% damage bonus"
	"Ham Shank (Pan Reskin): -20% damage penalty, +60% fire rate"
	"The Equalizer: deal more damage as your health lowers"
	"Half-Katana: On Hit: +40 hp"
	"Obsidian Maul: +125% damage bonus, 70% slower fire rate"
	"Scimitar: +30% fire rate"
	"Axtinguisher: On Hit: Ignite enemy"

/////////////////////////

ranger melees and their upgrades

	bow		- unlocked lvl # - upgrades: lvl #-effect
	cleavers	- unlocked lvl # - upgrades: lvl #-effect
	crossbow	- unlocked lvl # - upgrades: lvl #-effect
	cannon		- unlocked lvl # - upgrades: lvl #-effect

	"Huntsman: Headshottable Arrows"
	"Cleavers: Fast Fire Rate Throwables"
	"Crossbow: crossbow that can deal high damage"
	"Cannon: Arc'd, High Damage Cannonballs"

/////////////////////////

mage spells and their upgrades

these are temporary, I'm planning to implement CUSTOM spells... Halloween spells are wayyy too overpowered for this mod.

	fireball	- unlocked lvl # - upgrades: lvl #-effect
	electrical orb	- unlocked lvl # - upgrades: lvl #-effect
	bat missiles	- unlocked lvl # - upgrades: lvl #-effect

	"Fireballs"
	"Electric Bolts"
	"Hellfire Missiles"

*/

/* I D E A S

add an internal mod store to buy supplies such as ammo for magic and projectiles.
add inventory (maybe 5 item inventory?)
give gold on kill or completing map objectives to use for buying shit.


*/

#include "modules/globals.sp"
#include "modules/timers.sp"
#include "modules/stocks.sp"
#include "modules/events.sp"
#include "modules/commands.sp"
#include "modules/menuhandlers.sp"

public Plugin myinfo = {
        name = "RPG Fortress",
        author = "Assyrian/Nergal & others",
        description = "RPG Fortress is an enhancement for Medieval Mode",
        version = PLUGIN_VERSION,
        url = "http://steamcommunity.com/groups/acvsh | http://forums.alliedmods.net/showthread.php?t=230178"
};

public void OnPluginStart()
{
        CreateConVar("rpg_version", PLUGIN_VERSION, "RPG Fortress Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
        rs_enable = CreateConVar("rpg_enabled", "1", "Enables RPG Fortress mod", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	cvar_fireball_recharge = CreateConVar("rpg_fireball_recharge", "4.0", "Every x seconds, 1 fireball spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);
        cvar_hellfire_recharge = CreateConVar("rpg_hellfire_recharge", "3.0", "Every x seconds, 1 hellfire spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);
        cvar_electric_recharge = CreateConVar("rpg_electric_recharge", "8.0", "Every x seconds, 1 electrical bolt spell will be added", FCVAR_PLUGIN|FCVAR_NOTIFY);

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

	player_speed_medic = CreateConVar("rpg_playerspeed_mage", "350.0", "speed of Mages in Hammer units");
	player_speed_sniper = CreateConVar("rpg_playerspeed_ranger", "350.0", "speed of Rangers in Hammer units");
	player_speed_soldier = CreateConVar("rpg_playerspeed_knight", "400.0", "speed of Knights in Hammer units");
	
	LvlCookie = RegClientCookie("rpgfortress_levels", "RPG Fortress Player Levels cookie", CookieAccess_Protected);

        AutoExecConfig(true, "RPGFortressConfig");
       
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

        RegConsoleCmd("sm_rpg", RPGFortressMenu, "RPG Fortress menu");
	RegAdminCmd("sm_rpg_setlvl", CommandSetLevels, ADMFLAG_KICK, "reset all player levels");

	int i;
	//for (int i = 1; i <= MaxClients; i++)
	while ( ++i <= MaxClients )
	{
		if (!IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
}
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	CRPGClass player = CRPGClass(client);

	player.iExp = 0;
	player.iMaxExp = cvar_exp_default.IntValue;
	if (player.iCookyLevel < 1)
	{
		player.iCookyLevel = 1;
		player.DoLevelUp(player.iCookyLevel);
	}
	player.iWeapPick = 0;
}
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);

	CRPGClass player = CRPGClass(client);
	player.iLevel = 0;
	player.iWeapPick = 0;
}
public void OnMapStart()
{
	CreateTimer(advert_timer.FloatValue, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, RegenSpells, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, PlayerTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public void OnClientCookiesCached(int client)
{
	if (!IsFakeClient(client) && IsClientInGame(client))
	{
		CRPGClass player = CRPGClass(client);
		player.DoLevelUp(player.iCookyLevel);
		//LevelUp(client, GetPlayerLevel(client));
	}
}

public void OnConfigsExecuted()
{
	if (!rs_enable.BoolValue) return;

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
public void cvarChange_Tags(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (!rs_enable.BoolValue) return;
	TagsCheck("runescape, rs, rpg", false);
}
public void OnLibraryAdded(const char[] name)
{
#if defined _steamtools_included
	if ( !strcmp(name, "SteamTools", false) ) steamtools = true;
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
	if (!rs_enable.BoolValue) return;
	if ( !IsPlayerAlive(client) ) return;

	CRPGClass player = CRPGClass(client);

	if (player.iExp >= player.iMaxExp && player.iLevel < cvar_level_max.IntValue)
		player.DoLevelUp(player.iLevel+1);

	player.UpdateHud();
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!rs_enable.BoolValue) return Plugin_Continue;

	if (attacker > 0 && victim != attacker)
        {
                if (damagetype & DMG_CRIT) //crits are very powerful, slightly nerf them for this gamemode
		{
			damage /= 1.5;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
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


