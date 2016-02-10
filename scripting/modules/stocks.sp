
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
stock void clamp(int& data, int min, int max)
{
	if (data < min) data = min;
	if (data > max) data = max;
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
	if (spellbook <= 0) LogError("[RPG Fortress] ErMac: Spellbook Doesn't Exist!");
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
stock void ClearTimer(Handle& Timer)
{
	if (Timer != null)
	{
		delete Timer;
		Timer = null;
	}
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
