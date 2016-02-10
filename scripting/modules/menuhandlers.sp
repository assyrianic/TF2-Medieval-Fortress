public int MenuHandler_RPGFortress(Menu menu, MenuAction action, int client, int param2)
{  
	char info[32]; menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		switch ( TF2_GetPlayerClass(client) )
		{
			case TFClass_Soldier:
			{
				CKnightClass knight = CKnightClass(client);
				knight.MenuChooseWeapon();
			}
			case TFClass_Medic:
			{
				CMageClass mage = CMageClass(client);
				mage.MenuChooseWeapon();
			}
			case TFClass_Sniper:
			{
				CRangerClass ranger = CRangerClass(client);
				ranger.MenuChooseWeapon();
			}
		}
		//MenuChooseWeapon(client);
	}
	else if (action == MenuAction_End) delete menu;
}
public int MenuHandler_GiveRangeWep(Menu menu, MenuAction action, int client, int param2)
{
	char info2[32]; menu.GetItem(param2, info2, sizeof(info2));
	if (action == MenuAction_Select)
	{
		TF2_RemoveAllWeapons2(client);

		CRangerClass ranger = CRangerClass(client);
		ranger.iWeapPick = param2;
		ranger.Equip();

		//SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 26 ; 75 ; 252 ; 0");
	}
	else if (action == MenuAction_End) delete menu;
}
public int MenuHandler_GiveMeleeWep(Menu menu, MenuAction action, int client, int param2)
{
	char info3[32]; menu.GetItem( param2, info3, sizeof(info3) );
	if (action == MenuAction_Select)
	{
                TF2_RemoveAllWeapons2(client);

		CKnightClass knight = CKnightClass(client);
		knight.iWeapPick = param2;
		knight.Equip();

		//SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 5.0 ; 252 ; 0");
	}
	else if (action == MenuAction_End) delete menu;
}
public int MenuHandler_GiveMageWep(Menu menu, MenuAction action, int client, int param2)
{
	char info4[32]; menu.GetItem( param2, info4, sizeof(info4) );
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

		CMageClass mage = CMageClass(client);
		mage.iWeapPick = param2;
		mage.Equip();

		//SpawnWeapon(client, "tf_weapon_builder", 28, 5, 10, "57 ; 2.0 ; 26 ; 25 ; 252 ; 0");
	}
	else if (action == MenuAction_End) delete menu;
}

