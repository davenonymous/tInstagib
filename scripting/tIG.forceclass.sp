#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;

new bool:g_bEnabled;

public Plugin:myinfo =
{
	name 		= "tInstagib - class",
	author 		= "Thrawn",
	description = "Forces every player to play a specific class",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_weapon_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_class_enable", "1", "Enable tInstagib - Weapon", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_ChangedEnable);

	//HookEvent("player_changeclass", Event_PlayerClass);
	HookEvent("player_spawn",       Event_PlayerSpawn);
	HookEvent("player_team",        Event_PlayerTeam);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast) {
    new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

    if(g_bEnabled) {
        TF2_SetPlayerClass(iClient, TFClass_Scout);
        TF2_RegeneratePlayer(iClient);
    }
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

    if(g_bEnabled) {
        TF2_SetPlayerClass(iClient, TFClass_Scout);
        TF2_RegeneratePlayer(iClient);
    }
}

public Event_PlayerTeam(Handle:event,  const String:name[], bool:dontBroadcast) {
    new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

    if(iClient > 0) {
		if(g_bEnabled) {
			TF2_SetPlayerClass(iClient, TFClass_Scout);
			TF2_RegeneratePlayer(iClient);
		}
    }
}