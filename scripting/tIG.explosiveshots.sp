#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define VERSION 		"0.0.1"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

new g_ExplosionSprite;

public Plugin:myinfo =
{
	name 		= "tInstagib - Explosive Shots",
	author 		= "Thrawn",
	description = "Every shot hitting a wall will be explosive",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tig_explosive_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tig_explosive_enable", "1", "Enable tInstagib - Explosive", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_ChangedEnable);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public OnMapStart() {
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
}

public Action:TF2_CalcIsAttackCritical(iClient, iWeapon, String:sWeaponname[], &bool:bResult) {
	if(!g_bEnabled)return Plugin_Continue;

	new Float:vecOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);

	new Float:vecAng[3];
	GetClientEyeAngles(iClient, vecAng);

	new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayerNoKill);
	if(TR_DidHit(trace)) {
		new Float:vPosition[3];
		TR_GetEndPosition(vPosition, trace);

		ApplyExplosionForce(iClient, vPosition);
		TE_SetupExplosion(vPosition, g_ExplosionSprite, 1.0, 0, 0, 192, 500);
		TE_SendToAll();
	}
	CloseHandle(trace);

	return Plugin_Continue;
}

public bool:TraceEntityFilterPlayerNoKill(entity, contentsMask) {
	return entity>MaxClients;
}


ApplyExplosionForce(iClient, Float:vPosition[3]) {
	new Float:vOrigin[3];
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vOrigin);
	vOrigin[2] += 20;

	new Float:fDistance = GetVectorDistance(vOrigin, vPosition);
	if(fDistance>192 || fDistance==0)
		return;

	new Float:vForce[3];
	SubtractVectors(vOrigin, vPosition, vForce);

	new Float:scale = ((fDistance/10)*(fDistance/10));
	for(new n=0;n<3;n++) {
		vForce[n] = vForce[n]/scale*250;
		if(vForce[n]>800.0)
			vForce[n] = 800.0;
	}

	new Float:vecVel[3];
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVel);
	AddVectors(vForce, vecVel, vecVel);

	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
}