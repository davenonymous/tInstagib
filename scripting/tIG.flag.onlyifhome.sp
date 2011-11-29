#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;

new bool:g_bEnabled;

public Plugin:myinfo =
{
	name 		= "tInstagib - Flag - Cap only if home",
	author 		= "Thrawn",
	description = "Returns a flag to the base if a player of its team touches it",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_flag_home_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_flag_home_enable", "1", "Enable tInstagib - Flag - Cap only if home", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_ChangedEnable);

	new iFlag = 0;
	while((iFlag = FindEntityByClassname(iFlag, "func_capturezone"))!=-1) {
		SDKHook(iFlag, SDKHook_Touch, TouchHook);
	}
}

public OnEntityCreated(entity, const String:classname[]) {
	if(!StrEqual(classname, "func_capturezone"))return;

	SDKHook(entity, SDKHook_Touch, TouchHook);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Action:TouchHook(iZone, iClient) {
	if(!g_bEnabled)return Plugin_Continue;

	if(iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient) && !IsClientObserver(iClient)) {
		new iClientTeam = GetClientTeam(iClient);
		new iZoneTeam = GetEntProp(iZone, Prop_Send, "m_iTeamNum");
		new iItem = GetEntPropEnt(iClient, Prop_Send, "m_hItem");

		if(iClientTeam == iZoneTeam && iItem != -1) {
			new iFlag = MaxClients+1;
			while((iFlag = FindEntityByClassname(iFlag, "item_teamflag"))!=-1) {
				new iFlagTeam = GetEntProp(iFlag, Prop_Send, "m_iTeamNum");
				if(iFlagTeam != iClientTeam)continue;

				// At least one own flag must be at home
				new iFlagStatus = GetEntProp(iFlag, Prop_Send, "m_nFlagStatus");
				if(iFlagStatus == 0) {
					return Plugin_Continue;
				}
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}