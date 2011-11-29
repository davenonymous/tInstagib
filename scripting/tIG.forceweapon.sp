#pragma semicolon 1
#include <sourcemod>
#include <tf2items>
#include <item_definition_helpers>
#include <tf2_stocks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;

new bool:g_bEnabled;

public Plugin:myinfo =
{
	name 		= "tInstagib - Weapon",
	author 		= "Thrawn",
	description = "Equips every player with a tracing sniperrifle",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_weapon_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_weapon_enable", "1", "Enable tInstagib - Weapon", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_ChangedEnable);

	HookEvent("post_inventory_application", Event_InventoryApplication, EventHookMode_Post);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}


public Action:Event_InventoryApplication(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	CreateTimer(0.1, Timer_CheckInventory, iClient);
}

public Action:Timer_CheckInventory(Handle:timer, any:iClient) {
	TF2_RemoveAllWeapons(iClient);

	CreateTimer(0.3, Timer_EquipRailgun, iClient);
}

public Action:Timer_EquipRailgun(Handle:timer, any:iClient) {
	new Handle:hTest = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
	TF2Items_SetClassname(hTest, "tf_weapon_sniperrifle");
	TF2Items_SetItemIndex(hTest, 14);		// Default Rifle
	//TF2Items_SetItemIndex(hTest, 526);		// The Machina
	//TF2Items_SetItemIndex(hTest, 201);		// Upgradeable Default Rifle


	TF2Items_SetLevel(hTest, 5);
	TF2Items_SetQuality(hTest, 6);
	TF2Items_SetNumAttributes(hTest, 4);
	TF2Items_SetAttribute(hTest, 0, 304, 1.0);
	TF2Items_SetAttribute(hTest, 1, 308, 1.0);
	TF2Items_SetAttribute(hTest, 2, 305, 1.0);
	TF2Items_SetAttribute(hTest, 3, 2, 100.0);

	new entity = TF2Items_GiveNamedItem(iClient, hTest);
	CloseHandle(hTest);

	EquipPlayerWeapon(iClient, entity);

	// Give 200 shot
	new iOffAmmo = FindDataMapOffs(iClient, "m_iAmmo") + 1 * 4;
	SetEntData(iClient, iOffAmmo, 200);
}