#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION 		"0.0.1"


new g_LastButtons[MAXPLAYERS+1];

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

new Handle:g_hCvarMax = INVALID_HANDLE;
new g_iMaxFov = 170;

new Handle:g_hCvarMin = INVALID_HANDLE;
new g_iMinFov = 50;

enum FOV {
	Default,
	Zoom
};

new g_xFov[MAXPLAYERS+1][FOV];
new bool:g_bIsZoomed[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name 		= "tInstagib - Changeable FOV",
	author 		= "Thrawn",
	description = "Allows players to change their FOV",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_fov_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_fov_enable", "1", "Enable tInstagib - Changeable FOV", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	g_hCvarMin = CreateConVar("sm_tig_fov_min", "50.0", "Minimum Fov", FCVAR_PLUGIN, true, 1.0, true, 179.0);
	HookConVarChange(g_hCvarMin, Cvar_Changed);

	g_hCvarMax = CreateConVar("sm_tig_fov_max", "170.0", "Maximum Fov", FCVAR_PLUGIN, true, 1.0, true, 179.0);
	HookConVarChange(g_hCvarMax, Cvar_Changed);

	HookEvent("player_spawn", Event_PlayerSpawn);

	RegConsoleCmd("sm_fov", Command_SetFov);
	RegConsoleCmd("sm_fovz", Command_SetFovZoom);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_iMinFov = GetConVarInt(g_hCvarMin);
	g_iMaxFov = GetConVarInt(g_hCvarMax);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnClientDisconnect_Post(client) {
    g_LastButtons[client] = 0;
    g_xFov[client][Zoom] = 0;
    g_xFov[client][Default] = 0;
    g_bIsZoomed[client] = false;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!g_bEnabled)return;
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bIsZoomed[iClient]) {
		ApplyFov(iClient, g_xFov[iClient][Zoom]);
	} else {
		ApplyFov(iClient, g_xFov[iClient][Default]);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if(!g_bEnabled)return Plugin_Continue;

	if ((buttons & IN_ATTACK2)) {
		if (!(g_LastButtons[client] & IN_ATTACK2)) {
			OnButtonPress(client);
		}
	} else if ((g_LastButtons[client] & IN_ATTACK2)) {
		OnButtonRelease(client);
	}

	g_LastButtons[client] = buttons;

	return Plugin_Continue;
}

public OnButtonPress(client) {
	// Can't zoom in while dead...
	if(!IsPlayerAlive(client) || IsClientObserver(client))return;

	if(g_xFov[client][Zoom] == 0 || g_xFov[client][Default] == 0) {
		PrintToChat(client, "You need to set your desired FOV values first. Use /fov <default> <zoomed>.");
		return;
	}

	g_bIsZoomed[client] = true;
	ApplyFov(client, g_xFov[client][Zoom]);
}

public OnButtonRelease(client) {
	// ... but still can zoom out
	ApplyFov(client, g_xFov[client][Default]);
	g_bIsZoomed[client] = false;
}

public Action:Command_SetFov(client,args) {
	if(!g_bEnabled) {
		ReplyToCommand(client, "This feature is disabled.");
		return Plugin_Handled;
	}

	if(args == 0) {
		ReplyToCommand(client, "Your FOV is: %i\nYour Zoom FOV is: %i", g_xFov[client][Default], g_xFov[client][Zoom]);
		return Plugin_Handled;
	}

	if(args == 1 || args == 2) {
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));

		new iArg;
		if(StringToIntEx(sArg, iArg) > 0) {
			if(iArg >= g_iMinFov && iArg <= g_iMaxFov) {
				g_xFov[client][Default] = iArg;
				if(IsPlayerAlive(client) && !IsClientObserver(client))ApplyFov(client, iArg);
				ReplyToCommand(client, "FOV set to %i.", iArg);
			} else {
				ReplyToCommand(client, "FOV must be between %i and %i.", g_iMinFov, g_iMaxFov);
				return Plugin_Handled;
			}
		} else {
			ReplyToCommand(client, "FOV parameter '%s' is malformed. Ignoring.", sArg);
		}

		if(args == 2) {
			decl String:sArgZoom[4];
			GetCmdArg(2, sArgZoom, sizeof(sArgZoom));

			new iArgZoom;
			if(StringToIntEx(sArgZoom, iArgZoom) > 0) {
				if(iArgZoom >= g_iMinFov && iArgZoom <= g_iMaxFov) {
					g_xFov[client][Zoom] = iArgZoom;
					ReplyToCommand(client, "Zoom FOV set to %i.", iArgZoom);
				} else {
					ReplyToCommand(client, "Zoom FOV must be between %i and %i.", g_iMinFov, g_iMaxFov);
				}
			} else {
				ReplyToCommand(client, "Zoom FOV parameter '%s' is malformed. Ignoring.", sArgZoom);
			}
		}

		return Plugin_Handled;
	}

	ReplyToCommand(client, "Usage: sm_fov <default fov> [<fov for zooming>]");
	return Plugin_Handled;
}


public Action:Command_SetFovZoom(client,args) {
	if(!g_bEnabled) {
		ReplyToCommand(client, "This feature is disabled.");
		return Plugin_Handled;
	}

	if(args == 0) {
		ReplyToCommand(client, "Your Zoom Fov is: %i", g_xFov[client][Zoom]);
		return Plugin_Handled;
	}

	if(args == 1) {
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));

		new iArg;
		if(StringToIntEx(sArg, iArg) > 0) {
			if(iArg >= g_iMinFov && iArg <= g_iMaxFov) {
				g_xFov[client][Zoom] = iArg;
				ReplyToCommand(client, "Zoom FOV set to %i.", iArg);
			} else {
				ReplyToCommand(client, "Zoom FOV must be between %i and %i.", g_iMinFov, g_iMaxFov);
			}

			return Plugin_Handled;
		}
	}

	ReplyToCommand(client, "Usage: sm_fovz <fov for zooming>");
	return Plugin_Handled;
}

public bool:ApplyFov(client, iFov) {
	if(iFov != 0) {
		SetEntProp(client, Prop_Send, "m_iFOV", iFov);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", iFov);
		return true;
	}

	return false;
}