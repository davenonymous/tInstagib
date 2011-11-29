#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

new bool:g_bIsJumping[MAXPLAYERS+1];
new Float:g_fHopVelocity[MAXPLAYERS+1][3];
new bool:g_bAirDash[MAXPLAYERS+1];

new Handle:g_hCvarKeepDoubleJumpVelocity = INVALID_HANDLE;
new bool:g_bKeepDoubleJumpVelocity = true;

public Plugin:myinfo =
{
	name 		= "tInstagib - Bunnyhopping",
	author 		= "Thrawn",
	description = "Allows players to bunnyhop",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_bunnyhop_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_bunnyhop_enable", "1", "Enable tInstagib - Bunnyhop", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	g_hCvarKeepDoubleJumpVelocity = CreateConVar("sm_tig_bunnyhop_keepdjvel", "1", "Keep velocity on doublejump", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarKeepDoubleJumpVelocity, Cvar_Changed);

	/* Account for late loading */
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			SDKHook(i, SDKHook_PreThink, OnPreThink);
		}
	}
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_bKeepDoubleJumpVelocity = GetConVarBool(g_hCvarKeepDoubleJumpVelocity);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public OnPreThink(iClient) {
	if(!g_bEnabled)return;
	if(!IsPlayerAlive(iClient))return;

	new Float:velocity[3];
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", velocity);

	new Float:speed = SquareRoot((velocity[0]*velocity[0])+(velocity[1]*velocity[1]));

	new bool:bPressingJump = bool:(GetClientButtons(iClient) & IN_JUMP);
	new bool:bOnGround = bool:(GetEntityFlags(iClient) & FL_ONGROUND);

	new bool:bAirDash = bool:GetEntProp(iClient, Prop_Send, "m_iAirDash");
	new bool:bJustDoubleJumped = false;
	if(!g_bAirDash[iClient] && bAirDash)bJustDoubleJumped = true;
	g_bAirDash[iClient] = bAirDash;

	if(g_bIsJumping[iClient] && !bPressingJump) {
		g_bIsJumping[iClient] = false;
	}

	if((bPressingJump && bOnGround) || (bJustDoubleJumped && g_bKeepDoubleJumpVelocity)) {
		if(g_bIsJumping[iClient]) {
			velocity[2] += 800.0/3.0;
		}

		if(!(GetClientButtons(iClient) & IN_DUCK)) {
			//PrintToChatAll("Bunnyjump!");
			g_bIsJumping[iClient] = true;
			new Float:speed2;
			speed2 = SquareRoot((speed*speed)+(g_fHopVelocity[iClient][2]*g_fHopVelocity[iClient][2]));

			if(speed==0.0) {
				speed2 = 0.0;
			} else {
				velocity[0] = velocity[0]*speed2/speed;
				velocity[1] = velocity[1]*speed2/speed;
			}
		}


		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, velocity);
	}

	g_fHopVelocity[iClient][0] = velocity[0];
	g_fHopVelocity[iClient][1] = velocity[1];
	g_fHopVelocity[iClient][2] = velocity[2];
}