
#define PLUGIN_VERSION			"1.5"
#define PLYR				MAXPLAYERS+1

//non-cvar handles---------------------
Handle hudLevel,
	hudEXP,
	hudPlus1,
	hudPlus2,
	hudLevelUp,
	LvlCookie
;

//cvar handles-------------------------
ConVar rs_enable,
	cvar_fireball_recharge,
	cvar_hellfire_recharge,
	cvar_electric_recharge,
	//cvar_exp_levelup,
	cvar_level_max,
	cvar_exp_default,
	cvar_exp_onkill,
	cvar_exp_ondmg,
	player_speed_sniper,
	player_speed_soldier,
	advert_timer,
	player_speed_medic
;

//Handle cvar_level_default;

//floats--------------------------------------------------------------------------------------------------------
float flSpellTime[PLYR];

enum RPGElements
{
	iPlayerLevel = 0,
	iPlayerExp,
	iPlayerExpMax,
};
//ints----------------------------------------------------------------------------------------------------------

int iPlayerInfo[PLYR][RPGElements];
int iWepSelection[PLYR];
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
	1070,
	1132,
	5604,
	30015, //more canteens
	30535
};

methodmap CRPGClass /* the Player character, vital to every RPG! */
{
	public CRPGClass (int index, bool uid = false)
	{
		if (uid) {
			return view_as<CRPGClass>( index );
		}
		return view_as<CRPGClass>( GetClientUserId(index) );
	}

	property int userid {
		public get()				{ return view_as<int>(this); }
	}
	property int index {
		public get()				{ return GetClientOfUserId( this.userid ); }
	} // this.index
	
	property int iLevel
	{
		public get()				{ return iPlayerInfo[ this.index ][ iPlayerLevel ]; }
		public set(int val)			{ iPlayerInfo[ this.index ][ iPlayerLevel ] = val; }
	}
	property int iExp
	{
		public get()				{ return iPlayerInfo[ this.index ][ iPlayerExp ]; }
		public set(int val)			{ iPlayerInfo[ this.index ][ iPlayerExp ] = val; }
	}
	property int iMaxExp
	{
		public get()				{ return iPlayerInfo[ this.index ][ iPlayerExpMax ]; }
		public set(int val)			{ iPlayerInfo[ this.index ][ iPlayerExpMax ] = val; }
	}
	property int iWeapPick
	{
		public get()				{ return iWepSelection[ this.index ]; }
		public set(int val)			{ iWepSelection[ this.index ] = val; }
	}
	property int iCookyLevel
	{
		public get() //GetPlayerLevel
		{
			if ( IsFakeClient(this.index) ) return 0;
			char playerlevelz[32];
			GetClientCookie(this.index, LvlCookie, playerlevelz, sizeof(playerlevelz));
			return StringToInt(playerlevelz);
		}
		public set(int val) //SetPlayerLevel
		{
			if ( !IsFakeClient(this.index) ) {
				char playerlevl[32];
				IntToString(val, playerlevl, sizeof(playerlevl));
				SetClientCookie(this.index, LvlCookie, playerlevl);
			}
		}
	}

	public void DoLevelUp(int level)
	{
		this.iLevel = level;
		SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
		ShowSyncHudText(this.index, hudLevelUp, "LEVEL UP!");
		this.iCookyLevel = level;
		int total = 0;
		for (int i = 1; i < level; ++i)
		{
			total += RoundToFloor(i+75.0 * Pow(2.0, i/7.0));
		}
		this.iMaxExp = total;
		if (level >= cvar_level_max.IntValue) this.iMaxExp = 0;
	}
	public void UpdateHud()
	{
		SetHudTextParams(0.14, 0.80, 1.0, 100, 200, 255, 150);
		ShowSyncHudText(this.index, hudLevel, "Level: %i", this.iLevel);
		SetHudTextParams(0.14, 0.83, 1.0, 255, 200, 100, 150);

		if (this.iLevel >= cvar_level_max.IntValue) ShowSyncHudText(this.index, hudEXP, "Max Level Reached!");
		else ShowSyncHudText(this.index, hudEXP, "Exp: %i/%i", this.iExp, this.iMaxExp);
	}
	public int SpawnWeapon(char[] name, int index, int level, int qual, char[] att)
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
		if ( !hWeapon ) return -1;
		int entity = TF2Items_GiveNamedItem(this.index, hWeapon);
		delete hWeapon;
		EquipPlayerWeapon(this.index, entity);
		return entity;
	}
	public void RemoveBack(int[] indices, int len)
	{
		if (len <= 0) return;
		int edict = MaxClients+1;
		while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
			{
				int idx = GetItemIndex(edict);
				if (GetOwner(edict) == this.index && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
				{
					for (int i = 0; i < len; i++)
					{
						if (idx == indices[i]) TF2_RemoveWearable(this.index, edict);
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
				if (GetOwner(edict) == this.index && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
				{
					for (int i = 0; i < len; i++)
					{
						if (idx == indices[i]) TF2_RemoveWearable(this.index, edict);
					}
				}
			}
		}
	}
	public int FindBack(int[] indices, int len)
	{
		if (len <= 0) return -1;
		int edict = MaxClients+1;
		while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
			{
				int idx = GetItemIndex(edict);
				if (GetOwner(edict) == this.index && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
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
				if (GetOwner(edict) == this.index && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
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
};

methodmap CMageClass < CRPGClass
{
	public CMageClass (int index, bool uid = false)
	{
		if (uid) {
			return view_as<CMageClass>( CRPGClass(index, true) );
		}
		return view_as<CMageClass>( CRPGClass(index) );
	}

	property float flSpell
	{
		public get()				{ return flSpellTime[ this.index ]; }
		public set(float val)			{ flSpellTime[ this.index ] = val; }
	}
	public void MenuChooseWeapon()
	{
		if (IsValidClient(this.index) && IsPlayerAlive(this.index))
		{
			Menu WepMenu = new Menu(MenuHandler_GiveMageWep);
			WepMenu.SetTitle("Choose Your Magic Spell:");
			WepMenu.AddItem("banner", "Fireballs");
			WepMenu.AddItem("shrtcrcuit", "Electric Bolts");
			WepMenu.AddItem("backup", "Hellfire Missiles");
			WepMenu.Display(this.index, MENU_TIME_FOREVER);
		}
	}
	public void Equip()
	{
		if ( IsValidEntity(this.FindBack(iRemoveItems, sizeof(iRemoveItems))) )
			this.RemoveBack(iRemoveItems, sizeof(iRemoveItems));

		int wep = this.iWeapPick;
		clamp(wep, 0, 2);
		this.iWeapPick = wep;
		switch (this.iWeapPick)
		{
			case 0:	//fireball
			{
				this.SpawnWeapon("tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
				SetSpell(this.index, 0, 0); //fireball
				wep = this.SpawnWeapon("tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
			}
			case 1:	//electrical orb
			{
				this.SpawnWeapon("tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
				SetSpell(this.index, 7, 0); //electrical orb
				wep = this.SpawnWeapon("tf_weapon_buff_item", 129, 100, 5, "2 ; 1.0");
			}
			case 2:	//bat missiles
			{
				this.SpawnWeapon("tf_weapon_spellbook", 1069, 100, 5, "2 ; 1.0");
				SetSpell(this.index, 1, 0); //hellfire missiles
				wep = this.SpawnWeapon("tf_weapon_buff_item", 226, 100, 5, "2 ; 1.0");
			}
		}
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", wep);
	}
};

methodmap CKnightClass < CRPGClass
{
	public CKnightClass (int index, bool uid = false)
	{
		if (uid) {
			return view_as<CKnightClass>( CRPGClass(index, true) );
		}
		return view_as<CKnightClass>( CRPGClass(index) );
	}
	public void Equip()
	{
		int wep = this.iWeapPick;
		clamp(wep, 0, 8);
		this.iWeapPick = wep;
		switch (this.iWeapPick) 
		{
			case 0: wep = this.SpawnWeapon("tf_weapon_shovel", 325, 100, 5, "6 ; 0.80 ; 57 ; 3.0");	//boston basher
			case 1: wep = this.SpawnWeapon("tf_weapon_shovel", 264, 100, 5, "1 ; 0.8 ; 6 ; 0.50");	//pan
			case 2: wep = this.SpawnWeapon("tf_weapon_shovel", 452, 100, 5, "2 ; 1.25");		//3-rune blade
			case 3: wep = this.SpawnWeapon("tf_weapon_shovel", 1013, 100, 5, "1 ; 0.8 ; 6 ; 0.50");	//ham
			case 4: wep = this.SpawnWeapon("tf_weapon_shovel", 128, 100, 5, "115 ; 1.0");		//equalizer
			case 5: wep = this.SpawnWeapon("tf_weapon_shovel", 357, 100, 5, "16 ; 40");		//katana
			case 6: wep = this.SpawnWeapon("tf_weapon_shovel", 466, 100, 5, "2 ; 2.25 ; 5 ; 1.70");	//maul
			case 7: wep = this.SpawnWeapon("tf_weapon_shovel", 404, 100, 5, "6 ; 0.70");		//persian persuader
			case 8: wep = this.SpawnWeapon("tf_weapon_shovel", 38, 100, 5, "208 ; 1.0");		//axtinguisher
		}
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", wep);
	}
	public void MenuChooseWeapon()
	{
		if (IsValidClient(this.index) && IsPlayerAlive(this.index))
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
			WepMenu.Display(this.index, MENU_TIME_FOREVER);
		}
	}
};

methodmap CRangerClass < CRPGClass
{
	public CRangerClass (int index, bool uid = false)
	{
		if (uid) {
			return view_as<CRangerClass>( CRPGClass(index, true) );
		}
		return view_as<CRangerClass>( CRPGClass(index) );
	}
	public void MenuChooseWeapon()
	{
		if (IsValidClient(this.index) && IsPlayerAlive(this.index))
		{
			Menu WepMenu = new Menu(MenuHandler_GiveRangeWep);
			WepMenu.SetTitle("Choose Your Ranged Weapon: ");
			WepMenu.AddItem("huntsman", "Huntsman: Headshottable Arrows");
			WepMenu.AddItem("cleaver", "Cleavers: Fast Fire Rate Throwables");
			WepMenu.AddItem("crossbow", "Crossbow: crossbow that can deal high damage");
			WepMenu.AddItem("cannon", "Cannon: Arc'd, High Damage Cannonballs");
			WepMenu.Display(this.index, MENU_TIME_FOREVER);
		}
	}
	public void Equip()
	{
		int wep = this.iWeapPick;
		clamp(wep, 0, 3);
		this.iWeapPick = wep;
		switch (this.iWeapPick)
		{
			case 0: wep = this.SpawnWeapon("tf_weapon_compound_bow", 56, 100, 5, "6 ; 0.75 ; 2 ; 1.50");	//bow
			case 1: wep = this.SpawnWeapon("tf_weapon_cleaver", 812, 100, 5, "6 ; 0.85");			//cleavers
			case 2: wep = this.SpawnWeapon("tf_weapon_crossbow", 305, 100, 5, "2 ; 2.0");			//crossbow
			case 3: wep = this.SpawnWeapon("tf_weapon_cannon", 996, 100, 5, "466 ; 1 ; 477 ; 1.0 ; 97 ; 0.6 ; 3 ; 0.25 ; 103 ; 3.0 ; 2 ; 1.50");													//cannon
		}
		SetWeaponAmmo(wep, 100);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", wep);
	}
};

/*
Balance chart

Mage > Knight
Knight > Ranger
Ranger > Mage
*/

#if defined _steamtools_included
bool steamtools = false;
#endif

