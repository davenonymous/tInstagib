#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

public Plugin:myinfo =
{
	name 		= "tInstagib - Gib",
	author 		= "Thrawn",
	description = "All deaths will be bloody",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_gibs_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_gibs_enable", "1", "Enable tInstagib - Gib", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_ChangedEnable);

	HookEvent("player_death", Event_PlayerDeath);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}


public Action:Event_PlayerDeath(Handle:Event, const String:Name[], bool:Broadcast) {
	if(!g_bEnabled)return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(Event, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(Event, "attacker"));

	new Float:fClientOrigin[3];
	GetClientAbsOrigin(iClient, fClientOrigin);

	if(iAttacker != 0 && IsClientInGame(iClient) && IsClientInGame(iAttacker)) {
		new iRagdoll = CreateEntityByName("tf_ragdoll");
		if(IsValidEdict(iRagdoll)) {
			SetEntPropVector(iRagdoll, Prop_Send, "m_vecRagdollOrigin", fClientOrigin);
			SetEntProp(iRagdoll, Prop_Send, "m_iPlayerIndex", iClient);
			SetEntPropVector(iRagdoll, Prop_Send, "m_vecForce", NULL_VECTOR);
			SetEntPropVector(iRagdoll, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR);
			SetEntProp(iRagdoll, Prop_Send, "m_bGib", 1);

			DispatchSpawn(iRagdoll);

			CreateTimer(0.1, RemoveBody, iClient);
			CreateTimer(15.0, RemoveGibs, iRagdoll);
		}
	}

	return Plugin_Continue;
}

public Action:RemoveBody(Handle:Timer, any:iClient) {
	new iBodyRagdoll;
	iBodyRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");

	if(IsValidEdict(iBodyRagdoll)) RemoveEdict(iBodyRagdoll);
}

public Action:RemoveGibs(Handle:Timer, any:iEnt) {
	if(IsValidEntity(iEnt)) {
		decl String:sClassname[64];
		GetEdictClassname(iEnt, sClassname, sizeof(sClassname));

		if(StrEqual(sClassname, "tf_ragdoll", false)) {
			RemoveEdict(iEnt);
		}
	}
}