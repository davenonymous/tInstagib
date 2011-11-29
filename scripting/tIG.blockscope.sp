#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

public Plugin:myinfo =
{
	name 		= "tInstagib - NoScope",
	author 		= "Thrawn",
	description = "This blocks all sniper rifles from scoping",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_blockscope_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_blockscope_enable", "1", "Enable tInstagib - NoScope", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_ChangedEnable);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public OnEntityCreated(entity, const String:classname[]) {
	if(!StrEqual(classname, "tf_weapon_sniperrifle"))return;

	SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public OnEntitySpawned(entity) {
	SDKHook(entity, SDKHook_SetTransmit, OnRiflePrethink);
}

public OnRiflePrethink(entity) {
	if(!g_bEnabled)return;

	new Float:time = GetEntPropFloat(entity, Prop_Send, "m_flTimeWeaponIdle");
	SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", time + 3.0);
}