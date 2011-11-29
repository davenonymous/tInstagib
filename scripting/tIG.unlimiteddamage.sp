#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarModifier = INVALID_HANDLE;
new Float:g_fModifier = 1.0;

public Plugin:myinfo =
{
	name 		= "tInstagib - Unlimited Damage",
	author 		= "Thrawn",
	description = "This adds a cvar to modify the dealt damage",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_unldamage_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarModifier = CreateConVar("sm_tig_unldamage_modifier", "100.0", "Enable tInstagib - Unlimited Damage by setting this != 1.0", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarModifier, Cvar_ChangedModifier);

	/* Account for late loading */
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnConfigsExecuted() {
	g_fModifier = GetConVarFloat(g_hCvarModifier);
}

public Cvar_ChangedModifier(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fModifier = GetConVarFloat(g_hCvarModifier);
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(g_fModifier == 1.0)return Plugin_Continue;

	if(!(damagetype & DMG_FALL)) {
		damage *= g_fModifier;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}