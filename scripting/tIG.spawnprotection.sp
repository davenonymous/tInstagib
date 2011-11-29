#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarProtTime = INVALID_HANDLE;

new Float:g_fProtTime = 0.0;

public Plugin:myinfo =
{
	name 		= "tInstagib - Spawnprotection",
	author 		= "Thrawn",
	description = "Gives ubercharge for a certain time on spawn",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_spawnprotection_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarProtTime = CreateConVar("sm_tig_spawnprotection_time", "5.0", "Set to 0.0 to disable.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarProtTime, Cvar_ChangedEnable);

	HookEvent("player_spawn",       Event_PlayerSpawn);
}

public OnConfigsExecuted() {
	g_fProtTime = GetConVarFloat(g_hCvarProtTime);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fProtTime = GetConVarFloat(g_hCvarProtTime);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_fProtTime == 0.0)return;

	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	TF2_AddCondition(iClient, TFCond_Ubercharged, g_fProtTime);
}

public Action:TF2_CalcIsAttackCritical(iClient, iWeapon, String:sWeaponname[], &bool:bResult) {
	if(g_fProtTime == 0.0)return Plugin_Continue;

	TF2_RemoveCondition(iClient, TFCond_Ubercharged);
	return Plugin_Continue;
}