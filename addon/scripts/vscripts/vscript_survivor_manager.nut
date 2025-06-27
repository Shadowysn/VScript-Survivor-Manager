//try {
printl("Activating VScript Survivor Manager");

/*

i see u boi

*/

// todo:
/*
- block and/or forward inputs from our team 2 survivors to team 4 (fixed)
- charger fix W.I.P. figure out how to recreate freezing takedown
effects of trigger upon death also not tested (likely fixed)
- defibrillator fix W.I.P. higher priority
bodies are still incorrectly disappearing (half-done for defib)
the defibrillator events don't fire if survivor is passing character 
in l4d1 surv set without equivalent proper l4d1 surv existing
- witch fix W.I.P. not functional
- l4d1 bots being spawned in maps immediately can prematurely trigger player_first_spawn
and consequently break the shit out of the initial map spawn system
see custom survivor bot in a custom coldy map (mostly fixed)
*/

local TCFVersion = 1;
// teamCrashFix handles fixing team crashing by setting the bots to 
// their proper team before removal from the team list by the game's hard code
if (!("teamCrashFix" in this) || 
(!("version" in teamCrashFix) || teamCrashFix.version < TCFVersion))
{
teamCrashFix <-
{
	version = TCFVersion,
	// this system is flawed and is probably the cause of the inconsistent crashes
	// at least oldteam == 0 can be checked
	/*recentJoins = [],
	function OnGameEvent_player_connect(params)
	{
		printl("EVENT player_connect");
		g_ModeScript.DeepPrintTable(params);
		if (!("userid" in params)) return;
		
		if (recentJoins.find(params["userid"]) == null)
			recentJoins.append(params["userid"]);
	}*/
	
	function OnGameEvent_player_team(params)
	{
		//printl("EVENT player_team");
		//g_ModeScript.DeepPrintTable(params);
		if (!("userid" in params)) return;
		local client = GetPlayerFromUserID(params["userid"]);
		if (client == null || !client.IsValid()) return;
		
		local hasTeamEv = ("team" in params && params.team != 0);
		if (hasTeamEv && "oldteam" in params && params.oldteam == 0)
		{
			NetProps.SetPropInt(client, "m_iInitialTeamNum", params.team);
			//printl("m_iInitialTeamNum set to "+params.team);
			return;
		}
		
		local initialTeam = NetProps.GetPropInt(client, "m_iInitialTeamNum");
		if (initialTeam != 0)
		{
			local curTeam = NetProps.GetPropInt(client, "m_iTeamNum");
			if (curTeam != initialTeam)
			{
				NetProps.SetPropInt(client, "m_iTeamNum", initialTeam);
				//printl("m_iTeamNum set to "+initialTeam);
			}
		}
		
		if (hasTeamEv)
		{
			NetProps.SetPropInt(client, "m_iInitialTeamNum", params.team);
			//printl("m_iInitialTeamNum set to "+params.team);
		}
	}
	
	function OnGameEvent_player_disconnect(params)
	{
		//printl("EVENT player_disconnect");
		//g_ModeScript.DeepPrintTable(params);
		if (!("userid" in params)) return;
		
		local client = GetPlayerFromUserID(params["userid"]);
		if (client == null || !client.IsValid()) return;
		
		local initialTeam = NetProps.GetPropInt(client, "m_iInitialTeamNum");
		if (initialTeam == 0) return;
		
		local curTeam = NetProps.GetPropInt(client, "m_iTeamNum");
		if (curTeam != initialTeam)
		{
			local wasAlive = (NetProps.GetPropInt(client, "m_lifeState") == 0);
			local isFalling = false;
			if (wasAlive)
			{
				isFalling = (NetProps.GetPropInt(client, "m_isFallingFromLedge") != 0);
				if (curTeam == 4)
					NetProps.SetPropInt(client, "m_iTeamNum", 2);
				
				local worldSpawn = Entities.First();
				NetProps.SetPropInt(client, "m_takedamage", 2);
				client.SetHealthBuffer(0);
				client.TakeDamageEx(worldSpawn, worldSpawn, worldSpawn, Vector(), Vector(), client.GetHealth() * 10, (1 << 5)); // DMG_FALL
				
				// We need to stop the crash at all costs
				// If they're still alive they're blocking fall damage
				// In that case use different damage
				if (NetProps.GetPropInt(client, "m_lifeState") == 0)
				{
					NetProps.SetPropInt(client, "m_isIncapacitated", 1);
					client.TakeDamageEx(worldSpawn, worldSpawn, worldSpawn, Vector(), Vector(), client.GetHealth() * 10, (1 << 0)); // DMG_GENERIC
				}
			}
			
			NetProps.SetPropInt(client, "m_iTeamNum", initialTeam);
			
			if (wasAlive && !NetProps.GetPropInt(client, "m_lifeState") != 0 && !isFalling)
			{
				switch (curTeam)
				{
				case 2:
				case 4:
					local clOrigin = client.GetOrigin();
					local distance = null;
					local chosenBody = null;
					for (local body; body = Entities.FindByClassname( body, "survivor_death_model" );)
					{
						if (body == null || NetProps.GetPropInt(body, "m_iEFlags") & (1 << 0)) continue; // EFL_KILLME
						
						local distVars = (clOrigin-body.GetOrigin()).LengthSqr();
						if (distance == null || distVars < distance)
						{
							distance = distVars;
							chosenBody = body;
						}
					}
					if (chosenBody != null)
						chosenBody.Kill();
					break;
				}
			}
			//Director.ClearCachedBotQueries(); // TODO for TCFVersion 2
			//printl("m_iTeamNum set to "+initialTeam);
			// thought maybe the weapons have something to do with the odd crash
			// was not the case
			// game sometimes crashes when multiple survivor bots get kicked and 
			// readded, it's likely a problem with this crash fix although how it's
			// happening i don't know
			// and then it gets unpredictably less common the longer the session is
			// for some reason
		//	for (local i = 0; i < NetProps.GetPropArraySize(client, "m_hMyWeapons"); i++)
		//	{
		//		local wep = NetProps.GetPropEntityArray(client, "m_hMyWeapons", i);
		//		if (wep == null) continue;
		//		printl("wep: "+wep+" team: "+NetProps.GetPropInt(wep, "m_iTeamNum"));
		//		//wep.Kill();
		//		if (NetProps.GetPropInt(wep, "m_iTeamNum") != initialTeam)
		//		{
		//			printl("Found a weapon that didn't have matching team for "+client+"!: "+wep);
		//			NetProps.SetPropInt(wep, "m_iTeamNum", initialTeam);
		//		}
		//	}
		}
	}
}
}
__CollectEventCallbacks(teamCrashFix, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);

local survAnimVersion = 1;
if (!("survAnim" in this) || 
(!("version" in survAnim) || survAnim.version < survAnimVersion))
{
survAnim <-
{
	version = survAnimVersion,
	HackPos = null,
	// animation forcing hack because (Re)SetSequence doesn't work on players
	function ForceSequence(client, anim)
	{
		if (client.GetMoveParent() != null) return;
		
		local worldSpawn = Entities.First();
		if (!worldSpawn.ValidateScriptScope()) return;
		
		local worldScope = worldSpawn.GetScriptScope();
		if (!("VScrAlterFS1" in worldScope) || worldScope.VScrAlterFS1 == null)
			worldScope.VScrAlterFS1 <- AlterFS1.weakref();
		if (!("VScrAlterFS2" in worldScope) || worldScope.VScrAlterFS2 == null)
			worldScope.VScrAlterFS2 <- AlterFS2.weakref();
		if (!("VScrAlterFS1Var" in worldScope) || worldScope.VScrAlterFS1Var == null)
			worldScope.VScrAlterFS1Var <- [];
		if (!("VScrAlterFS2Var" in worldScope) || worldScope.VScrAlterFS2Var == null)
			worldScope.VScrAlterFS2Var <- [];
		
		local clOrigin = client.GetOrigin();
		local clAngles = client.EyeAngles();
		
		if (HackPos == null || !HackPos.IsValid())
		{
			HackPos = SpawnEntityFromTable("info_survivor_position", {
				targetname = "VScrFSHack",
			});
			if (HackPos == null || !HackPos.IsValid()) return;
		}
		
		worldScope.VScrAlterFS1Var.append([
			clOrigin,
			QAngle(clAngles.x, clAngles.y, 0),
			anim,
		]);
		worldScope.VScrAlterFS2Var.append([
			clOrigin,
			clAngles,
			client.GetVelocity(),
		]);
		
		DoEntFire("!self", "CallScriptFunction", "VScrAlterFS1", 0, HackPos, worldSpawn);
		DoEntFire("!self", "CallScriptFunction", "IFOverride1", 0, null, client);
		DoEntFire("!self", "TeleportToSurvivorPosition", "VScrFSHack", 0, null, client);
		DoEntFire("!self", "CallScriptFunction", "IFOverride0", 0, null, client);
		DoEntFire("!self", "ClearParent", "", 0, null, client);
		DoEntFire("!self", "CallScriptFunction", "VScrAlterFS2", 0, client, worldSpawn);
	}
	function AlterFS1()
	{
		if (!("VScrAlterFS1Var" in this)) return;
		if (!(0 in this.VScrAlterFS1Var))
		{
			delete this.VScrAlterFS1Var;
			return;
		}
		
		if (activator != null)
		{
			for (local i = 0; i < this.VScrAlterFS1Var[0].len(); i++)
			{
				switch (i)
				{
				case 0:
					activator.SetOrigin(this.VScrAlterFS1Var[0][i]);
					break;
				case 1:
					activator.SetAngles(this.VScrAlterFS1Var[0][i]);
					break;
				case 2:
					activator.__KeyValueFromString("SurvivorIntroSequence", this.VScrAlterFS1Var[0][i]);
					break;
				}
			}
		}
		this.VScrAlterFS1Var.remove(0);
	}
	function AlterFS2()
	{
		if (!("VScrAlterFS2Var" in this)) return;
		if (!(0 in this.VScrAlterFS2Var))
		{
			delete this.VScrAlterFS2Var;
			return;
		}
		
		if (activator != null)
		{
			for (local i = 0; i < this.VScrAlterFS2Var[0].len(); i++)
			{
				switch (i)
				{
				case 0:
					activator.SetOrigin(this.VScrAlterFS2Var[0][i]);
					break;
				case 1:
					activator.SnapEyeAngles(this.VScrAlterFS2Var[0][i]);
					break;
				case 2:
					activator.SetVelocity(this.VScrAlterFS2Var[0][i]);
					break;
				}
			}
			NetProps.SetPropEntity(activator, "m_positionEntity", null);
			NetProps.SetPropInt(activator, "m_fFlags", NetProps.GetPropInt(activator, "m_fFlags") &~ (1 << 5));
			NetProps.SetPropInt(activator, "m_Local.m_iHideHUD", 0);
		}
		this.VScrAlterFS2Var.remove(0);
	}
}
}

local CMD_SPAWN_NAME = "survbot";
local CMD_COUNT_NAME = "survcount";
local CMD_REFIXATTEMPTS_NAME = "survfix";
local CMD_TAKEOVER_NAME = "survswap";
//local CMD_SETCHAR_NAME = "survchar";
local CMD_ORDER_NAME = "survorder";
local CMD_KICK_NAME = "survkick";

local SPAWNTYPE_CHECK = 0;
local SPAWNTYPE_CMD = 1;

// sb_add is funky
//local g_survBCharacter = [];
//local g_survNCharacter = [];
local g_survCharacter = {};
//local g_existingPlys = [];
local g_iBots = 0;
local g_iBotAttempts = 0;
local MAX_SPAWN_ATTEMPTS = 6;

local g_vecSummon = null;

local default_folder = "vssm";
local info_path = default_folder+"/info.txt";
local settings_path = default_folder+"/settings.cfg";

local isDedicated = IsDedicatedServer();
local survSet = Director.GetSurvivorSet();

//local g_lastBotKillTime = 0;
//local BOTKILL_WARN_TIME = 5;

local errorMeleeIdx = null;

// persistent variables that NEED to last through soft map restarts
// (basically any map loads that don't involve a loading poster)
// strict survivor list that updates with SurvListFunc
if (!("survManagerList" in this))
{ survManagerList <- []; }
// strict spectator list that updates with SpecListFunc
if (!("specManagerList" in this))
{ specManagerList <- []; }
// for map-entities info_l4d1_survivor_spawn spawned survivors 
if (!("infoSpawnedSurvsList" in this))
{ infoSpawnedSurvsList <- {}; }
// round_start is too early for bots when map first loads
if (!("VSSMAllowRoundStart" in this))
{ VSSMAllowRoundStart <- null; }
// info_l4d1_survivor_spawn that handles all spawning
// not sure if this should kill itself or stay
// on the upside it's a free entity scope we can attach AddThinkToEnt to
if (!("VSSMSpawner" in this))
{ VSSMSpawner <- null; }
//if (!("VSSMEntsWithIdVars" in this))
//{ VSSMEntsWithIdVars <- []; }
local VSSMEntsWithIdVars = [];

// don't give start items to the first 4 spawned survivors only
// but any of the spawned survs kicked and replaced are eligible for start items then
// VSSMStartWepsInit is a hack variable for first map load and 
// helps cache VSSMNoSpawnStartItemsTbl which should not change for entire session
if (!("VSSMStartWepsInit" in this))
{ VSSMStartWepsInit <- null; }
if (!("VSSMNoSpawnStartItemsTbl" in this))
{ VSSMNoSpawnStartItemsTbl <- []; }

if (!("VSSMTransItemsTbl" in this))
{ VSSMTransItemsTbl <- {}; }
if (!("VSSMFirstCharSurvs" in this))
{ VSSMFirstCharSurvs <- []; }

// people actually pick other characters i was so used to nick and bill every time
// with console map mapname no wonder
if (!("VSSMCharsInit" in this))
{ VSSMCharsInit <- null; }

// Team 2 Bots that shouldn't be removed, like Mike from Cold Front
// map_support script handles adding bots to this array
if (!("VSSMEssentialBots" in this))
{ VSSMEssentialBots <- []; }

if (!("survManager" in this) || ("hasRoundEnded" in survManager))
{

local friendlyFireTime = 0;

local maxPlayers = 18;
local teamManager = Entities.FindByClassname(null, "cs_team_manager");
if (teamManager != null)
	maxPlayers = teamManager.GetEntityIndex() - 1;
else
	printl("[VSSM]\nWARNING:\nCouldn't get maxplayers! Assuming it is 18!");

local baseMode = null;
if ("g_BaseMode" in this)
	baseMode = g_BaseMode;
else
	baseMode = Director.GetGameModeBase();

// welcome to Shadowysn's spaghetti emporium, we are now surving bots
survManager <-
{
	// my thought for this var is to blanket-check through events to decide
	// whether to do survivor character fixes like defibbing wrong person,
	// upgrade packs only working for 4, passing-value characters able to take all 
	// upgrade ammo, etc, but plugins/scripts can sneaky change characters without 
	// firing events so nah
	//OddSurvivorsInPlay = false,
	chosenOrder = null,
	transItemsGranted = [],
	// for spectators that remain specs on round end or map transition
	//specTbl = {},
	//startItemsGranted = [],
	
	//expectedInfoBots = 0,
	
	// table of which weapons are special eg. melee keys for survStartWeapons
	startWepsType = {},
	dirOptionDefaultItems = [],
	
	// enforced chars for SpawnBot, goes like [<character>, <number>]
	enforcedChars = null,
	
	// table of changelevel entity indexes containing an array of first aid kit spawns
	changeLevelsItems = {},
	
	/*function WarnIncompat()
	{
		switch (baseMode)
		{
		case "versus":
		case "scavenge":
			if (!isDedicated)
			{
				ClientPrint(GetListenServerHost(), 3, "\x03"+"[VSSM]"+"\x04"+"\nWARNING:"+"\x01"+"\nPVP gamemodes are NOT properly tested!");
			}
			else
			{
				printl("[VSSM]\nWARNING:\nPVP gamemodes are NOT properly tested!");
			}
			break;
		}
	}*/
	
	// Stop the pistol drop spam caused by Manacat's mods
	// https://steamcommunity.com/sharedfiles/filedetails/?id=213445426
	function DropItemCheck(client, weaponClass)
	{
		if (weaponClass == "weapon_pistol" && 
		!("repair1" in this) && 
		"manacat_rng_item" in getroottable() && "OnGameEvent_weapon_drop" in ::manacat_rng_item)
		{
			printl("Replacing and breaking pistol skin handling for ::manacat_rng_item.OnGameEvent_weapon_drop function\nto avoid pistol drop spam from Manacat's rngitem script");
			::manacat_rng_item.OnGameEvent_weapon_drop <- function(params)
			{
				if(!("item" in params))return;
				local player = GetPlayerFromUserID(params.userid);
				if(player == null || !player.IsValid())return;
				::manacat_rng_item.chkThrows(player);
				if(NetProps.GetPropInt(player,"m_iHealth") != 0 && NetProps.GetPropFloat(player,"m_healthBuffer") != 0)::manacat_rng_item.inv_save(params.userid);
			}
			this.repair1 <- null;
		}
		client.DropItem(weaponClass);
	}
	
	function ReloadItems()
	{
		// extra survivors actually have saved items from default takeover system
		// but it takes effect only on restart because extras spawn late
		// and the clones get the wrong loadout of first player char :\
		// though i think i can't rely on this default system
		// thanks to first char survs being able to leave and thus
		// pushing the first char surv's inventory to the wrong one
		/*local firstCharSurvs = [];
		for (local i = 0; i <= 7; i++)
		{
			local handledChar = GetPlayerFromCharacter(i);
			if (handledChar != null)
				firstCharSurvs.append(handledChar);
		}*/
		
		local survList = survManager.RetrieveSurvList(false);
		local gameSurvSlots = survManager.GetNumberOrderSlots(survList);
		foreach (key, client in survList)
		{
			//ApplyIFs(client, true);
			if (NetProps.GetPropInt(client, "m_iTeamNum") != 2)
			{
				continue;
			}
			//local userId = client.GetPlayerUserId();
			//local nSArrLoc = VSSMNoSpawnStartItemsTbl.find(userId);
			//if (nSArrLoc != null) continue;
			
			local survSlot = gameSurvSlots.find(client);
			if (survSlot == null) continue;
			
			local origWeps = null;
			for ( local moveChild = client.FirstMoveChild(); moveChild != null; moveChild = moveChild.NextMovePeer() )
			{
				if (!moveChild.IsValid() || moveChild.GetClassname().slice(0,7) != "weapon_") continue;
				if (origWeps == null) origWeps = [];
				origWeps.append(moveChild);
			}
			
			local userId = client.GetPlayerUserId();
			local hasTransItems = (VSSMFirstCharSurvs.find(userId) == null) ? survManager.RestoreTransItems(client, origWeps, survSlot) : false;
			if (!hasTransItems && VSSMNoSpawnStartItemsTbl.find(userId) == null)
			{
				survManager.GiveStartItems(client, origWeps);
			}
		}
		delete this.VSSMReloadItems;
	}
	function OnGameEvent_round_start( params )
	{
		if (VSSMAllowRoundStart == null) return;
		RoundStart();
		//WarnIncompat();
		
		local worldSpawn = Entities.First();
		if (!worldSpawn.ValidateScriptScope()) return;
		
		local worldScope = worldSpawn.GetScriptScope();
		if (worldScope != null && 
		(!("VSSMReloadItems" in worldScope) || worldScope.VSSMReloadItems == null))
		{
			worldScope.VSSMReloadItems <- ReloadItems.weakref();
			DoEntFire("!self", "CallScriptFunction", "VSSMReloadItems", 0, null, worldSpawn);
		}
		// here is earlier than the unreliable game's transition weapons loading
		// which overrides our stuff so do it on delay
		
		// spawning bots in round_start is a bit too early
		// game's main survivors haven't even spawned
		/*if (survManagerList.len() != 0)
		{
			SpawnBot(0);
		}*/
	}
	
	function OnGameEvent_round_end( params )
	{
		this.hasRoundEnded <- null;
		transItemsGranted.clear();
		//startItemsGranted.clear();
	}
	
	function GetSurvSet()
	{
		/*switch (survManager.Settings.forceFuncSurvSet)
		{
		case 1:
		case 2:
			return survManager.Settings.forceFuncSurvSet;
			break;
		}*/
		return survSet;
	}
	
	function GetSurvOrder()
	{
		if (chosenOrder == null)
		{
			local orderList = [];
			switch (GetSurvSet())
			{
			case 1:
				if (Settings.survCharOrderL4D1.len() == 0) break;
				foreach (key, val in Settings.survCharOrderL4D1)
				{
					switch (val.tolower())
					{
					case "bill":		orderList.append(0); break;
					case "zoey":		orderList.append(1); break;
					case "louis":		orderList.append(2); break;
					case "francis":		orderList.append(3); break;
					case "nick":		orderList.append(4); break;
					case "rochelle":	orderList.append(5); break;
					case "ellis":		orderList.append(6); break;
					case "coach":		orderList.append(7); break;
					}
				}
				break;
			default:
				if (Settings.survCharOrderL4D2.len() == 0) break;
				foreach (key, val in Settings.survCharOrderL4D2)
				{
					switch (val.tolower())
					{
					case "nick":		orderList.append(0); break;
					case "rochelle":	orderList.append(1); break;
					case "coach":		orderList.append(2); break;
					case "ellis":		orderList.append(3); break;
					case "bill":		orderList.append(4); break;
					case "zoey":		orderList.append(5); break;
					case "francis":		orderList.append(6); break;
					case "louis":		orderList.append(7); break;
					}
				}
				break;
			}
			chosenOrder = orderList;
		}
		return chosenOrder;
	}
	
	Settings =
	{
		survCount = 4,
		removeExcessSurvivors = true,
		//forceFuncSurvSet = 0,
		survStartWeapons = [
			"base",
			"pistol",
			"first_aid_kit",
		],
		survCharOrderL4D2 = [
			"Nick",
			"Rochelle",
			"Coach",
			"Ellis",
			"Bill",
			"Zoey",
			"Francis",
			"Louis",
		],
		survCharOrderL4D1 = [
			"Bill",
			"Zoey",
			"Louis",
			"Francis",
			"Nick",
			"Rochelle",
			"Ellis",
			"Coach",
		],
		fixUpgradePacks = true,
		autoControlExtraBots = true,
		fixChargerHits = true,
		fixDefibrillator = true,
		fixFriendlyFireLines = true,
		autoCheckpointFirstAid = true,
		restoreExtraSurvsItemsOnTransition = true,
		allowSurvSwapCmdForUsers = false,
	}
	
	function SerializeSettings()
	{
		local sData = "{";
		foreach (key, val in Settings)
		{
			switch (typeof val)
			{
			case "string":
				sData = format("%s\n\t%s = \"%s\"", sData, key, val);
				break;
			
			case "float":
				sData = format("%s\n\t%s = %.2f", sData, key, val);
				break;
			
			case "integer":
			case "bool":
				sData = sData + "\n\t" + key + " = " + val;
				break;
			case "table":
				local tableStr = "";
				foreach (key, value in val)
				{
					switch (typeof value)
					{
						case "string":
						{
							tableStr = tableStr+"\n\t\t"+key+" = \""+value+"\",";
							break;
						}
						default:
						{
							tableStr = tableStr+"\n\t\t"+key+" = "+value+",";
							break;
						}
					}
				}
				sData = format("%s\n\t%s = \n\t{%s\n\t}", sData, key, tableStr);
				break;
			case "array":
				local tableStr = "";
				foreach (key, value in val)
				{
					switch (typeof value)
					{
					case "string":
						tableStr = tableStr+"\n\t\t\""+value+"\",";
						break;
					default:
						tableStr = tableStr+"\n\t\t"+value+",";
						break;
					}
				}
				sData = format("%s\n\t%s = \n\t[%s \n\t]", sData, key, tableStr);
				break;
			}
		}
		sData = sData + "\n}";
		StringToFile(settings_path, sData);
	}
	
	function UpdateConfigFile(alterKeys = null)
	{
		if (alterKeys == null)
		{
			// Need to reset chosenOrder to null to properly reset survivor order
			// and clear startWepsType to reget new weapon types
			chosenOrder = null;
			startWepsType.clear();
			ParseConfigFile();
			return;
		}
		
		local tData;
		if (tData = FileToString(settings_path))
		{
			try {
				tData = compilestring("return " + tData)();
				local hasUpdatedKey = false;
				foreach (key, val in tData)
				{
					if (key in Settings)
					{
						if (key in alterKeys)
						{
							Settings[key] = alterKeys[key];
							if (!hasUpdatedKey) { hasUpdatedKey = true; }
						}
						else
						{
							Settings[key] = tData[key];
						}
					}
				}
				if (hasUpdatedKey)
				{
					chosenOrder = null;
					startWepsType.clear();
					SerializeSettings();
				}
			}
			catch (error) {
				printl("[VSSM] ERROR trying to update config:\n"+error);
			}
		}
	}
	
	function ParseConfigFile()
	{
		local tData;
		if (tData = FileToString(settings_path))
		{
			try {
				tData = compilestring("return " + tData)();
				local hasMissingKey = false;
				foreach (key, val in Settings)
				{
					if (key in tData)
					{
						Settings[key] = tData[key];
					}
					else if (!hasMissingKey)
					{ hasMissingKey = true; }
				}
				if (hasMissingKey)
				{ SerializeSettings(); }
			}
			catch (error) {
				SerializeSettings();
			}
		}
		else
		{
			SerializeSettings();
		}
	}
	
	// --=FUNCTION=-- VSSMEntsWithIdVars, for replace events to properly swap IDs
	function EntVarFunc(entity, boolean = true)
	{
		switch (boolean)
		{
		case true:
			if (VSSMEntsWithIdVars.find(entity) == null)
				VSSMEntsWithIdVars.append(entity);
			break;
		default:
			local arrLoc = VSSMEntsWithIdVars.find(entity);
			if (arrLoc != null)
				VSSMEntsWithIdVars.remove(arrLoc);
			break;
		}
	}
	
	function RetrieveEntVarList(checkScope = false)
	{
		local entVarsList = [];
		for (local i = 0; i < VSSMEntsWithIdVars.len(); i++)
		{
			if (VSSMEntsWithIdVars[i] == null || !VSSMEntsWithIdVars[i].IsValid() || 
			(checkScope && !VSSMEntsWithIdVars[i].ValidateScriptScope()))
			{
				VSSMEntsWithIdVars.remove(i); i = i - 1;
				continue;
			}
			entVarsList.append(VSSMEntsWithIdVars[i]);
		}
		return entVarsList;
	}
	
	// --=FUNCTION=-- survManagerList things
	function SurvListFunc(userid, boolean = true)
	{
		switch (boolean)
		{
		case true:
			if (survManagerList.find(userid) == null)
				survManagerList.append(userid);
			break;
		default:
			local arrLoc = survManagerList.find(userid);
			if (arrLoc != null)
				survManagerList.remove(arrLoc);
			break;
		}
	}
	
	function RetrieveSurvList(checkScope = false)
	{
		local survList = [];
		for (local i = 0; i < survManagerList.len(); i++)
		{
			if (survManagerList[i] == null)
			{
				survManagerList.remove(i); i = i - 1;
				continue;
			}
			local client = GetPlayerFromUserID(survManagerList[i]);
			if (client == null || !client.IsSurvivor() || 
			(checkScope && !client.ValidateScriptScope()))
			{
				survManagerList.remove(i); i = i - 1;
				continue;
			}
			survList.append(client);
		}
		return survList;
	}
	
	function SpecListFunc(userid, boolean = true)
	{
		switch (boolean)
		{
		case true:
			if (specManagerList.find(userid) == null)
				specManagerList.append(userid);
			break;
		default:
			local arrLoc = specManagerList.find(userid);
			if (arrLoc != null)
				specManagerList.remove(arrLoc);
			break;
		}
	}
	
	function RetrieveSpecList(checkScope = false)
	{
		local specList = [];
		for (local i = 0; i < specManagerList.len(); i++)
		{
			if (specManagerList[i] == null)
			{
				specManagerList.remove(i); i = i - 1;
				continue;
			}
			local client = GetPlayerFromUserID(specManagerList[i]);
			if (client == null || NetProps.GetPropInt(client, "m_lifeState") == 0 || 
			(checkScope && !client.ValidateScriptScope()))
			{
				specManagerList.remove(i); i = i - 1;
				continue;
			}
			specList.append(client);
		}
		return specList;
	}
	
	// thank you a lot Nescius
	// if you don't know string tables precache strings so when you use
	// something like GetMeAString on anything entity related it might pop up
	// as Getmeastring because the map's first use of this string uses that case
	// this is important because input hooks are CASE SENSITIVE
	// but inputs themselves are NOT CASE SENSITIVE
	function GetFromStringTable(str, strTblLookup = Entities.First())
	{
		local oldName = strTblLookup.GetName();
		
		strTblLookup.__KeyValueFromString("targetname", str);
		local strFromStrTbl = strTblLookup.GetName();
		
		strTblLookup.__KeyValueFromString("targetname", oldName);
		
		return strFromStrTbl;
	}
	
	// --=EVENT=-- Fix takecontrolling from idle or joining
	function SetCharacter(client, char, mode = null)
	{
		//printl("SetCharacter called with client: "+client+", char: "+char+", mode: "+mode);
		if (char < 0 || char > 7) return;
		if (mode != 0) NetProps.SetPropInt(client, "m_survivorCharacter", char);
		switch (GetSurvSet())
		{
		case 1:
			switch (char)
			{
			case 0: // bill
				if (mode == 0)
				{client.SetContext("who","",0); break;}
				
				client.SetModel("models/survivors/survivor_namvet.mdl");
				client.SetContext("who","",0);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Bill");
				break;
			case 1: // zoey
				if (mode == 0)
				{client.SetContext("who","",0); break;}
				
				client.SetModel("models/survivors/survivor_teenangst.mdl");
				client.SetContext("who","",0);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Zoey");
				break;
			case 2: // louis
				if (mode == 0)
				{client.SetContext("who","",0); break;}
				
				client.SetModel("models/survivors/survivor_manager.mdl");
				client.SetContext("who","",0);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Louis");
				break;
			case 3: // francis
				if (mode == 0)
				{client.SetContext("who","",0); break;}
				
				client.SetModel("models/survivors/survivor_biker.mdl");
				client.SetContext("who","",0);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Francis");
				break;
			case 4: // passing nick
				if (mode == 0)
				{client.SetContext("who","gambler",-1); break;}
				
				client.SetModel("models/survivors/survivor_gambler.mdl");
				client.SetContext("who","gambler",-1);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Nick");
				break;
			case 5: // passing rochelle
				if (mode == 0)
				{client.SetContext("who","producer",-1); break;}
				
				client.SetModel("models/survivors/survivor_producer.mdl");
				client.SetContext("who","producer",-1);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Rochelle");
				break;
			case 6: // passing ellis
				if (mode == 0)
				{client.SetContext("who","mechanic",-1); break;}
				
				client.SetModel("models/survivors/survivor_mechanic.mdl");
				client.SetContext("who","mechanic",-1);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Ellis");
				break;
			case 7: // passing coach
				if (mode == 0)
				{client.SetContext("who","coach",-1); break;}
				
				client.SetModel("models/survivors/survivor_coach.mdl");
				client.SetContext("who","coach",-1);
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Coach");
				break;
			}
			break;
		default:
			switch (char)
			{
			case 0: // nick
				client.SetModel("models/survivors/survivor_gambler.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Nick");
				break;
			case 1: // rochelle
				client.SetModel("models/survivors/survivor_producer.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Rochelle");
				break;
			case 2: // coach
				client.SetModel("models/survivors/survivor_coach.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Coach");
				break;
			case 3: // ellis
				client.SetModel("models/survivors/survivor_mechanic.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Ellis");
				break;
			case 4: // passing bill
				client.SetModel("models/survivors/survivor_namvet.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Bill");
				break;
			case 5: // passing zoey
				client.SetModel("models/survivors/survivor_teenangst.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Zoey");
				break;
			case 6: // passing francis
				client.SetModel("models/survivors/survivor_biker.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Francis");
				break;
			case 7: // passing louis
				client.SetModel("models/survivors/survivor_manager.mdl");
				if (IsPlayerABot(client))
					SetFakeClientConVarValue(client, "name", "Louis");
				break;
			}
			break;
		}
		
		switch (char)
		{
		case 4: case 5: case 6: case 7:
			if (VSSMSpawner == null || !VSSMSpawner.IsValid()) survManager.EnsureSpawner();
			if (VSSMSpawner != null)
			{
				local entScope = VSSMSpawner.GetScriptScope();
				if (entScope.IsThinking == null)
				{
					AddThinkToEnt(VSSMSpawner, "VSSMThink");
					entScope.IsThinking = true;
				}
			}
			break;
		}
	}
	
	// l4d2's player system sucks ASS
	// should ideally swap VSSMTransItemsTbl slots in replace events
	// but newly-spawned bots' slots are taken as newest slot that doesn't fit
	// sadly probably not workable
	function DoReplace(oldPlyId, newPlyId)
	{
		local oldPly = GetPlayerFromUserID(oldPlyId);
		if (oldPly == null || !oldPly.IsValid()) return;
		local newPly = GetPlayerFromUserID(newPlyId);
		if (newPly == null || !newPly.IsValid() || !newPly.IsSurvivor()) return;
		
		local essentialMark = VSSMEssentialBots.find(oldPly);
		if (essentialMark != null)
			VSSMEssentialBots[essentialMark] = newPly;
		
		local survChar = NetProps.GetPropInt(oldPly, "m_survivorCharacter");
		// don't count these as spawned so they don't change unwantedly by CharCheck
		if (oldPly.ValidateScriptScope())
		{
			local clScope = oldPly.GetScriptScope();
			if ("VSSMSpawned" in clScope)
			{ delete clScope.VSSMSpawned; }
		}
		
		if (g_survCharacter.len() != 0 && oldPlyId in g_survCharacter)
		{
			g_survCharacter[newPlyId] <- g_survCharacter[oldPlyId];
			delete g_survCharacter[oldPlyId];
		}
		local nSArrLoc = VSSMNoSpawnStartItemsTbl.find(oldPlyId);
		if (nSArrLoc != null)
			VSSMNoSpawnStartItemsTbl[nSArrLoc] = newPlyId;
		
		local entVarList = RetrieveEntVarList(true);
		if (entVarList.len() != 0)
		{
			foreach (key, ent in entVarList)
			{
				ent.GetScriptScope().SwapIds(oldPlyId, newPlyId);
			}
		}
		
		local arrFirstSurvLoc = VSSMFirstCharSurvs.find(oldPlyId);
		if (arrFirstSurvLoc != null)
		{
			VSSMFirstCharSurvs[arrFirstSurvLoc] = newPlyId;
		}
		
		/*if (VSSMTransItemsTbl.len() != 0)
		{
			local survList = RetrieveSurvList(false);
			local gameSurvSlots = GetNumberOrderSlots(survList);
			//try {
				local oldSurvSlot = gameSurvSlots.find(oldPly);
				local newSurvSlot = gameSurvSlots.find(newPly);
				if (oldSurvSlot != null && newSurvSlot != null)
				{
					printl("oldSurvSlot: "+oldSurvSlot);
					printl("newSurvSlot: "+newSurvSlot);
					oldSurvSlot = oldSurvSlot.tostring();
					newSurvSlot = newSurvSlot.tostring();
					local hasOld = (oldSurvSlot in VSSMTransItemsTbl);
					local hasNew = (newSurvSlot in VSSMTransItemsTbl);
					
					if (hasOld) printl("VSSMTransItemsTbl["+oldSurvSlot+"] before: "+VSSMTransItemsTbl[oldSurvSlot]);
					if (hasNew) printl("VSSMTransItemsTbl["+newSurvSlot+"] before: "+VSSMTransItemsTbl[newSurvSlot]);
					if (hasOld && hasNew)
					{
						local tempTbl = VSSMTransItemsTbl[oldSurvSlot];
						VSSMTransItemsTbl[oldSurvSlot] <- VSSMTransItemsTbl[newSurvSlot];
						VSSMTransItemsTbl[newSurvSlot] <- tempTbl;
					}
					else
					{
						if (hasOld)
						{
							VSSMTransItemsTbl[newSurvSlot] <- delete VSSMTransItemsTbl[oldSurvSlot];
						}
						if (hasNew)
						{
							VSSMTransItemsTbl[oldSurvSlot] <- delete VSSMTransItemsTbl[newSurvSlot];
						}
					}
					if (oldSurvSlot in VSSMTransItemsTbl) printl("VSSMTransItemsTbl["+oldSurvSlot+"] after: "+VSSMTransItemsTbl[oldSurvSlot]);
					if (newSurvSlot in VSSMTransItemsTbl) printl("VSSMTransItemsTbl["+newSurvSlot+"] after: "+VSSMTransItemsTbl[newSurvSlot]);
				}
			//} catch (err) {ClientPrint(null, 3, "aw fuck: "+err);}
		}*/
		
		local newChar = NetProps.GetPropInt(newPly, "m_survivorCharacter");
		//printl("newPly m_survivorCharacter: "+newChar)
		if (GetSurvSet() == 1 && newChar < 4) newPly.SetContext("who","",0);
		if (newChar != survChar) SetCharacter(newPly, survChar);
		
		if (newPly.ValidateScriptScope())
		{
			local clScope = newPly.GetScriptScope();
			if ("VSSMSpawned" in clScope)
			{ delete clScope.VSSMSpawned; }
		}
	}
	
	function OnGameEvent_player_bot_replace(params)
	{
		if (!("player" in params) || !("bot" in params)) return;
		DoReplace(params["player"], params["bot"]);
	}
	
	function OnGameEvent_bot_player_replace(params)
	{
		if (!("player" in params) || !("bot" in params)) return;
		DoReplace(params["bot"], params["player"]);
	}
	
	// there is too much fucking data like pins, etc, to transfer over
	// and shit can go horribly wrong very easily
	/*function Takeover(main, target)
	{
		local switchData = [
			NetProps.GetPropInt(target, "m_iTeamNum"), // 0
			NetProps.GetPropInt(main, "m_iTeamNum"),
			target.GetOrigin(), // 2
			main.GetOrigin(),
			target.GetAngles(), // 4
			main.GetAngles(),
			NetProps.GetPropInt(target, "m_iObserverMode"), // 6
			NetProps.GetPropInt(main, "m_iObserverMode"),
			NetProps.GetPropInt(target, "m_hObserverTarget"), // 8
			NetProps.GetPropInt(main, "m_hObserverTarget"),
			NetProps.GetPropInt(target, "m_iMaxHealth"), // 10
			NetProps.GetPropInt(main, "m_iMaxHealth"),
			NetProps.GetPropInt(target, "m_iHealth"), // 12
			NetProps.GetPropInt(main, "m_iHealth"),
			NetProps.GetPropInt(target, "m_lifeState"), // 14
			NetProps.GetPropInt(main, "m_lifeState"),
			NetProps.GetPropInt(target, "m_survivorCharacter"), // 16
			NetProps.GetPropInt(main, "m_survivorCharacter"),
			NetProps.GetPropInt(target, "m_zombieClass"), // 18
			NetProps.GetPropInt(main, "m_zombieClass"),
			NetProps.GetPropInt(target, "m_zombieState"), // 20
			NetProps.GetPropInt(main, "m_zombieState"),
			NetProps.GetPropInt(target, "m_isIncapacitated"), // 22
			NetProps.GetPropInt(main, "m_isIncapacitated"),
		];
		//local addData = [];
		
		for (local i = 0; i <= 1; i++)
		{
			local client = (i == 1) ? target : main;
			//local chosenVictim = (i != 1) ? target : main;
			
			NetProps.SetPropInt(client, "m_iTeamNum", switchData[0 + i]);
			client.SetOrigin(switchData[2 + i]);
			client.SetAngles(switchData[4 + i]);
			NetProps.SetPropInt(client, "m_iObserverMode", switchData[6 + i]);
			NetProps.SetPropInt(client, "m_hObserverTarget", switchData[8 + i]);
			NetProps.SetPropInt(client, "m_iMaxHealth", switchData[10 + i]);
			NetProps.SetPropInt(client, "m_iHealth", switchData[12 + i]);
			NetProps.SetPropInt(client, "m_lifeState", switchData[14 + i]);
			NetProps.SetPropInt(client, "m_survivorCharacter", switchData[16 + i]);
			NetProps.SetPropInt(client, "m_zombieClass", switchData[18 + i]);
			NetProps.SetPropInt(client, "m_zombieState", switchData[20 + i]);
			NetProps.SetPropInt(client, "m_isIncapacitated", switchData[22 + i]);
			NetProps.SetPropInt(client, "m_isIncapacitated", switchData[22 + i]);
			
			//switch (switchData[0 + i])
			//{
			//case 2:
			//	if (!(i in addData))
			//	{
			//		addData[i].append();
			//		addData[i] <- [
			//			NetProps.GetPropInt(chosenVictim, "m_survivorCharacter"),
			//		];
			//	}
				//NetProps.SetPropInt(client, "m_survivorCharacter", switchData[14 + i]);
				
				
			//	break;
			//}
			
			//switch (switchData[12 + i])
			//{
			//case 0:
			//	NetProps.SetPropInt(client, "m_iHealth", NetProps.GetPropInt(chosenVictim, "m_iHealth"));
			//	break;
			//default:
			//	break;
			//}
		}
	}*/
	function SimpleTakeover(main, target)
	{
		if (!main.IsSurvivor() || !target.IsSurvivor()) return;
		
		local switchData = [
			NetProps.GetPropInt(target, "m_iTeamNum"), // 0
			NetProps.GetPropInt(main, "m_iTeamNum"),
			target.GetOrigin(), // 2
			main.GetOrigin(),
			target.EyeAngles(), // 4
			main.EyeAngles(),
			NetProps.GetPropInt(target, "m_iObserverMode"), // 6
			NetProps.GetPropInt(main, "m_iObserverMode"),
			NetProps.GetPropInt(target, "m_hObserverTarget"), // 8
			NetProps.GetPropInt(main, "m_hObserverTarget"),
			NetProps.GetPropInt(target, "m_iMaxHealth"), // 10
			NetProps.GetPropInt(main, "m_iMaxHealth"),
			NetProps.GetPropInt(target, "m_iHealth"), // 12
			NetProps.GetPropInt(main, "m_iHealth"),
			NetProps.GetPropInt(target, "m_lifeState"), // 14
			NetProps.GetPropInt(main, "m_lifeState"),
			NetProps.GetPropInt(target, "m_survivorCharacter"), // 16
			NetProps.GetPropInt(main, "m_survivorCharacter"),
			NetProps.GetPropInt(target, "m_zombieClass"), // 18
			NetProps.GetPropInt(main, "m_zombieClass"),
			NetProps.GetPropInt(target, "m_zombieState"), // 20
			NetProps.GetPropInt(main, "m_zombieState"),
			NetProps.GetPropInt(target, "m_isIncapacitated"), // 22
			NetProps.GetPropInt(main, "m_isIncapacitated"),
			NetProps.GetPropInt(target, "m_isHangingFromLedge"), // 24
			NetProps.GetPropInt(main, "m_isHangingFromLedge"),
			NetProps.GetPropVector(target, "m_hangAirPos"), // 26
			NetProps.GetPropVector(main, "m_hangAirPos"),
			NetProps.GetPropVector(target, "m_hangPos"), // 28
			NetProps.GetPropVector(main, "m_hangPos"),
			NetProps.GetPropVector(target, "m_hangStandPos"), // 30
			NetProps.GetPropVector(main, "m_hangStandPos"),
			NetProps.GetPropVector(target, "m_hangNormal"), // 32
			NetProps.GetPropVector(main, "m_hangNormal"),
			NetProps.GetPropInt(target, "m_frustration"), // 34
			NetProps.GetPropInt(main, "m_frustration"),
			NetProps.GetPropInt(target, "m_clientIntensity"), // 36
			NetProps.GetPropInt(main, "m_clientIntensity"),
			NetProps.GetPropInt(target, "m_iPlayerState"), // 38
			NetProps.GetPropInt(main, "m_iPlayerState"),
			NetProps.GetPropInt(target, "pl.deadflag"), // 40
			NetProps.GetPropInt(main, "pl.deadflag"),
			NetProps.GetPropVector(target, "m_vecViewOffset"), // 42
			NetProps.GetPropVector(main, "m_vecViewOffset"),
			NetProps.GetPropInt(target, "m_iBonusProgress"), // 44
			NetProps.GetPropInt(main, "m_iBonusProgress"),
			NetProps.GetPropInt(target, "m_iBonusChallenge"), // 46
			NetProps.GetPropInt(main, "m_iBonusChallenge"),
			NetProps.GetPropEntity(target, "m_hViewEntity"), // 48
			NetProps.GetPropEntity(main, "m_hViewEntity"),
			NetProps.GetPropInt(target, "m_bDucked"), // 50
			NetProps.GetPropInt(main, "m_bDucked"),
			NetProps.GetPropInt(target, "m_bDucking"), // 52
			NetProps.GetPropInt(main, "m_bDucking"),
			NetProps.GetPropInt(target, "m_bInDuckJump"), // 54
			NetProps.GetPropInt(main, "m_bInDuckJump"),
			NetProps.GetPropInt(target, "m_nDuckTimeMsecs"), // 56
			NetProps.GetPropInt(main, "m_nDuckTimeMsecs"),
			NetProps.GetPropInt(target, "m_nDuckJumpTimeMsecs"), // 58
			NetProps.GetPropInt(main, "m_nDuckJumpTimeMsecs"),
			NetProps.GetPropInt(target, "m_nJumpTimeMsecs"), // 60
			NetProps.GetPropInt(main, "m_nJumpTimeMsecs"),
			NetProps.GetPropFloat(target, "m_flFallVelocity"), // 62
			NetProps.GetPropFloat(main, "m_flFallVelocity"),
			NetProps.GetPropEntity(target, "m_hUseEntity"), // 64
			NetProps.GetPropEntity(main, "m_hUseEntity"),
			NetProps.GetPropEntity(target, "m_hRagdoll"), // 66
			NetProps.GetPropEntity(main, "m_hRagdoll"),
			NetProps.GetPropVector(target, "m_lastLadderNormal"), // 68
			NetProps.GetPropVector(main, "m_lastLadderNormal"),
			NetProps.GetPropInt(target, "m_iShovePenalty"), // 70
			NetProps.GetPropInt(main, "m_iShovePenalty"),
			NetProps.GetPropFloat(target, "m_healthBuffer"), // 72
			NetProps.GetPropFloat(main, "m_healthBuffer"),
			NetProps.GetPropFloat(target, "m_healthBufferTime"), // 74
			NetProps.GetPropFloat(main, "m_healthBufferTime"),
			NetProps.GetPropFloat(target, "m_itTimer.m_duration"), // 76
			NetProps.GetPropFloat(main, "m_itTimer.m_duration"),
			NetProps.GetPropFloat(target, "m_itTimer.m_timestamp"), // 78
			NetProps.GetPropFloat(main, "m_itTimer.m_timestamp"),
			NetProps.GetPropInt(target, "m_isFallingFromLedge"), // 80
			NetProps.GetPropInt(main, "m_isFallingFromLedge"),
			NetProps.GetPropInt(target, "m_currentReviveCount"), // 82
			NetProps.GetPropInt(main, "m_currentReviveCount"),
			NetProps.GetPropInt(target, "m_isGoingToDie"), // 84
			NetProps.GetPropInt(main, "m_isGoingToDie"),
			NetProps.GetPropFloat(target, "m_vomitStart"), // 86
			NetProps.GetPropFloat(main, "m_vomitStart"),
			NetProps.GetPropFloat(target, "m_vomitFadeStart"), // 88
			NetProps.GetPropFloat(main, "m_vomitFadeStart"),
			NetProps.GetPropFloat(target, "m_stunTimer.m_duration"), // 90
			NetProps.GetPropFloat(main, "m_stunTimer.m_duration"),
			NetProps.GetPropFloat(target, "m_stunTimer.m_timestamp"), // 92
			NetProps.GetPropFloat(main, "m_stunTimer.m_timestamp"),
			NetProps.GetPropFloat(target, "m_TimeForceExternalView"), // 94
			NetProps.GetPropFloat(main, "m_TimeForceExternalView"),
			target.GetVelocity(), // 96
			main.GetVelocity(),
			NetProps.GetPropInt(target, "m_MoveType"), // 98
			NetProps.GetPropInt(main, "m_MoveType"),
			NetProps.GetPropInt(target, "m_fFlags"), // 100
			NetProps.GetPropInt(main, "m_fFlags"),
			NetProps.GetPropInt(target, "m_iEFlags"), // 102
			NetProps.GetPropInt(main, "m_iEFlags"),
			NetProps.GetPropEntity(target, "m_hGroundEntity"), // 104
			NetProps.GetPropEntity(main, "m_hGroundEntity"),
			NetProps.GetPropVector(target, "m_Collision.m_vecMins"), // 106
			NetProps.GetPropVector(main, "m_Collision.m_vecMins"),
			NetProps.GetPropVector(target, "m_Collision.m_vecMaxs"), // 108
			NetProps.GetPropVector(main, "m_Collision.m_vecMaxs"),
			NetProps.GetPropInt(target, "cslocaldata.m_duckUntilOnGround"), // 110
			NetProps.GetPropInt(main, "cslocaldata.m_duckUntilOnGround"),
		];
		
		local mainAmmo = {};
		local targetAmmo = {};
		for (local i = 0; i < NetProps.GetPropArraySize(main, "m_iAmmo"); i++)
		{
			local ammo = NetProps.GetPropIntArray(main, "m_iAmmo", i);
			if (ammo == 0) continue;
			mainAmmo[i] <- ammo;
			NetProps.SetPropIntArray(main, "m_iAmmo", 0, i); // clear else we dupe ammo
		}
		for (local i = 0; i < NetProps.GetPropArraySize(target, "m_iAmmo"); i++)
		{
			local ammo = NetProps.GetPropIntArray(target, "m_iAmmo", i);
			if (ammo == 0) continue;
			targetAmmo[i] <- ammo;
			NetProps.SetPropIntArray(target, "m_iAmmo", 0, i); // clear else we dupe ammo
		}
		foreach (key, ammo in mainAmmo)
		{
			NetProps.SetPropIntArray(target, "m_iAmmo", ammo, key);
		}
		foreach (key, ammo in targetAmmo)
		{
			NetProps.SetPropIntArray(main, "m_iAmmo", ammo, key);
		}
		mainAmmo.clear();
		targetAmmo.clear();
		
		local mainInvTable = {};
		local targetInvTable = {};
		GetInvTable(main, mainInvTable);
		GetInvTable(target, targetInvTable);
		foreach (key, val in mainInvTable)
		{
			local valClass = val.GetClassname();
			if (NetProps.HasProp(val, "m_isDualWielding") && NetProps.GetPropInt(val, "m_isDualWielding") != 0)
			{
				NetProps.SetPropInt(val, "m_isDualWielding", 0);
				local hackWep = SpawnEntityFromTable(valClass, {
					origin = val.GetOrigin().ToKVString(),
					angles = val.GetAngles().ToKVString(),
				});
				DoEntFire("!self", "Use", "", 0, target, hackWep);
			}
			else if (NetProps.HasProp(val, "m_bRedraw") && NetProps.GetPropInt(val, "m_bRedraw") != 0)
			{
				// m_bRedraw is 1 when grenade is thrown, but using sb_takecontrol
				// can glitch the grenade as an unusable item presumably depleted of
				// ammo, and m_bRedraw is 0
				// eh, works checking for it, the game still makes it unusable
				// so no infinite grenades regardless
				val.Kill();
				continue;
			}
			survManager.DropItemCheck(main, valClass);
			DoEntFire("!self", "Use", "", 0, target, val);
		}
		foreach (key, val in targetInvTable)
		{
			local valClass = val.GetClassname();
			if (NetProps.HasProp(val, "m_isDualWielding") && NetProps.GetPropInt(val, "m_isDualWielding") != 0)
			{
				NetProps.SetPropInt(val, "m_isDualWielding", 0);
				local hackWep = SpawnEntityFromTable(valClass, {
					origin = val.GetOrigin().ToKVString(),
					angles = val.GetAngles().ToKVString(),
				});
				DoEntFire("!self", "Use", "", 0, main, hackWep);
			}
			else if (NetProps.HasProp(val, "m_bRedraw") && NetProps.GetPropInt(val, "m_bRedraw") != 0)
			{
				val.Kill();
				continue;
			}
			survManager.DropItemCheck(target, valClass);
			DoEntFire("!self", "Use", "", 0, main, val);
		}
		
		for (local i = 0; i <= 1; i++)
		{
			local client = (i == 1) ? target : main;
			//local otherClient = (i != 1) ? target : main;
			
			if (NetProps.GetPropInt(client, "m_isIncapacitated") != 0)
				NetProps.SetPropInt(client, "m_isIncapacitated", 0);
			
			client.Stagger(Vector());
			NetProps.SetPropFloat(client, "m_staggerTimer.m_duration", 0);
			NetProps.SetPropFloat(client, "m_staggerTimer.m_timestamp", 0);
			
			NetProps.SetPropInt(client, "m_iTeamNum", switchData[0 + i]);
			client.SetOrigin(switchData[2 + i]);
			client.SnapEyeAngles(switchData[4 + i]);
			NetProps.SetPropInt(client, "m_iObserverMode", switchData[6 + i]);
			NetProps.SetPropInt(client, "m_hObserverTarget", switchData[8 + i]);
			NetProps.SetPropInt(client, "m_iMaxHealth", switchData[10 + i]);
			NetProps.SetPropInt(client, "m_iHealth", switchData[12 + i]);
			NetProps.SetPropInt(client, "m_lifeState", switchData[14 + i]);
			SetCharacter(client, switchData[16 + i]);
			NetProps.SetPropInt(client, "m_zombieClass", switchData[18 + i]);
			NetProps.SetPropInt(client, "m_zombieState", switchData[20 + i]);
			NetProps.SetPropInt(client, "m_isIncapacitated", switchData[22 + i]);
			NetProps.SetPropInt(client, "m_isHangingFromLedge", switchData[24 + i]);
			NetProps.SetPropVector(client, "m_hangAirPos", switchData[26 + i]);
			NetProps.SetPropVector(client, "m_hangPos", switchData[28 + i]);
			NetProps.SetPropVector(client, "m_hangStandPos", switchData[30 + i]);
			NetProps.SetPropVector(client, "m_hangNormal", switchData[32 + i]);
			NetProps.SetPropInt(client, "m_frustration", switchData[34 + i]);
			NetProps.SetPropInt(client, "m_clientIntensity", switchData[36 + i]);
			NetProps.SetPropInt(client, "m_iPlayerState", switchData[38 + i]);
			NetProps.SetPropInt(client, "pl.deadflag", switchData[40 + i]);
			NetProps.SetPropVector(client, "m_vecViewOffset", switchData[42 + i]);
			NetProps.SetPropInt(client, "m_iBonusProgress", switchData[44 + i]);
			NetProps.SetPropInt(client, "m_iBonusChallenge", switchData[46 + i]);
			NetProps.SetPropEntity(client, "m_hViewEntity", switchData[48 + i]);
			NetProps.SetPropInt(client, "m_bDucked", switchData[50 + i]);
			NetProps.SetPropInt(client, "m_bDucking", switchData[52 + i]);
			NetProps.SetPropInt(client, "m_bInDuckJump", switchData[54 + i]);
			NetProps.SetPropInt(client, "m_nDuckTimeMsecs", switchData[56 + i]);
			NetProps.SetPropInt(client, "m_nDuckJumpTimeMsecs", switchData[58 + i]);
			NetProps.SetPropInt(client, "m_nJumpTimeMsecs", switchData[60 + i]);
			NetProps.SetPropFloat(client, "m_flFallVelocity", switchData[62 + i]);
			NetProps.SetPropEntity(client, "m_hUseEntity", switchData[64 + i]);
			NetProps.SetPropEntity(client, "m_hRagdoll", switchData[66 + i]);
			NetProps.SetPropVector(client, "m_lastLadderNormal", switchData[68 + i]);
			NetProps.SetPropInt(client, "m_iShovePenalty", switchData[70 + i]);
			NetProps.SetPropFloat(client, "m_healthBuffer", switchData[72 + i]);
			NetProps.SetPropFloat(client, "m_healthBufferTime", switchData[74 + i]);
			NetProps.SetPropFloat(client, "m_itTimer.m_duration", switchData[76 + i]);
			NetProps.SetPropFloat(client, "m_itTimer.m_timestamp", switchData[78 + i]);
			NetProps.SetPropInt(client, "m_isFallingFromLedge", switchData[80 + i]);
			client.SetReviveCount(switchData[82 + i]);
			NetProps.SetPropInt(client, "m_isGoingToDie", switchData[84 + i]);
			NetProps.SetPropFloat(client, "m_vomitStart", switchData[86 + i]);
			NetProps.SetPropFloat(client, "m_vomitFadeStart", switchData[88 + i]);
			NetProps.SetPropFloat(client, "m_stunTimer.m_duration", switchData[90 + i]);
			NetProps.SetPropFloat(client, "m_stunTimer.m_timestamp", switchData[92 + i]);
			NetProps.SetPropFloat(client, "m_TimeForceExternalView", switchData[94 + i]);
			client.SetVelocity(switchData[96 + i]);
			NetProps.SetPropInt(client, "m_MoveType", switchData[98 + i]);
			NetProps.SetPropFloat(client, "m_flProgressBarDuration", 0);
			NetProps.SetPropFloat(client, "m_flProgressBarStartTime", 0);
			NetProps.SetPropEntity(client, "m_useActionOwner", null);
			NetProps.SetPropEntity(client, "m_useActionTarget", null);
			NetProps.SetPropInt(client, "m_iCurrentUseAction", 0);
			NetProps.SetPropEntity(client, "m_reviveOwner", null);
			NetProps.SetPropEntity(client, "m_reviveTarget", null);
			// don't transfer FL_FAKECLIENT flags
			local flagData = switchData[100 + i];
			if (flagData & (1 << 8))
				flagData = flagData &~ (1 << 8);
			// TODO: FL_DUCKING (1 << 1) is problematic, persists on bots
			// makes them slow and crouched while standing
			// but can't exactly remove it like FL_FAKECLIENT, you get stuck
			// in overhangs you crouch under
			NetProps.SetPropInt(client, "m_fFlags", flagData);
			
			NetProps.SetPropInt(client, "m_iEFlags", switchData[102 + i]);
			NetProps.SetPropEntity(client, "m_hGroundEntity", switchData[104 + i]);
			NetProps.SetPropVector(client, "m_Collision.m_vecMins", switchData[106 + i]);
			NetProps.SetPropVector(client, "m_Collision.m_vecMaxs", switchData[108 + i]);
			NetProps.SetPropInt(client, "cslocaldata.m_duckUntilOnGround", switchData[110 + i]);
			
			/*if (switchData[106 + i] != null && switchData[106 + i] != client && NetProps.HasProp(switchData[106 + i], "m_useActionOwner"))
			{
				NetProps.SetPropEntity(switchData[106 + i], "m_useActionOwner", otherClient);
			}
			if (switchData[112 + i] != null && switchData[112 + i] != client && NetProps.HasProp(switchData[112 + i], "m_reviveOwner"))
			{
				NetProps.SetPropEntity(switchData[112 + i], "m_reviveOwner", otherClient);
			}*/
			
			DoEntFire("!self", "CancelCurrentScene", "", 0, null, client);
		}
		
		local entVarList = RetrieveEntVarList(true);
		if (entVarList.len() != 0)
		{
			foreach (key, ent in entVarList)
			{
				ent.GetScriptScope().SwapIds(main.GetPlayerUserId(), target.GetPlayerUserId(), true);
			}
		}
	}
	
	// --=EVENT=-- General Duplicate/5+ Survivor Fixes
	function ConvertThroughSets(char)
	{
		switch (char)
		{
			case 0: return 4;
			case 1: return 5;
			case 2: return 7;
			case 3: return 6;
			case 4: return 0;
			case 5: return 1;
			case 6: return 3;
			case 7: return 2;
		}
		return null;
	}
	
	function OnGameEvent_player_death( params )
	{
		if ( !("userid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsValid() || !client.IsSurvivor() || 
		(!client.IsDead() && !client.IsDying()) ) return;
		
		local survId = client.GetPlayerUserId();
		local char = NetProps.GetPropInt(client, "m_survivorCharacter");
		
		for (local body; body = Entities.FindByClassname( body, "survivor_death_model" );)
		{
			local bodyChar = NetProps.GetPropInt(body, "m_nCharacterType");
			if (bodyChar != char || !body.ValidateScriptScope()) continue;
			
			local bodyScope = body.GetScriptScope();
			if ("VSSMId" in bodyScope) continue;
			
			bodyScope.VSSMId <- survId;
			body.SetOrigin(client.GetOrigin());
			if (!("SwapIds" in bodyScope) || bodyScope.SwapIds == null)
				bodyScope.SwapIds <- DefibSwapIds.weakref();
			
			EntVarFunc(body, true);
			break;
		}
		
		local ability = NetProps.GetPropEntity(client, "m_customAbility");
		if (ability != null && NetProps.HasProp(ability, "m_isCharging") && 
		client.ValidateScriptScope())
		{
			local clScope = client.GetScriptScope();
			if ("VSSMTrig" in clScope && clScope.VSSMTrig != null && 
			clScope.VSSMTrig.IsValid())
			{
				clScope.VSSMTrig.Kill();
			}
		}
		
		/*if (GetSurvSet() == 1 && char >= 4 && char <= 7)
		{
			if (client.ValidateScriptScope())
			{
				local clScope = client.GetScriptScope();
				clScope.VSSMOrigChar <- char;
			}
			NetProps.SetPropInt(client, "m_survivorCharacter", ConvertThroughSets(char));
		}*/
		/*if (GetSurvSet() == 1 && char >= 4 && char <= 7)
		{
			local survList = survManager.RetrieveSurvList();
			foreach (key, loopClient in survList)
			{
				if (NetProps.GetPropInt(loopClient, "m_iTeamNum") != 2) continue;
				switch (char)
				{
				case 4: // nick
					loopClient.SetContext("DeadCharacter", "gambler", 2);
					break;
				case 5: // rochelle
					loopClient.SetContext("DeadCharacter", "producer", 2);
					break;
				case 6: // ellis
					loopClient.SetContext("DeadCharacter", "mechanic", 2);
					break;
				case 7: // coach
					loopClient.SetContext("DeadCharacter", "coach", 2);
					break;
				}
				printl("Adding death context to "+loopClient)
			}
		}*/
	}
	
	// --=EVENT=-- Fix for fake L4D2 survivors using L4D1 rescue closet callouts
	function OnGameEvent_survivor_call_for_help( params )
	{
		if ( GetSurvSet() != 1 || !("userid" in params) || !("subject" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null ) return;
		
		local char = NetProps.GetPropInt(client, "m_survivorCharacter");
		switch (char)
		{
		case 4: case 5: case 6: case 7:
			break;
		default:
			return;
			break;
		}
		
		local rescue = EntIndexToHScript( params["subject"] );
		if ( rescue == null ) return;
		
		local who = client.GetContext("who");
		QueueSpeak(rescue, "CallForRescue", 0, "who:"+who);
	}
	
	// TODO work on witch attack alteration more
	/*function OnGameEvent_infected_hurt( params )
	{
		if ( !("attacker" in params) || !("entityid" in params) || 
		!("type" in params) ) return;
		
		local witch = EntIndexToHScript( params["entityid"] );
		if ( witch == null || !witch.IsValid() || witch.GetClassname() != "witch" || NetProps.GetPropInt(witch, "m_lifeState") != 0 ) return;
		
		local client = GetPlayerFromUserID( params["attacker"] );
		if ( client == null || !client.IsValid() || !client.IsSurvivor() || NetProps.GetPropInt(client, "m_lifeState") != 0 ) return;
		
		if ((params["type"] & (1 << 28))) return; 
		
		local witchScope = witch.GetScriptScope();
		local hasTarget = ("VSSMTarget" in witchScope && witchScope.VSSMTarget != null && witchScope.VSSMTarget.IsValid());
		// (1 << 28) DMG_DIRECT according to SM, entityflame does this so ignore
		if (
		(params["type"] & DirectorScript.DMG_BURN && !(params["type"] & (1 << 28)))
		 || 
		(witchScope == null || !hasTarget)
		)
		{
			if (witchScope == null)
			{
				if (!witch.ValidateScriptScope()) return;
				witchScope = witch.GetScriptScope();
			}
			
			if (!hasTarget || witchScope.VSSMTarget != client)
			{
				witchScope.VSSMTarget <- client;
				
				DoEntFire("!self", "RunScriptCode", "survManager.WitchAttackFunc1(self, activator)", 0, client, witch);
				DoEntFire("!self", "RunScriptCode", "survManager.WitchAttackFunc2(self, activator)", 0.01, client, witch);
			//	local effectEnt = NetProps.GetPropEntity(witch, "m_hEffectEntity");
			//	if (effectEnt != null && effectEnt.GetClassname() == "entityflame")
			//	{
			//		//NetProps.SetPropEntity(effectEnt, "m_hOwnerEntity", client);
			//		effectEnt.Kill();
			//		
			//		local newEffectEnt = SpawnEntityFromTable("entityflame", {
			//			origin = effectEnt.GetOrigin()
			//		});
			//		NetProps.SetPropFloat(newEffectEnt, "m_flLifetime", NetProps.GetPropFloat(effectEnt, "m_flLifetime"));
			//		NetProps.SetPropEntity(newEffectEnt, "m_hEntAttached", witch);
			//		NetProps.SetPropInt(newEffectEnt, "m_iDangerSound", NetProps.GetPropInt(effectEnt, "m_iDangerSound"));
			//		NetProps.SetPropEntity(witch, "m_hEffectEntity", newEffectEnt);
			//	}
			}
		}
	}
	
	function OnGameEvent_witch_harasser_set( params )
	{
		if ( !("userid" in params) || !("witchid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsValid() || !client.IsSurvivor() ) return;
		local witch = EntIndexToHScript( params["witchid"] );
		if ( witch == null || !witch.IsValid() ) return;
		
		local witchScope = witch.GetScriptScope();
		// (1 << 28) DMG_DIRECT according to SM, entityflame does this so ignore
		if (witchScope != null && (!("VSSMTarget" in witchScope) || witchScope.VSSMTarget == null || !witchScope.VSSMTarget.IsValid()))
		{
			// If no damage was inflicted, get the look target
			local lookTarg = NetProps.GetPropEntity(witch, "m_clientLookatTarget");
			if (lookTarg != null && lookTarg != client && lookTarg != GetPlayerFromCharacter(NetProps.GetPropInt(client, "m_survivorCharacter")))
			{
				if (witchScope == null)
				{
					if (!witch.ValidateScriptScope()) return;
					witchScope = witch.GetScriptScope();
				}
				
				// Immediate crash if the witch AI is reset here
				//CommandABot({
				//	bot = witch,
				//	cmd = DirectorScript.BOT_CMD_RESET,
				//});
				DoEntFire("!self", "RunScriptCode", "survManager.WitchAttackFunc1(self, activator)", 0, lookTarg, witch);
				DoEntFire("!self", "RunScriptCode", "survManager.WitchAttackFunc2(self, activator)", 0.01, lookTarg, witch);
				
				witchScope.VSSMTarget <- lookTarg;
				//NetProps.SetPropFloat(witch, "m_rage", 1);
				//CommandABot({
				//	bot = witch,
				//	cmd = DirectorScript.BOT_CMD_ATTACK,
				//	target = lookTarg,
				//});
				//NetProps.SetPropInt(lookTarg, "m_iTeamNum", oldTeam);
			}
			else
			{
				if (witchScope == null)
				{
					if (!witch.ValidateScriptScope()) return;
					witchScope = witch.GetScriptScope();
				}
				witchScope.VSSMTarget <- client;
			}
		}
	}
	function WitchAttackFunc1(self, activator)
	{
		if (activator == null) return;
		
		CommandABot({
			bot = self,
			cmd = DirectorScript.BOT_CMD_RESET,
		});
	}
	function WitchAttackFunc2(self, activator)
	{
		if (activator == null) return;
		
		local oldTeam = NetProps.GetPropInt(activator, "m_iTeamNum");
		NetProps.SetPropInt(activator, "m_iTeamNum", 3);
		NetProps.SetPropFloat(self, "m_rage", 1);
		CommandABot({
			bot = self,
			cmd = DirectorScript.BOT_CMD_ATTACK,
			target = activator,
		});
		NetProps.SetPropInt(activator, "m_iTeamNum", oldTeam);
	}*/
	
	// --=EVENT=-- Fix Upgrade Pack
	function OnGameEvent_upgrade_pack_added( params )
	{
		if (!Settings.fixUpgradePacks) return;
		//g_ModeScript.DeepPrintTable(params)
		if ( !("userid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsValid() ) return;
		local upgradeBox = EntIndexToHScript( params["upgradeid"] );
		if ( upgradeBox == null || !upgradeBox.IsValid() || upgradeBox.GetClassname().slice(0, 13) != "upgrade_ammo_" || !upgradeBox.ValidateScriptScope() ) return;
		
		NetProps.SetPropInt(upgradeBox, "m_itemCount", 4); // didn't know about this, doh
		local boxScope = upgradeBox.GetScriptScope();
		if (!("survIdList" in boxScope))
		{
			boxScope.survIdList <- [];
			// downside to using user id is the id stays with
			// you when you switch bots
			// unfortunately given having to account for m_survivorCharacter clones
			// and the fact l4d2's player system is dog doodoo this is the best for now
			EntVarFunc(upgradeBox, true);
			boxScope.SwapIds <- function(oldPlyId, newPlyId, noDel = null)
			{
				local oldIdLoc = this.survIdList.find(oldPlyId);
				if (noDel == null)
				{
					if (oldIdLoc != null)
						this.survIdList[oldIdLoc] = newPlyId;
				}
				else
				{
					local newIdLoc = this.survIdList.find(newPlyId);
					if (newIdLoc == null && oldIdLoc != null)
						this.survIdList[oldIdLoc] = newPlyId;
					if (oldIdLoc == null && newIdLoc != null)
						this.survIdList[newIdLoc] = oldPlyId;
				}
			}
			
			// Bots bypass the input denying by never Useing in the first place
			boxScope["Input"+GetFromStringTable("Use", upgradeBox)] <- function()
			{
				if (activator != null && activator.IsValid() && activator.IsPlayer())
				{
					local activatorId = activator.GetPlayerUserId();
					if ("userChar" in this && this.userChar[1] == activatorId) return true;
					if (this.survIdList.find(activatorId) != null)
					{
						local time = Time();
						if (!("LastUseTime" in this) || this.LastUseTime < time)
						{
							this.LastUseTime <- time + 0.25;
							//g_ModeScript.DeepPrintTable(this.survIdList);
							/*FireGameEvent("upgrade_item_already_used", {
								upgradeclass = self.GetClassname(),
								userid = activatorId,
								splitscreenplayer = 0,
							});*/
							
							if (!("userDo" in this))
							{
								this.userDo <- function()
								{
									NetProps.SetPropInt(self, "m_iUsedBySurvivorsMask", 1);
									
									if (activator != null)
									{
										this.userChar <- [
											NetProps.GetPropInt(activator, "m_survivorCharacter"),
											activator.GetPlayerUserId(),
										];
										NetProps.SetPropInt(activator, "m_survivorCharacter", 0);
									}
								}
							}
							if (!("userSet" in this))
							{
								this.userSet <- function()
								{
									NetProps.SetPropInt(self, "m_iUsedBySurvivorsMask", 0);
									
									if ("userChar" in this)
									{
										if (activator != null) NetProps.SetPropInt(activator, "m_survivorCharacter", this.userChar[0]);
										delete this.userChar;
									}
								}
							}
							
							DoEntFire("!self", "CallScriptFunction", "userDo", 0, activator, self);
							DoEntFire("!self", "Use", "", 0, activator, self);
							DoEntFire("!self", "CallScriptFunction", "userSet", 0, activator, self);
						}
						return false;
					}
				}
				else
				{ return false; }
				return true;
			}
			boxScope.Unmask <- function()
			{
				NetProps.SetPropInt(self, "m_iUsedBySurvivorsMask", 0);
			}
		}
		
		if (boxScope.survIdList.find(params["userid"]) == null)
		{
			boxScope.survIdList.append(params["userid"]);
			local survList = survManager.RetrieveSurvList(false);
			local survListLen = survList.len();
			for (local i = 0; i < survListLen; i++)
			{
				if (NetProps.GetPropInt(survList[i], "m_iTeamNum") != 2)
				{
					survListLen = survListLen - 1;
				}
			}
			if (boxScope.survIdList.len() >= survListLen)
			{
				//printl("IVE RAN OUT :(")
				upgradeBox.Kill();
				return;
			}
		}
		else
		{
			// stop bots from repeatedly getting ammo
			// have to give them just 1 ammo so they won't repeatedly try to take it
			if (IsPlayerABot(client))
			{
				local primaryWep = {}; GetInvTable(client, primaryWep);
				if ("slot0" in primaryWep && primaryWep.slot0 != null)
				{
					primaryWep = primaryWep.slot0;
					local loadedAmmo = NetProps.GetPropInt(primaryWep, "m_nUpgradedPrimaryAmmoLoaded");
					if (loadedAmmo > 1)
					{
						local ammoType = NetProps.GetPropInt(primaryWep, "m_iPrimaryAmmoType");
						//printl("ammo before: "+NetProps.GetPropIntArray(client, "m_iAmmo", ammoType))
						
						NetProps.SetPropIntArray(client, "m_iAmmo", (NetProps.GetPropIntArray(client, "m_iAmmo", ammoType) - (loadedAmmo-1)), ammoType);
						NetProps.SetPropInt(primaryWep, "m_nUpgradedPrimaryAmmoLoaded", 1);
						//printl("ammo after: "+NetProps.GetPropIntArray(client, "m_iAmmo", ammoType))
					}
				}
			}
		}
		
		DoEntFire("!self", "CallScriptFunction", "Unmask", 0, null, upgradeBox);
		
		//g_ModeScript.DeepPrintTable(ownerScope.survIdList);
		//NetProps.SetPropInt(upgradeBox, "m_fEffects", (NetProps.GetPropInt(upgradeBox, "m_fEffects") | (1 << 5)));
		// Interestingly setting EF_NODRAW on pack disallows it from being used normally
	}
	
	// --=EVENT=-- Charger Clone Survivor Hits Fix
	function ChargeColliStart()
	{
		if (activator == null) return;
		NetProps.SetPropInt(activator, "m_CollisionGroup", 11);
	}
	
	function ChargeColliEnd()
	{
		if (activator == null) return;
		NetProps.SetPropInt(activator, "m_CollisionGroup", 5);
	}
	
	function Fling(client, victim)
	{
		local clOrigin = client.GetOrigin();
		local forwardVec = clOrigin + client.GetForwardVector();
		
		local distance = Vector(
			(clOrigin.x - forwardVec.x),
			(clOrigin.y - forwardVec.y),
			(clOrigin.z - forwardVec.z)
		);
		local tVec = NetProps.GetPropVector(client, "m_vecVelocity");
		
		local ratio_x = distance.x / sqrt(distance.y * distance.y + distance.x * distance.x);//Ratio x/hypo
		local ratio_y = distance.y / sqrt(distance.y * distance.y + distance.x * distance.x);//Ratio y/hypo
		
		local addVel = Vector(
			//ratio.x * -1 * 500.0,
			//ratio.y * -1 * 500.0,
			-(ratio_x) * 500.0,
			-(ratio_y) * 500.0,
			500.0
		);
		
		//NetProps.SetPropVector(victim, "m_vecAbsVelocity", NetProps.GetPropVector(victim, "m_vecAbsVelocity") + addVel);
		victim.ApplyAbsVelocityImpulse(addVel);
		//NetProps.SetPropVector(victim, "m_vecBaseVelocity", addVel);
		return addVel;
	}
	
	function OnGameEvent_charger_charge_start( params )
	{
		if (!Settings.fixChargerHits) return;
		local charger = GetPlayerFromUserID( params["userid"] );
		if ( charger == null || !charger.IsValid() || !charger.ValidateScriptScope() ) return;
		
		local chargerScope = charger.GetScriptScope();
		if (!("VSSMTrig" in chargerScope) || chargerScope.VSSMTrig == null || 
		!chargerScope.VSSMTrig.IsValid())
		{
			local chargerOrigin = charger.GetOrigin();
			local trig = SpawnEntityFromTable("script_trigger_multiple", {
				//targetname = "testTrig",
				origin = chargerOrigin,
				spawnflags = 1,
				connections =
				{
					OnStartTouch =
					{
						cmd1 = "!selfCallScriptFunctionSTouchFix0-1"
					}
					/*OnEndTouch =
					{
						cmd1 = "!selfCallScriptFunctionETouchFix0.5-1"
					}*/
				}
			});
			if (trig == null) return;
			if (!trig.ValidateScriptScope()) {trig.Kill();return;}
			
			local trigScope = trig.GetScriptScope();
			trigScope.Owner <- charger;
			chargerScope.VSSMTrig <- trig;
			trigScope.knockCharList <- [];
			//trigScope.userChar <- [];
			trigScope.knockIdList <- [];
			EntVarFunc(trig, true);
			trigScope.SwapIds <- function(oldPlyId, newPlyId, noDel = null)
			{
				local oldIdLoc = this.knockIdList.find(oldPlyId);
				if (noDel == null)
				{
					if (oldIdLoc != null)
						this.knockIdList[oldIdLoc] = newPlyId;
				}
				else
				{
					local newIdLoc = this.knockIdList.find(newPlyId);
					if (newIdLoc == null && oldIdLoc != null)
						this.knockIdList[oldIdLoc] = newPlyId;
					if (oldIdLoc == null && newIdLoc != null)
						this.knockIdList[newIdLoc] = oldPlyId;
				}
			}
			
			// v (vector : (-16.000000, -16.000000, 0.000000)
			local mins = NetProps.GetPropVector(charger, "m_Collision.m_vecMins") - Vector(5,5,5);
			NetProps.SetPropVector(trig, "m_Collision.m_vecMins", mins);
			NetProps.SetPropVector(trig, "m_Collision.m_vecSpecifiedSurroundingMins", mins);
			// v (vector : (16.000000, 16.000000, 71.000000)
			local maxs = NetProps.GetPropVector(charger, "m_Collision.m_vecMaxs") + Vector(5,5,5);
			NetProps.SetPropVector(trig, "m_Collision.m_vecMaxs", maxs);
			NetProps.SetPropVector(trig, "m_Collision.m_vecSpecifiedSurroundingMaxs", maxs);
			
		//	NetProps.SetPropEntity(trig, "m_pParent", charger);
		//	NetProps.SetPropEntity(trig, "m_hMoveParent", charger);
		//	NetProps.SetPropInt(trig, "m_MoveType", 0);
		//	NetProps.SetPropVector(trig, "m_vecAbsOrigin", chargerOrigin);
			
		//	local moveChild = null;
		//	for ( moveChild = client.FirstMoveChild(); moveChild != null; moveChild = moveChild.NextMovePeer() )
		//	{
		//		if (!moveChild.IsValid() || moveChild.GetClassname() != "weapon_pistol") continue;
		//		origWeps = moveChild;
		//		break;
		//	}
			// m_airMovementRestricted doesn't seem to be added on charge impact
			DoEntFire("!self", "SetParent", "!activator", 0, charger, trig);
			DoEntFire("!self", "CallScriptFunction", "Readjust", 0, null, trig);
			trigScope.Readjust <- function()
			{
				if (!Owner.IsValid()) return;
				self.SetOrigin(Vector(0,0,0));
			}
			local worldSpawn = Entities.First();
			if (worldSpawn.ValidateScriptScope())
			{
				local worldScope = worldSpawn.GetScriptScope();
				if (!("VSSMChargeS" in worldScope) || worldScope.VSSMChargeS == null)
					worldScope.VSSMChargeS <- survManager.ChargeColliStart.weakref()
				if (!("VSSMChargeE" in worldScope) || worldScope.VSSMChargeE == null)
					worldScope.VSSMChargeE <- survManager.ChargeColliEnd.weakref()
				
				/*{
					//if (this.userChar.len() == 0) return;
					if (activator == null) return;
					//if (activator == null) {this.userChar.remove(0);return;}
					//NetProps.SetPropInt(activator, "m_CollisionGroup", this.userChar[0]);
					NetProps.SetPropInt(activator, "m_CollisionGroup", 5);
					//NetProps.SetPropInt(activator, "m_usSolidFlags", NetProps.GetPropInt(activator, "m_usSolidFlags") &~ (1 << 2));
					//this.userChar.remove(0);
				}*/
			}
			
			trigScope.STouchFix <- function()
			{
				local dev = developer();
				if (dev) printl("STouchFix triggered, activator: "+activator);
				if (activator == null || activator == Owner || !activator.IsValid() || 
				!activator.IsSurvivor() || 
				NetProps.GetPropEntity(activator, "m_pounceAttacker") != null || 
				NetProps.GetPropEntity(activator, "m_pummelAttacker") != null) return;
				local carrier = NetProps.GetPropEntity(activator, "m_carryAttacker");
				if (carrier != null && carrier != Owner) return;
				
				local char = NetProps.GetPropInt(activator, "m_survivorCharacter");
				local userId = activator.GetPlayerUserId();
				if (knockIdList.find(userId) != null) return;
				if (knockCharList.find(char) != null)
				{
					if (carrier == Owner)
					{
						knockCharList.append(char);
						return;
					}
					knockIdList.append(userId);
					if (dev) printl("Attempting Charge Fix")
					
					local chargeDmg = Convars.GetFloat("z_charge_max_damage");
					switch (GetDifficulty())
					{
						case 0:
							chargeDmg = chargeDmg * 0.5;
							break;
						case 2:
							chargeDmg = chargeDmg * 1.5;
							break;
						case 3:
							chargeDmg = chargeDmg * 2;
							break;
					}
					
					local vecForce = survManager.Fling(Owner, activator);
					activator.TakeDamageEx(Owner, Owner, null, 
					vecForce, Owner.GetOrigin(), 
					chargeDmg, 
					(1 << 7)); // DMG_CLUB
					EmitSoundOn("ChargerZombie.HitPerson", activator);
					
					// TakeDamage does seem to kill you if low enough hp
					if (activator.IsDying() || activator.IsDead() || 
					NetProps.GetPropEntity(activator, "m_positionEntity") != null)
					{
						FireGameEvent("charger_impact", {
							userid = Owner.GetPlayerUserId(),
							victim = userId,
						});
						return;
					}
					
					activator.Stagger(Vector());
					NetProps.SetPropFloat(activator, "m_staggerTimer.m_duration", 0);
					NetProps.SetPropFloat(activator, "m_staggerTimer.m_timestamp", 0);
					
					local stunTime = 3;
					
					if (VSSMSpawner == null || !VSSMSpawner.IsValid()) survManager.EnsureSpawner();
					if (VSSMSpawner != null && VSSMSpawner.IsValid())
					{
						local entScope = VSSMSpawner.GetScriptScope();
						entScope.ToggleClient(activator, true);
						stunTime = 99;
					}
					
					local time = Time();
					NetProps.SetPropFloat(activator, "m_stunTimer.m_duration", stunTime);
					local timeDur = time+stunTime;
					NetProps.SetPropFloat(activator, "m_stunTimer.m_timestamp", timeDur);
					NetProps.SetPropFloat(activator, "m_jumpSupressedUntil", timeDur);
					NetProps.SetPropFloat(activator, "m_TimeForceExternalView", timeDur);
					
					FireGameEvent("charger_impact", {
						userid = Owner.GetPlayerUserId(),
						victim = userId,
					});
					
					// ACT_TERROR_IDLE_FALL_FROM_CHARGERHIT
					// m_iPlayerState 1 seems to freeze player similar to 
					// interactions like first aid kit healing
					
					//NetProps.SetPropInt(activator, "m_fFlags", NetProps.GetPropInt(activator, "m_fFlags") &~ (1<<0)); // FL_ONGROUND
					
					// easy: 5
					// normal: 10
					// hard: 15
					// impossible: 20
					
					//trigScope.userChar.append(NetProps.GetPropInt(activator, "m_CollisionGroup"));
					//NetProps.SetPropInt(activator, "m_CollisionGroup", 1);
					//NetProps.SetPropInt(activator, "m_usSolidFlags", NetProps.GetPropInt(activator, "m_usSolidFlags") | (1 << 2)); // FSOLID_NOT_SOLID
					local worldSpawn = Entities.First();
					DoEntFire("!self", "CallScriptFunction", "VSSMChargeS", 0.02, activator, worldSpawn);
					DoEntFire("!self", "CallScriptFunction", "VSSMChargeE", 1, activator, worldSpawn);
				}
				else
				{ knockCharList.append(char); }
			}
			
			/*trigScope.ETouchFix <- function()
			{
				if (activator == null || activator == Owner || !activator.IsValid() || 
				(!activator.IsDead() && !activator.IsDying())) return;
				
				NetProps.SetPropInt(activator, "m_CollisionGroup", 5);
			}*/
		}
		else
		{
			chargerScope.VSSMTrig.Enable();
			chargerScope.VSSMTrig.SetAngles(QAngle(0,0,0))
		}
	}
	
	function ChargerGrabOrImpact( params )
	{
		if (!Settings.fixChargerHits) return;
		local victim = GetPlayerFromUserID( params["victim"] );
		if ( victim == null || !victim.IsValid() ) return;
		local charger = GetPlayerFromUserID( params["userid"] );
		if ( charger == null || !charger.IsValid() || !charger.ValidateScriptScope() ) return;
		
		local chargerScope = charger.GetScriptScope();
		if ("VSSMTrig" in chargerScope && chargerScope.VSSMTrig != null && 
		chargerScope.VSSMTrig.IsValid() && chargerScope.VSSMTrig.ValidateScriptScope())
		{
			local trigScope = chargerScope.VSSMTrig.GetScriptScope();
			if (trigScope.knockIdList.find(params["victim"]) == null) trigScope.knockIdList.append(params["victim"]);
			local char = NetProps.GetPropInt(victim, "m_survivorCharacter");
			if (trigScope.knockCharList.find(char) == null) trigScope.knockCharList.append(char);
		}
	}
	
	function OnGameEvent_charger_charge_end( params )
	{
		if (!Settings.fixChargerHits) return;
		local charger = GetPlayerFromUserID( params["userid"] );
		if ( charger == null || !charger.IsValid() || !charger.ValidateScriptScope() ) return;
		
		local chargerScope = charger.GetScriptScope();
		if ("VSSMTrig" in chargerScope && chargerScope.VSSMTrig != null && 
		chargerScope.VSSMTrig.IsValid() && chargerScope.VSSMTrig.ValidateScriptScope())
		{
			local trigScope = chargerScope.VSSMTrig.GetScriptScope();
			//trigScope.userChar.clear();
			trigScope.knockCharList.clear();
			trigScope.knockIdList.clear();
			chargerScope.VSSMTrig.Disable();
		}
	}
	
	// --=EVENT=-- Defib Clone Survivor Fix
	function DefibSwapIds(oldPlyId, newPlyId, noDel = null)
	{
		if (!("VSSMId" in this)) return;
		if (noDel == null)
		{
			if (this.VSSMId == oldPlyId)
				this.VSSMId = newPlyId;
		}
		else
		{
			if (this.VSSMId == oldPlyId)
				this.VSSMId = newPlyId;
			else if (this.VSSMId == newPlyId)
				this.VSSMId = oldPlyId;
		}
	}
	
	function DefibCheck()
	{
		if (activator == null || !activator.IsValid() || !("VSSMId" in this)) return;
		local useObj = NetProps.GetPropEntity(activator, "m_useActionTarget");
		//printl("body m_useActionOwner: "+user) // m_useActionOwner is invalid on body
		if (useObj != self) return;
		
		local isTimeUp = (Time() >= NetProps.GetPropFloat(activator, "m_flProgressBarStartTime") + NetProps.GetPropFloat(activator, "m_flProgressBarDuration")-0.15);
		//printl("isTimeUp: "+isTimeUp)
		if (!isTimeUp) return;
		
		// TODO: very shit solution!!!!
		// defibrillator events dont fire if a proper L4D1 survivor doesn't exist 
		// and does not fire proper defibrillator_used event for sourcemod
		// why are we still here
		// just to suffer
		
		local client = GetPlayerFromUserID(this.VSSMId);
		if (client == null) return;
		
		// L4D1 surv set definitely has GetPlayerFromCharacter affected
		local char = NetProps.GetPropInt(client, "m_survivorCharacter");
		if (GetPlayerFromCharacter(char) == client) return;
		
		local testchar = NetProps.GetPropInt(client, "m_survivorCharacter");
		if (developer()) printl("likely revived: "+client);
		
		activator.Stagger(Vector());
		NetProps.SetPropFloat(activator, "m_staggerTimer.m_duration", 0);
		NetProps.SetPropFloat(activator, "m_staggerTimer.m_timestamp", 0);
		local moveChild = null;
		for ( moveChild = activator.FirstMoveChild(); moveChild != null; moveChild = moveChild.NextMovePeer() )
		{
			if (!moveChild.IsValid() || moveChild.GetClassname() != "weapon_defibrillator") continue;
			DoEntFire("!self", "Kill", "", 0, null, moveChild);
			break;
		}
		
		local victimName = (IsPlayerABot(client)) ? GetCharacterDisplayName(client) : client.GetPlayerName();
		local rescuerName = (IsPlayerABot(activator)) ? GetCharacterDisplayName(activator) : activator.GetPlayerName();
		
		local survList = survManager.RetrieveSurvList(false);
		local survCharList = [];
		for (local i = 0; i < survList.len(); i++)
		{
			survCharList.append(NetProps.GetPropInt(survList[i], "m_survivorCharacter"));
			if (survList[i] == client)
			{
				if (survManager.GetSurvSet() == 1 && char >= 4 && char <= 7)
				{
					local newChar = survManager.ConvertThroughSets(char);
					NetProps.SetPropInt(client, "m_survivorCharacter", newChar);
					NetProps.SetPropInt(self, "m_nCharacterType", newChar);
				}
				else
					NetProps.SetPropInt(self, "m_nCharacterType", char);
			}
			else
				NetProps.SetPropInt(survList[i], "m_survivorCharacter", 8);
		}
		local entVarList = survManager.RetrieveEntVarList(false);
		local entCharList = [];
		for (local i = 0; i < entVarList.len(); i++)
		{
			if (!NetProps.HasProp(entVarList[i], "m_nCharacterType") || entVarList[i] == self)
			{
				entVarList.remove(i);
				i = i - 1;
				continue;
			}
			entCharList.append(NetProps.GetPropInt(entVarList[i], "m_nCharacterType"));
			NetProps.SetPropInt(entVarList[i], "m_nCharacterType", 8);
		}
		client.ReviveByDefib();
		FireGameEvent("defibrillator_used", {
			userid = activator.GetPlayerUserId(),
			subject = client.GetPlayerUserId(),
		});
		ClientPrint(null, 3, "\x04"+rescuerName+" brought "+victimName+" back from the dead");
		
		if (survCharList.len() != 0)
		{
			for (local i = 0; i < survList.len(); i++)
			{
				NetProps.SetPropInt(survList[i], "m_survivorCharacter", survCharList[i]);
			}
		}
		if (entVarList.len() != 0)
		{
			for (local i = 0; i < entVarList.len(); i++)
			{
				NetProps.SetPropInt(entVarList[i], "m_nCharacterType", entCharList[i]);
			}
		}
	}
	
	function OnGameEvent_defibrillator_begin( params )
	{
		if (!Settings.fixDefibrillator) return;
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsValid() ) return;
		local body = NetProps.GetPropEntity(client, "m_useActionTarget");
		if ( body == null || !body.IsValid() || body.GetClassname() != "survivor_death_model" || !body.ValidateScriptScope() ) return;
		
		local bodyScope = body.GetScriptScope();
		if (!("VSSMId" in bodyScope)) return;
		
		local duration = NetProps.GetPropFloat(client, "m_flProgressBarDuration");
		//printl("m_flProgressBarDuration: "+duration)
		//printl("m_useActionTarget: "+body)
		
		if (duration > 0.15)
		{
			if (!("VSSMDefib" in bodyScope) || bodyScope.VSSMDefib == null)
				bodyScope.VSSMDefib <- DefibCheck.weakref();
			
			DoEntFire("!self", "CallScriptFunction", "VSSMDefib", duration-0.15, client, body);
		}
		else
		{
			bodyScope.activator <- client;
			bodyScope.VSSMDefib <- DefibCheck.weakref();
			bodyScope.VSSMDefib();
		}
	}
	
	// --=EVENT=-- Friendly Fire Lines Fix
	function OnGameEvent_player_hurt( params )
	{
		if (!Settings.fixFriendlyFireLines) return;
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsSurvivor() /*|| client.GetSurvivorSlot() <= 3*/ ) return;
		// Would've loved to optimize it so it won't play on the 4 survivors that will
		// emit friendly fire lines by themselves, but apparently it's NOT slots
		// or player entity order that dictates these 4 special survivors
		local attacker = GetPlayerFromUserID( params["attacker"] );
		if ( attacker == null || !attacker.IsSurvivor() || attacker == client ) return;
		
		if (ResponseCriteria.HasCriterion(client, "FriendlyFire"))
		{
			local context = null;
			try
			{context = ResponseCriteria.GetValue(client, "FriendlyFire").tointeger();}
			catch (err)
			{context = 0;}
			
			if (context >= 1) return;
		}
		
		local time = Time();
		if (friendlyFireTime > time)
			return;
		else
			friendlyFireTime = time + 2;
		
		local contextName = null;
		if (ResponseCriteria.HasCriterion(attacker, "who"))
		{
			contextName = ResponseCriteria.GetValue(attacker, "who");
		}
		else
		{
			local isT4 = (NetProps.GetPropInt(attacker, "m_iTeamNum") == 4);
			if (isT4) NetProps.SetPropInt(attacker, "m_iTeamNum", 2);
			contextName = GetCharacterDisplayName(attacker);
			if (isT4) NetProps.SetPropInt(attacker, "m_iTeamNum", 4);
			
			switch (contextName)
			{
			case "Nick":		contextName = "Gambler";	break;
			case "Rochelle":	contextName = "Producer";	break;
			case "Coach":		contextName = "Coach";		break;
			case "Ellis":		contextName = "Mechanic";	break;
			case "Bill":		contextName = "NamVet";		break;
			case "Zoey":		contextName = "TeenGirl";	break;
			case "Louis":		contextName = "Manager";	break;
			case "Francis":		contextName = "Biker";		break;
			default:			contextName = null;			break;
			}
		}
		
		local dmgType = null;
		if ("type" in params && params["type"])
		{
			if (params["type"] & DirectorScript.DMG_BULLET)
				dmgType = "DMG_BULLET";
			else if (params["type"] & (1 << 7)) // DMG_CLUB
				dmgType = "DMG_CLUB";
			else if (params["type"] & (1 << 2)) // DMG_SLASH
				dmgType = "DMG_SLASH";
			
			if (dmgType == null) return;
			
			/*if (!(params["type"] & DirectorScript.DMG_BULLET) && 
			//!(params["type"] & DirectorScript.DMG_BLAST) && 
			!(params["type"] & (1 << 7)) && // DMG_CLUB
			!(params["type"] & (1 << 2))) // DMG_SLASH
				return;*/
		}
		
		if (contextName == null)
			contextName = "Unknown";
		
		QueueSpeak(client, "PlayerFriendlyFire", 0.5, "subject:"+contextName+",damagetype:"+dmgType);
	}
	
	function SpecCheck()
	{
		local survList = survManager.RetrieveSurvList(false);
		local takenIds = [];
		local availableBots = [];
		local deadBots = [];
		foreach (key, client in survList)
		{
			if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
			if (NetProps.HasProp(client, "m_humanSpectatorUserID"))
			{
				if (client.IsDead() || client.IsDying())
				{
					deadBots.append(client);
				}
				else
				{
					local humanID = NetProps.GetPropInt(client, "m_humanSpectatorUserID");
					if (humanID == 0)
						availableBots.append(client);
					else
						takenIds.append(humanID);
				}
			}
		}
		
		//local specTblAvailable = (specTbl.len() != 0);
		local specList = survManager.RetrieveSpecList(false);
		for (local i = 0; i < specList.len(); i++)
		{
			if (IsPlayerABot(specList[i]) || 
			NetProps.GetPropInt(specList[i], "m_iTeamNum") == 3)
			{
				specList.remove(i); i = i - 1;
				continue;
			}
			if (takenIds.find(specList[i].GetPlayerUserId()) != null)
			{
				printl("[VSSM] "+specList[i].GetPlayerName()+" already has a bot!");
				specList.remove(i); i = i - 1;
				continue;
			}
		//	if (specTblAvailable)
		//	{
		//		local idStr = specList.GetNetworkIDString();
		//		local findIdStr = specTbl.find(idStr);
		//		if (findIdStr != null)
		//		{
		//			//specTbl.remove(findIdStr);
		//			specList.remove(i); i = i - 1;
		//			continue;
		//		}
		//	}
		}
		if (availableBots.len() != 0)
		{
			for (local i = 0; i < specList.len(); i++)
			{
				if (availableBots.len() == 0) break;
				printl("[VSSM] Trying to find bot for "+specList[i].GetPlayerName());
				printl("[VSSM] Found a suitable survivor bot: "+availableBots[0]);
				
				local userid = specList[i].GetPlayerUserId();
				// set to 1 first
				NetProps.SetPropInt(specList[i], "m_iTeamNum", 1);
				NetProps.SetPropInt(availableBots[0], "m_humanSpectatorUserID", userid);
				NetProps.SetPropInt(availableBots[0], "m_humanSpectatorEntIndex", specList[i].GetEntityIndex());
				NetProps.SetPropInt(specList[i], "m_iObserverMode", 5);
				NetProps.SetPropEntity(specList[i], "m_hObserverTarget", availableBots[0]);
				//NetProps.SetPropInt(specList[i], "m_fFlags", NetProps.GetPropInt(specList[i], "m_fFlags") & (1 << 26)); // IN_IDLE (1 << 26)
			//	if (specList[i].ValidateScriptScope())
			//	{
			//		local specScope = specList[i].GetScriptScope();
			//		if (!("VSSMTemp") in specScope)
			//		{
			//			specScope.VSSMTemp <- function()
			//			{
			//				NetProps.SetPropInt(self, "m_afButtonForced", NetProps.GetPropInt(self, "m_afButtonForced") &~ (1 << 0));
			//				delete this.VSSMTemp;
			//			}
			//		}
			//		NetProps.SetPropInt(specList[i], "m_afButtonForced", NetProps.GetPropInt(specList[i], "m_afButtonForced") | (1 << 0));
			//		DoEntFire("!self", "CallScriptFunction", "VSSMTemp", 1, null, specList[i]);
			//		printl("m_afButtonForced: "+NetProps.GetPropInt(specList[i], "m_afButtonForced"))
			//	}
				
				availableBots.remove(0);
				survManager.SpecListFunc(userid, false);
				specList.remove(i); i = i - 1;
				// Remove from spec list to try and prevent resetting them again
			}
		}
		if (deadBots.len() != 0)
		{
			for (local i = 0; i < specList.len(); i++)
			{
				if (deadBots.len() == 0) break;
				printl("[VSSM] Trying to find DEAD bot for "+specList[i].GetPlayerName());
				
				printl("[VSSM] Found a suitable DEAD survivor bot, replacing: "+deadBots[0]);
				
				specList[i].SetOrigin(deadBots[0].GetOrigin());
				specList[i].SetAngles(deadBots[0].GetAngles());
				NetProps.SetPropInt(specList[i], "m_iTeamNum", 2);
				NetProps.SetPropInt(specList[i], "m_survivorCharacter", NetProps.GetPropInt(deadBots[0], "m_survivorCharacter"));
				NetProps.SetPropInt(specList[i], "localdata.m_Local.m_bDrawViewmodel", 1);
				local userid = specList[i].GetPlayerUserId();
				FireGameEvent("bot_player_replace", {
					player = userid,
					bot = deadBots[0].GetPlayerUserId(),
				});
				deadBots[0].Kill();
				
				deadBots.remove(0);
				survManager.SpecListFunc(userid, false);
				specList.remove(i); i = i - 1;
				// Remove from spec list to try and prevent resetting them again
			}
		}
		// Damage control, disable this function until i can fix the
		// stupid problem without being fucking blind and completely restricted to singleplayer
		// thanks for being a piece of shit my network
		/*local remainingSpecs = (specList.len()-g_iBots);
		if (remainingSpecs != 0)
		{
			printl("[VSSM] Auto-spawning "+remainingSpecs+" bots due to lack of free bots");
			survManager.SpawnBot(remainingSpecs);
			DoEntFire("!self", "CallScriptFunction", "VSSMSpec", 0.25, null, self);
		}
		else
		{
			delete this.VSSMSpec;
		}*/
		delete this.VSSMSpec;
	}
	// team 4 survivors have own slots amongst GetSurvivorSlot and can
	// cause problems with saving stuff in slots
	// account for this
	function GetNumberOrderSlots(survList)
	{
		local slotsTbl = {};
		foreach (key, client in survList)
		{
			local survSlot = client.GetSurvivorSlot();
			//printl(client+" ("+client.GetPlayerName()+") GetSurvivorSlot: "+survSlot);
			if (NetProps.GetPropInt(client, "m_iTeamNum") != 2)
				slotsTbl[survSlot] <- null;
			else
				slotsTbl[survSlot] <- client;
		}
		
		local arrangedSlotsTbl = [];
		for (local i = 0; i < slotsTbl.len(); i++)
		{
			if ((i in slotsTbl) && slotsTbl[i] != null)
				arrangedSlotsTbl.append(slotsTbl[i]);
		}
		slotsTbl.clear();
		return arrangedSlotsTbl;
	}
	
	// --=EVENT=-- Spawn Bots
	// Decide which character to change the bot to
	// Must apply this function to script scope
	function CharCheck()
	{
		local survList = survManager.RetrieveSurvList(true);
		
		// handle first char survs list
		if (!(0 in VSSMFirstCharSurvs) && (0 in VSSMTransItemsTbl))
		{
			for (local i = 0; i <= 7; i++)
			{
				local handledChar = GetPlayerFromCharacter(i);
				if (handledChar != null)
					VSSMFirstCharSurvs.append(handledChar.GetPlayerUserId());
			}
		}
		
		local order = survManager.GetSurvOrder();
		if (order.len() == 0)
		{
			order = [0,1,2,3,4,5,6,7];
			printl("[VSSM] survCharOrderL4D"+survManager.GetSurvSet()+" setting is invalid!\nDefault 8-survivor order is used.");
		}
		// rearrange the order of first-joined survivors to accomodate
		// lobby selections
		//local firstOrder = null;
		local selectedSlots = null;
		if (VSSMCharsInit != null && VSSMCharsInit.len() != 0)
		{
			//printl("VSSMCharsInit:")
			//g_ModeScript.DeepPrintTable(VSSMCharsInit);
			selectedSlots = [];
			foreach (key, val in VSSMCharsInit)
			{
				local client = null;
				switch (typeof val)
				{
				case "instance":
					if (val.IsValid())
						client = val;
					break;
				case "integer":
					client = GetPlayerFromUserID(val);
					if (client == null)
					{
						VSSMCharsInit[key] = null;
						continue;
					}
					if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
					VSSMCharsInit[key] = client;
					break;
				}
				if (client == null) continue;
				
				local char = NetProps.GetPropInt(client, "m_survivorCharacter");
				switch (char)
				{
				case 0:
				case 1:
				case 2:
				case 3:
				case 4:
				case 5:
				case 6:
				case 7:
					break;
				default: char = null; break;
				}
				
				selectedSlots.append(char);
			}
			//printl("selectedSlots:")
			//g_ModeScript.DeepPrintTable(selectedSlots);
		}
		
		//local mapTrans = (VSSMStartWepsInit == null);
		/*switch (typeof VSSMCharsInit)
		{
		case "table":
		case "array":
			printl("VSSMCharsInit: ")
			g_ModeScript.DeepPrintTable(VSSMCharsInit)
			break;
		default:
			printl("VSSMCharsInit: "+VSSMCharsInit)
			break;
		}
		printl("VSSMStartWepsInit: "+VSSMStartWepsInit)*/
		local gameSurvSlots = survManager.GetNumberOrderSlots(survList);
		
		local doLobbyOrder = (selectedSlots != null && selectedSlots.len() != 0);
		//local doLobbyOrder = true;
		local availableSurvs = [];
		foreach (k,v in order) {availableSurvs.append(order[k]);}
		for (local i = 0; i < survList.len(); i++)
		{
			if (NetProps.GetPropInt(survList[i], "m_iTeamNum") != 2) continue;
			//if (i == key) continue; // ignore self
			
			if ("VSSMSpawned" in survList[i].GetScriptScope()) continue;
			
			local loopChar = NetProps.GetPropInt(survList[i], "m_survivorCharacter");
			
			local listLocArr = availableSurvs.find(loopChar);
			if (listLocArr != null)
			{
				availableSurvs.remove(listLocArr); i = i - 1;
			}
			
			if (!(0 in availableSurvs))
			{foreach (k,v in order) {availableSurvs.append(order[k]);} i = i + 1;}
			
			/*printl(client+" runchecks "+survList[i]+" "+i+":");
			foreach (k, v in availableSurvs)
			{
				if (k == availableSurvs.len()-1)
					printl(v)
				else
					print(v+",")
			}*/
		}
		
		local selSlot = 0;
		foreach (key, client in survList)
		{
			if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
			//printl("looping through "+client)
			
			local clScope = client.GetScriptScope();
			if (!("VSSMSpawned" in clScope))
			{
				// after map transition fake L4D2 survivors with GetSurvivorSlots
				// under 3 can lose who context, so reset here
				if (survManager.GetSurvSet() != 1) continue;
				
				survManager.SetCharacter(client, NetProps.GetPropInt(client, "m_survivorCharacter"), 0);
				continue;
			}
			delete clScope.VSSMSpawned;
			
			if (survManager.enforcedChars != null && (0 in survManager.enforcedChars && 1 in survManager.enforcedChars) && 
			survManager.enforcedChars[1] > 0)
			{
				survManager.SetCharacter(client, survManager.enforcedChars[0]);
				//printl("SetCharacter client "+client+" to "+survManager.enforcedChars[0])
				survManager.enforcedChars[1] = survManager.enforcedChars[1] - 1;
				if (survManager.enforcedChars[1] <= 0)
					survManager.enforcedChars = null;
			}
			else
			{
				local char = NetProps.GetPropInt(client, "m_survivorCharacter");
				if (doLobbyOrder)
				{
					local arrLoc = VSSMCharsInit.find(client);
					local availableSurvsLen = availableSurvs.len();
					if (arrLoc != null && (arrLoc in selectedSlots) && selectedSlots[arrLoc] != null)
					{
						//printl("availableSurvsLen-1 < selectedSlots[arrLoc]: "+(availableSurvsLen-1 < selectedSlots[arrLoc]))
						if (availableSurvsLen-1 < selectedSlots[arrLoc])
							selSlot = 0;
						else
						{
							selSlot = selectedSlots[arrLoc];
							foreach (key, val in selectedSlots)
							{
								if (val == 0) continue;
								// decrement every succeeding slot value by 1
								selectedSlots[key] -= 1;
							}
						}
					}
					else
						selSlot = 0;
				}
				
				//printl("availableSurvs: ");
				//g_ModeScript.DeepPrintTable(availableSurvs);
				//if (selectedSlots != null)
				//{
				//	printl("selectedSlots: ");
				//	g_ModeScript.DeepPrintTable(selectedSlots);
				//}
				
				//printl("selSlot is "+selSlot);
				if (availableSurvs[selSlot] != char)
				{
					survManager.SetCharacter(client, availableSurvs[selSlot]);
					//printl("SetCharacter client "+client+" to "+availableSurvs[selSlot])
				}
				
				availableSurvs.remove(selSlot);
				if (!(0 in availableSurvs))
				{
					foreach (k,v in order) {availableSurvs.append(order[k]);}
					doLobbyOrder = false;
					if (selectedSlots != null) selectedSlots.clear();
				}
			}
			
			local origWeps = null;
			for ( local moveChild = client.FirstMoveChild(); moveChild != null; moveChild = moveChild.NextMovePeer() )
			{
				if (!moveChild.IsValid() || moveChild.GetClassname().slice(0,7) != "weapon_") continue;
				if (origWeps == null) origWeps = [];
				origWeps.append(moveChild);
			}
			
			local survSlot = gameSurvSlots.find(client);
			if (survSlot != null)
			{
				local hasTransItems = survManager.RestoreTransItems(client, origWeps, survSlot, true);
				if (!hasTransItems && VSSMNoSpawnStartItemsTbl.find(client.GetPlayerUserId()) == null)
				{
					survManager.GiveStartItems(client, origWeps);
				}
			}
		}
		if (VSSMCharsInit != null)
		{VSSMCharsInit = null;}
	}
	
	function RoundStart()
	{
		//g_ModeScript.DeepPrintTable("survManagerList: "+survManagerList);
		//if (specTbl.len() == 0)
		//{RestoreTable("VSSM_PreferSpec", specTbl);}
		survManager.SpawnBot(0);
		if (VSSMStartWepsInit == null) VSSMStartWepsInit = true;
		if ("VSSMLoad" in this) delete this.VSSMLoad;
		
		if (survManager.Settings.autoCheckpointFirstAid)
		{
			local kitList = [];
			for (local firstAid; firstAid = Entities.FindByClassname( firstAid, "weapon_first_aid_kit_spawn" );)
			{
				if (firstAid == null) continue;
				kitList.append(firstAid);
			}
			
			if (0 in kitList)
			{
				// TODO checking mins and maxs is not perfect
				// changelevel trigger brushes can be non-cuboid or rotated
				for (local changeLevel; changeLevel = Entities.FindByClassname( changeLevel, "info_changelevel" );)
				{
					if (changeLevel == null) continue;
					
					local changeLevelIdx = changeLevel.GetEntityIndex();
					
					local changeLevelPos = changeLevel.GetOrigin();
					local changeLevelMins = changeLevelPos + NetProps.GetPropVector(changeLevel, "m_Collision.m_vecMins");
					local changeLevelMaxs = changeLevelPos + NetProps.GetPropVector(changeLevel, "m_Collision.m_vecMaxs");
					
					foreach (k, firstAid in kitList)
					{
						local kitPos = firstAid.GetOrigin();
						
						local hasPos1 = (kitPos.x >= changeLevelMins.x && kitPos.y >= changeLevelMins.y && kitPos.z >= changeLevelMins.z);
						local hasPos2 = (kitPos.x <= changeLevelMaxs.x && kitPos.y <= changeLevelMaxs.y && kitPos.z <= changeLevelMaxs.z);
						if (!hasPos1 || !hasPos2) continue;
						//if (!changeLevel.IsTouching(firstAid)) continue;
						
						local nearestNavArea = NavMesh.GetNearestNavArea(kitPos, 256, false, false);
						if (nearestNavArea != null)
						{
							if (!nearestNavArea.HasSpawnAttributes((1 << 11))) // CHECKPOINT
								continue;
						}
						
						// Entity Handle typeof == instance
						// Vector typeof == Vector
						if (survManager.changeLevelsItems == null)
							survManager.changeLevelsItems = {};
						if (!(changeLevelIdx in survManager.changeLevelsItems))
							survManager.changeLevelsItems[changeLevelIdx] <- [];
						
						survManager.changeLevelsItems[changeLevelIdx].append(firstAid);
					}
					
					if (changeLevelIdx in survManager.changeLevelsItems)
					{
						survManager.changeLevelsItems[changeLevelIdx].insert(0, survManager.changeLevelsItems[changeLevelIdx].len());
					}
				}
			}
			
			survManager.HandleCheckpointKits();
		}
		
		// garbage collection
		for (local i = 0; i < VSSMEssentialBots.len(); i++)
		{
			if (VSSMEssentialBots[i] == null || !VSSMEssentialBots[i].IsValid())
			{
				VSSMEssentialBots.remove(i);
				i = i - 1;
			}
		}
		local keysToRemove = [];
		foreach (key, value in infoSpawnedSurvsList)
		{
			local client = GetPlayerFromUserID(value);
			if (client == null)
				keysToRemove.append(key);
		}
		foreach (key, i in keysToRemove)
		{
			delete infoSpawnedSurvsList[i];
		}
	}
	
	function HandleCheckpointKits()
	{
		if (changeLevelsItems == null || survManager.Settings.survCount == 0) return;
		
		try {
		local idxsToRemove = null;
		foreach (changeLevelIdx, kitList in changeLevelsItems)
		{
			local totalAidCount = 0;
			foreach (key, aidKit in kitList)
			{
				if (aidKit == null || typeof aidKit != "instance" || !aidKit.IsValid()) continue;
				
				local count = NetProps.GetPropInt(aidKit, "m_itemCount");
				if (count < 1) count = 1;
				
				totalAidCount += count;
			}
			if (totalAidCount == 0) continue;
			
			local addCount = survManager.Settings.survCount - totalAidCount;
			//printl("addCount is "+addCount)
			local shouldAdd = (addCount > 0);
			//printl("shouldAdd is "+shouldAdd)
			local iteratingNum = shouldAdd ? 1 : -1;
			
			local addOffset = true;
			
			// first key should always be number of our total iterated kits
			for (local i = 0; (shouldAdd ? i < addCount : i > addCount); (shouldAdd ? i++ : i--))
			{
				/*switch (shouldAdd)
				{
				case true:
					if (kitList[0] == kitList.len())
						kitList[0] = 1;
					break;
				default:
					if (kitList[0] == 0)
						kitList[0] = kitList.len() - 1;
					break;
				}*/
				switch (kitList[0])
				{
				case kitList.len():
					kitList[0] = 1;
					break;
				case 0:
					kitList[0] = kitList.len() - 1;
					break;
				}
				if (addOffset)
				{
					switch (shouldAdd)
					{
					case true:
						if (typeof kitList[kitList[0]] == "instance" && kitList[kitList[0]].IsValid())
							kitList[0] += iteratingNum;
						break;
					default:
						if (typeof kitList[kitList[0]] == "array" && 0 in kitList[kitList[0]])
							kitList[0] += iteratingNum;
						break;
					}
					switch (kitList[0])
					{
					case kitList.len():
						kitList[0] = 1;
						break;
					case 0:
						kitList[0] = kitList.len() - 1;
						break;
					}
					addOffset = false;
				}
				//printl("kitList[0] is "+kitList[0])
				//printl("kitList.len() is "+kitList.len())
				
				local iteratingKey = kitList[0];
				switch (typeof kitList[iteratingKey])
				{
				case "instance":
					if (kitList[iteratingKey] == null || !kitList[iteratingKey].IsValid())
					{
						kitList.remove(iteratingKey);
						if (!(1 in kitList))
						{
							if (idxsToRemove == null) idxsToRemove = [];
							idxsToRemove.append(changeLevelIdx);
							i = addCount;
							break;
						}
					}
					else
					{
						if (shouldAdd)
						{
							//printl("Increasing "+kitList[iteratingKey]+"'s count by 1")
							// m_itemCount does not transfer over changelevels
							//NetProps.SetPropInt(kitList[iteratingKey], "m_itemCount", NetProps.GetPropInt(kitList[iteratingKey], "m_itemCount") + 1);
							// Bite the bullet and spawn new first aid kit spawns
							local newKit = SpawnEntityFromTable("weapon_first_aid_kit_spawn", {
								origin = kitList[iteratingKey].GetOrigin(),
								angles = kitList[iteratingKey].GetAngles().ToKVString(),
								targetname = kitList[iteratingKey].GetName(),
								spawnflags = NetProps.GetPropInt(kitList[iteratingKey], "m_spawnflags") | (1 << 0), // Enable Physics
								count = 1,
								glowrange = NetProps.GetPropFloat(kitList[iteratingKey], "m_flGlowRange"),
								weaponskin = NetProps.GetPropInt(kitList[iteratingKey], "m_nWeaponSkin"),
								solid = NetProps.GetPropInt(kitList[iteratingKey], "m_Collision.m_nSolidType"),
							});
							if (newKit != null)
							{
								if (iteratingKey + 1 == kitList.len())
									kitList.append(newKit);
								else
									kitList.insert(iteratingKey + 1, newKit);
								kitList[0] += iteratingNum;
								
								newKit.ApplyAbsVelocityImpulse(Vector((RandomInt(0, 1) == 1) ? 20 : -20, (RandomInt(0, 1) == 1) ? 20 : -20, (RandomInt(0, 1) == 1) ? 20 : -20));
							}
						}
						else
						{
							//printl("Decreasing "+kitList[iteratingKey]+"'s count by 1")
							local count = NetProps.GetPropInt(kitList[iteratingKey], "m_itemCount");
							if (count == 1)
							{
								local kitData = [
									kitList[iteratingKey].GetOrigin(),
									kitList[iteratingKey].GetAngles(),
									kitList[iteratingKey].GetName(),
									NetProps.GetPropInt(kitList[iteratingKey], "m_spawnflags"),
									NetProps.GetPropFloat(kitList[iteratingKey], "m_flGlowRange"),
									NetProps.GetPropInt(kitList[iteratingKey], "m_nWeaponSkin"),
									NetProps.GetPropInt(kitList[iteratingKey], "m_Collision.m_nSolidType"),
								];
								kitList[iteratingKey].Kill();
								kitList[iteratingKey] = kitData;
							}
							else
							{
								NetProps.SetPropInt(kitList[iteratingKey], "m_itemCount", NetProps.GetPropInt(kitList[iteratingKey], "m_itemCount") - 1);
							}
						}
						kitList[0] += iteratingNum;
					}
					break;
				case "array":
					if (!shouldAdd)
					{
						kitList[0] += iteratingNum;
						break;
					}
					//printl("Spawning new kit for "+kitList[iteratingKey])
					local newKit = SpawnEntityFromTable("weapon_first_aid_kit_spawn", {
						origin = kitList[iteratingKey][0],
						angles = kitList[iteratingKey][1].ToKVString(),
						targetname = kitList[iteratingKey][2],
						spawnflags = kitList[iteratingKey][3],
						count = 1,
						glowrange = kitList[iteratingKey][4],
						weaponskin = kitList[iteratingKey][5],
						solid = kitList[iteratingKey][6],
					});
					if (newKit != null)
					{
						kitList[iteratingKey] = newKit;
					}
					kitList[0] += iteratingNum;
					break;
				default:
					kitList[0] += iteratingNum;
					break;
				}
			}
		}
		if (idxsToRemove != null)
		{
			foreach (key, value in idxsToRemove)
			{
				delete changeLevelsItems[value];
			}
		}
		
		/*foreach (changeLevelIdx, kitList in changeLevelsItems)
		{
			g_ModeScript.DeepPrintTable(kitList);
		}*/
		
		} catch (err) {
			ClientPrint(null, 3, "\x03"+"[VSSM] "+"\x01"+"Something went wrong with autoCheckpointFirstAid! Error: "+err);
		}
	}
	
	function GetPosHack()
	{
		local isSuccessful = null;
		if (activator != null)
		{
			local posEnt = NetProps.GetPropEntity(activator, "m_positionEntity");
			//printl("m_positionEntity: "+posEnt);
			if (posEnt != null)
			{
				isSuccessful = true;
				DoEntFire("!self", "CallScriptFunction", "IFOverride1", 0, null, activator);
				DoEntFire("!self", "ReleaseFromSurvivorPosition", "", 0, null, activator);
				DoEntFire("!self", "CallScriptFunction", "IFOverride0", 0, null, activator);
				local char = NetProps.GetPropInt(activator, "m_survivorCharacter");
				if (char in ::infoSpawnedSurvsList)
				{
					local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[char]);
					if (infoBot != null)
					{
						DoEntFire("!self", "TeleportToSurvivorPosition", NetProps.GetPropString(posEnt, "m_iName"), 0, null, infoBot);
					}
				}
			}
		}
		DoEntFire("!self", "CallScriptFunction", "VSSMPHFunc2", 0, (isSuccessful != null) ? activator : null, self);
	}
	function GetPosHack2()
	{
		if (!("VSSMPosHack" in this)) return;
		if (activator != null)
		{
			activator.SetOrigin(this.VSSMPosHack[0][0]);
			activator.SnapEyeAngles(this.VSSMPosHack[0][1]);
			activator.SetVelocity(this.VSSMPosHack[0][2]);
			if (3 in this.VSSMPosHack[0] && this.VSSMPosHack[0][3].IsValid())
			{
				DoEntFire("!self", "RunScriptCode", "self.__KeyValueFromString(\"targetname\",\"vssmtelehack\")", 0, null, this.VSSMPosHack[0][3]);
				DoEntFire("!self", "CallScriptFunction", "IFOverride1", 0, null, activator);
				DoEntFire("!self", "TeleportToSurvivorPosition", "vssmtelehack", 0, null, activator);
				DoEntFire("!self", "CallScriptFunction", "IFOverride0", 0, null, activator);
				DoEntFire("!self", "RunScriptCode", "self.__KeyValueFromString(\"targetname\",\""+NetProps.GetPropString(this.VSSMPosHack[0][3], "m_iName")+"\")", 0, null, this.VSSMPosHack[0][3]);
			}
		}
		if (1 in this.VSSMPosHack)
		{
			this.VSSMPosHack.remove(0);
		}
		else
		{
			delete this.VSSMPosHack;
		}
	}
	
	function GetGlowHack()
	{
		if (!("VSSMGlowHack" in this)) return;
		
		if (activator != null)
		{
			local glowNew = NetProps.GetPropInt(activator, "m_bSurvivorGlowEnabled");
			NetProps.SetPropInt(activator, "m_bSurvivorGlowEnabled", this.VSSMGlowHack[0]);
			local char = NetProps.GetPropInt(activator, "m_survivorCharacter");
			if (char in ::infoSpawnedSurvsList)
			{
				local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[char]);
				if (infoBot != null)
				{
					NetProps.SetPropInt(infoBot, "m_bSurvivorGlowEnabled", glowNew);
				}
			}
		}
		if (1 in this.VSSMGlowHack)
		{
			this.VSSMGlowHack.remove(0);
		}
		else
		{
			delete this.VSSMGlowHack;
		}
	}
	
	function IFOverride0()
	{if ("VSSMIFOvr" in this) delete this.VSSMIFOvr;}
	function IFOverride1()
	{if (!("VSSMIFOvr" in this)) this.VSSMIFOvr <- null;}
	function IFKill()
	{
		//g_ModeScript.DeepPrintTable(this);
		//printl("IFKill char: "+NetProps.GetPropInt(self, "m_survivorCharacter"))
		//local isBot = IsPlayerABot(self);
		switch (NetProps.GetPropInt(self, "m_iTeamNum"))
		{
		case 2:
			local char = NetProps.GetPropInt(self, "m_survivorCharacter");
			if (char in ::infoSpawnedSurvsList)
			{
				local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[char]);
				if (infoBot != null)
				{
					DoEntFire("!self", "Kill", "", 0, activator, infoBot);
					printl("[VSSM] Game tried to remove survivor ("+self.GetPlayerName()+", "+self+") with Kill input. VSSM has forwarded input to Team 4 survivor.");
					return false;
				}
			}
			break;
		case 3:
		case 4:
			if (IsPlayerABot(self)) return true;
			break;
		}
		printl("[VSSM] Game tried to remove survivor ("+self.GetPlayerName()+", "+self+") with Kill input. VSSM has blocked input.");
		return false;
	}
	// It's a massive fuckup to ever even fire KillHierarchy on any player once
	// Don't ever allow it to go through
	function IFKillHierarchy()
	{
		error("[VSSM][WARNING] Game tried to REMOVE SURVIVOR IMPROPERLY ("+self.GetPlayerName()+", "+self+") with KillHierarchy input! VSSM has blocked input, but beware!\n");
		return false;
	}
	function IFTeleportToSurvivorPosition()
	{
		if ("VSSMIFOvr" in this) return true;
		switch (NetProps.GetPropInt(self, "m_iTeamNum"))
		{
		case 2:
			local char = NetProps.GetPropInt(self, "m_survivorCharacter");
			switch (char)
			{
			case 4: case 5: case 6: case 7:
			//	local survList = survManager.RetrieveSurvList(false);
			//	foreach (key, loopClient in survList)
			//	{
			//		if (NetProps.GetPropInt(loopClient, "m_iTeamNum") != 4 || 
			//		NetProps.GetPropInt(loopClient, "m_survivorCharacter") != char) continue;
			//		DoEntFire("!self", "TeleportToSurvivorPosition", "", 0, activator, loopClient);
			//		break;
			//	}
				if (char in ::infoSpawnedSurvsList)
				{
					local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[char]);
					if (infoBot != null)
					{
						// can't get the input data on input hook, stupid
						local worldSpawn = Entities.First();
						if (worldSpawn.ValidateScriptScope())
						{
							local worldScope = worldSpawn.GetScriptScope();
							if (!("VSSMPHFunc" in worldScope) || worldScope.VSSMPHFunc == null)
								worldScope.VSSMPHFunc <- survManager.GetPosHack.weakref();
							if (!("VSSMPHFunc2" in worldScope) || worldScope.VSSMPHFunc2 == null)
								worldScope.VSSMPHFunc2 <- survManager.GetPosHack2.weakref();
							if (!("VSSMPosHack" in worldScope))
								worldScope.VSSMPosHack <- [];
							
							local varList = [
								self.GetOrigin(),
								self.EyeAngles(),
								self.GetVelocity()
							];
							local oldPos = NetProps.GetPropEntity(self, "m_positionEntity");
							if (oldPos != null)
								varList.append(oldPos);
							
							worldScope.VSSMPosHack.append(varList);
							
							DoEntFire("!self", "CallScriptFunction", "VSSMPHFunc", 0, self, worldSpawn);
						}
						return true;
					}
				}
				return false;
				break;
			}
			break;
		}
		return true;
	}
	function IFReleaseFromSurvivorPosition()
	{
		if ("VSSMIFOvr" in this) return true;
		switch (NetProps.GetPropInt(self, "m_iTeamNum"))
		{
		case 2:
			local char = NetProps.GetPropInt(self, "m_survivorCharacter");
			switch (char)
			{
			case 4: case 5: case 6: case 7:
				local char = NetProps.GetPropInt(self, "m_survivorCharacter");
				if (char in ::infoSpawnedSurvsList)
				{
					local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[char]);
					if (infoBot != null)
					{
						DoEntFire("!self", "ReleaseFromSurvivorPosition", "", 0, activator, infoBot);
					}
				}
				break;
			}
			break;
		}
		return true;
	}
	function IFSetGlowEnabled()
	{
		if ("VSSMIFOvr" in this) return true;
		switch (NetProps.GetPropInt(self, "m_iTeamNum"))
		{
		case 2:
			local char = NetProps.GetPropInt(self, "m_survivorCharacter");
			switch (char)
			{
			case 4: case 5: case 6: case 7:
				if (char in ::infoSpawnedSurvsList)
				{
					local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[char]);
					if (infoBot != null)
					{
						local worldSpawn = Entities.First();
						if (worldSpawn.ValidateScriptScope())
						{
							local worldScope = worldSpawn.GetScriptScope();
							if (!("VSSMGHFunc" in worldScope) || worldScope.VSSMGHFunc == null)
								worldScope.VSSMGHFunc <- survManager.GetGlowHack.weakref();
							if (!("VSSMGlowHack" in worldScope))
								worldScope.VSSMGlowHack <- [];
							
							worldScope.VSSMGlowHack.append(NetProps.GetPropInt(self, "m_bSurvivorGlowEnabled"));
							DoEntFire("!self", "CallScriptFunction", "VSSMGHFunc", 0, self, worldSpawn);
						}
					}
				}
				break;
			}
			break;
		}
		return true;
	}
	// L4D1 survset hack, addons and maps can fire this and wipe our who context :|
	function IFClearContext()
	{
		if (NetProps.GetPropInt(self, "m_iTeamNum") == 2)
		{
			switch (NetProps.GetPropInt(self, "m_survivorCharacter"))
			{
				case 4: // passing nick
					DoEntFire("!self", "AddContext", "who:Gambler", 0, null, self);
					break;
				case 5: // passing rochelle
					DoEntFire("!self", "AddContext", "who:Producer", 0, null, self);
					break;
				case 6: // passing ellis
					DoEntFire("!self", "AddContext", "who:Mechanic", 0, null, self);
					break;
				case 7: // passing coach
					DoEntFire("!self", "AddContext", "who:Coach", 0, null, self);
					break;
			}
		}
		return true;
	}
	
	function ApplyIFs(client, boolean = true, clScope = null)
	{
		if (clScope == null)
		{
			if (!client.ValidateScriptScope()) return;
			clScope = client.GetScriptScope();
		}
		switch (boolean)
		{
		case true:
			if (!("IFOverride0" in clScope))
				clScope.IFOverride0 <- IFOverride0Ref;
			if (!("IFOverride1" in clScope))
				clScope.IFOverride1 <- IFOverride1Ref;
			
			local worldSpawn = Entities.First();
			local strToUse = "Input"+GetFromStringTable("Kill", worldSpawn);
			if (!(strToUse in clScope))
				clScope[strToUse] <- IFKillRef;
			
			strToUse = "Input"+GetFromStringTable("KillHierarchy", worldSpawn);
			if (!(strToUse in clScope))
				clScope[strToUse] <- IFKillHierarchyRef;
			
			strToUse = "Input"+GetFromStringTable("TeleportToSurvivorPosition", worldSpawn);
			if (!(strToUse in clScope))
				clScope[strToUse] <- IFTeleportToSurvivorPositionRef;
			
			strToUse = "Input"+GetFromStringTable("ReleaseFromSurvivorPosition", worldSpawn);
			if (!(strToUse in clScope))
				clScope[strToUse] <- IFReleaseFromSurvivorPositionRef;
			
			strToUse = "Input"+GetFromStringTable("SetGlowEnabled", worldSpawn);
			if (!(strToUse in clScope))
				clScope[strToUse] <- IFSetGlowEnabledRef;
			
			if (survManager.GetSurvSet() == 1)
			{
				strToUse = "Input"+GetFromStringTable("ClearContext", worldSpawn);
				if (!(strToUse in clScope))
					clScope[strToUse] <- IFClearContextRef;
			}
			break;
		default:
			if ("IFOverride0" in clScope)
				delete clScope.IFOverride0;
			if ("IFOverride1" in clScope)
				delete clScope.IFOverride1;
			
			local worldSpawn = Entities.First();
			local strToUse = "Input"+GetFromStringTable("Kill", worldSpawn);
			if ((strToUse in clScope) && clScope[strToUse] == IFKillRef)
				delete clScope[strToUse];
			
			strToUse = "Input"+GetFromStringTable("KillHierarchy", worldSpawn);
			if ((strToUse in clScope) && clScope[strToUse] == IFKillHierarchyRef)
				delete clScope[strToUse];
			
			strToUse = "Input"+GetFromStringTable("TeleportToSurvivorPosition", worldSpawn);
			if ((strToUse in clScope) && clScope[strToUse] == IFTeleportToSurvivorPositionRef)
				delete clScope[strToUse];
			
			strToUse = "Input"+GetFromStringTable("ReleaseFromSurvivorPosition", worldSpawn);
			if ((strToUse in clScope) && clScope[strToUse] == IFReleaseFromSurvivorPositionRef)
				delete clScope[strToUse];
			
			strToUse = "Input"+GetFromStringTable("SetGlowEnabled", worldSpawn);
			if ((strToUse in clScope) && clScope[strToUse] == IFSetGlowEnabledRef)
				delete clScope[strToUse];
			
			if (survManager.GetSurvSet() == 1)
			{
				strToUse = "Input"+GetFromStringTable("ClearContext", worldSpawn);
				if ((strToUse in clScope) && clScope[strToUse] == IFClearContextRef)
					delete clScope[strToUse];
			}
			break;
		}
	}
	
	function OnGameEvent_player_team(params)
	{
		//printl("player_team");
		//g_ModeScript.DeepPrintTable(params);
		if (!("userid" in params)) return;
		local client = GetPlayerFromUserID(params["userid"]);
		//printl("Teamer retrieve attempt: "+client)
		if (client == null || !client.IsValid()) return;
		local clScope = null;
		local isDisconnect = ("disconnect" in params && params.disconnect == 1);
		//printl("Teamer passed valid checks")
		if ("oldteam" in params)
		{
			switch (params.oldteam)
			{
			case 3:
				if (client.ValidateScriptScope())
				{
					clScope = client.GetScriptScope();
					if ("VSSMTrig" in clScope && clScope.VSSMTrig != null && 
					clScope.VSSMTrig.IsValid())
					{
						clScope.VSSMTrig.Kill();
					}
				}
				break;
			case 4:
			case 2:
				SurvListFunc(params["userid"], false);
				if (!isDisconnect && client.ValidateScriptScope())
				{
					clScope = client.GetScriptScope();
					ApplyIFs(client, null, clScope);
				}
				break;
			}
		}
		
		if (isDisconnect) return;
		
		if ("team" in params)
		{
			switch (params.team)
			{
			case 4:
			case 2:
				SurvListFunc(params["userid"], true);
				if (client.ValidateScriptScope())
				{
					if (clScope == null) clScope = client.GetScriptScope();
					ApplyIFs(client, true, clScope);
				}
				break;
			}
		}
	}
	
	function ResetChar()
	{
		if (activator == null || !activator.IsValid()) return;
		survManager.SetCharacter(activator, NetProps.GetPropInt(activator, "m_survivorCharacter"), 0);
	}
	
	function InitPlaySurvivor(client, userid = null)
	{
		if (g_iBots != 0 && IsPlayerABot(client))
		{
			g_iBots--;
			g_iBotAttempts = 0;
			
			if (g_vecSummon != null)
			{
				client.SetOrigin(g_vecSummon);
			}
			
			NetProps.SetPropInt(client, "m_iTeamNum", 2);
			// BOT_CMD_RESET resets the AI to use currently set team's AI
			// because AI is still the old team 4 AI which is unwanted
			// in this case we want the default survivor bot AI
			// so setting and resetting sb_l4d1_survivor_behavior ain't needed
			CommandABot({
				cmd = DirectorScript.BOT_CMD_RESET,
				bot = client,
			});
			// setting m_iTeamNum to 2 in player_first_spawn seems to make the
			// survivor initialize as a default survivor instead of the special passing survivors
			DoEntFire("!self", "CancelCurrentScene", "", 0, null, client);
		}
		
		if (NetProps.GetPropInt(client, "m_iTeamNum") == 2)
		{
			if (client.ValidateScriptScope())
			{
				local clScope = client.GetScriptScope();
				if (!("VSSMSpawned" in clScope))
				{ clScope.VSSMSpawned <- null; }
			}
		}
	}
	
	function SpawnSurvivor(client, userid = null)
	{
		local worldSpawn = null;
		local worldScope = null;
		
		if (VSSMAllowRoundStart == null || VSSMStartWepsInit == null)
		{
			// needs to be an EntFire because not all survivors have spawned yet
			worldSpawn = Entities.First();
			if (worldSpawn.ValidateScriptScope())
				worldScope = worldSpawn.GetScriptScope();
			
			if (NetProps.GetPropInt(client, "m_iTeamNum") == 2)
			{
				if (VSSMAllowRoundStart == null)
				{
					if (worldScope != null && 
					(!("VSSMLoad" in worldScope) || worldScope.VSSMLoad == null))
					{
						worldScope.VSSMLoad <- RoundStart.weakref();
						DoEntFire("!self", "CallScriptFunction", "VSSMLoad", 0, null, worldSpawn);
					}
					VSSMAllowRoundStart = true;
					//WarnIncompat();
				}
				if (VSSMStartWepsInit == null && client != null && 
				client.GetSurvivorSlot() <= 3)
				{
					// todo: GetSurvivorSlot is possible hack but works since
					// this is run only on first map load thanks to VSSMStartWepsInit
					
					if (userid == null) userid = client.GetPlayerUserId();
					
					if (VSSMCharsInit == null)
						VSSMCharsInit = [];
					
					VSSMCharsInit.append(userid);
					
					// inconsistency inbound
					// player_spawn players haven't been added to RetrieveSurvList yet
					// but somehow player_spawn players also include the about-to-spawn
					// players.....
					local nSArrLoc = VSSMNoSpawnStartItemsTbl.find(userid);
					if (nSArrLoc == null)
						VSSMNoSpawnStartItemsTbl.append(userid);
				}
			}
			//SpawnBot(0);
		}
		
		// todo: hackhack very hack
		if (GetSurvSet() != 1 || client == null) return;
		if (worldSpawn == null)
			worldSpawn = Entities.First();
		if (worldScope == null && worldSpawn.ValidateScriptScope())
			worldScope = worldSpawn.GetScriptScope();
		else if (worldScope == null)
			return;
		
		if (!("VSSMResetChar" in worldScope) || worldScope.VSSMResetChar == null)
		{worldScope.VSSMResetChar <- ResetChar.weakref();}
		DoEntFire("!self", "CallScriptFunction", "VSSMResetChar", 0, client, worldSpawn);
		//survManager.SetCharacter(client, NetProps.GetPropInt(client, "m_survivorCharacter"), 0);
	}
	
	function OnGameEvent_player_activate( params )
	{
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsSurvivor() ) return;
		//printl("Added "+client.GetPlayerName()+" "+client+" to survList");
		SurvListFunc(params["userid"], true);
	}
	
	// put the VSSMAllowRoundStart-less first map load code here
	// for map transitions to work
	function OnGameEvent_player_spawn( params )
	{
		local client = GetPlayerFromUserID( params["userid"] );
		if ( !client.IsSurvivor() ) client = null;
		
		// ok don't rely on player_first_spawn to add survivors to the list
		// on map transitions the player_first_spawn event doesn't fire for 
		// successfully transitioned survivors
		if (client != null)
		{
			SurvListFunc(params["userid"], true);
			switch (NetProps.GetPropInt(client, "m_iTeamNum"))
			{
			case 4:
				local char = NetProps.GetPropInt(client, "m_survivorCharacter");
				if (!(char in ::infoSpawnedSurvsList) || GetPlayerFromUserID(::infoSpawnedSurvsList[char]) == null)
					::infoSpawnedSurvsList[char] <- params["userid"];
			default:
				SpawnSurvivor(client, params["userid"]);
				break;
			}
			
			/*if (expectedInfoBots > 0)
			{
				::infoSpawnedSurvsList[NetProps.GetPropInt(client, "m_survivorCharacter")] <- params["userid"];
				expectedInfoBots--;
			}
			else
			{
				if (IsPlayerABot(client))
				{
					if (g_iBots != 0)
					{
						g_iBots -= 1;
						
						SpawnSurvivor(client, params["userid"]);
					}
				}
				else
					SpawnSurvivor(client, params["userid"]);
			}*/
		}
	}
	
	function OnGameEvent_player_first_spawn( params )
	{
		if ( !("userid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsValid() || !client.IsSurvivor() ) return;
		
		InitPlaySurvivor(client, params["userid"]);
	}
	
	function OnGameEvent_player_connect_full( params )
	{
		if (!Settings.autoControlExtraBots || VSSMStartWepsInit == null) return;
		
		if ( !("userid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || IsPlayerABot(client) ) return;
		
		local team = NetProps.GetPropInt(client, "m_iTeamNum");
		if (team > 1) return;
		printl("[VSSM] Found "+client.GetPlayerName()+" who has joined")
		
		SpecListFunc(params["userid"], true);
		
	//	local survList = RetrieveSurvList(false);
	//	foreach (key, loopClient in survList)
	//	{
	//		if (NetProps.HasProp(loopClient, "m_humanSpectatorUserID") && 
	//		NetProps.GetPropInt(loopClient, "m_humanSpectatorUserID") == 0) break;
	//		if (key == (survList.len()-1))
	//		{
	//			printl("[VSSM] Auto-spawning bot due to lack of free bots");
	//			SpawnBot();
	//		}
	//	}
		
		local worldSpawn = Entities.First();
		if (worldSpawn.ValidateScriptScope())
		{
			local worldScope = worldSpawn.GetScriptScope();
			if (!("VSSMSpec" in worldScope) || worldScope.VSSMSpec == null)
			{
				worldScope.VSSMSpec <- SpecCheck.weakref();
				DoEntFire("!self", "CallScriptFunction", "VSSMSpec", 0.25, null, worldSpawn);
			}
		}
	}
	
	function OnGameEvent_player_say( params )
	{
		if ( !("userid" in params) || !("text" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null ) return;
		
		local chatResult = params["text"];
		//printl("We've got it: "+chatResult);
		
		if (chatResult[0] != '!' && chatResult[0] != '/') return;
		//printl("Activated");
		chatResult = chatResult.slice(1).tolower();
		
		local host = isDedicated ? null : GetListenServerHost();
		
		local function CheckAdmin()
		{
			if (host == null || client != host)
			{
				if ("AdminSystem" in getroottable())
				{
					try {
						// IsServerHost shits itself on some players
						// makes this function unreliable, wtf rayman
						//if (!(::AdminSystem.IsAdmin(client))) return false;
						local steamid = client.GetNetworkIDString();
						if (!steamid) return false;
						
						if (!(steamid in ::AdminSystem.Admins)) return false;
					} catch (err) {
						ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Something went wrong with Admin System's verification.");
						return false;
					}
				}
				else
				{
					if (!isDedicated)
						ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"You need to be the server host to do that.");
					return false;
				}
			}
			return true;
		}
		
		local function GetSurvFromStrVal(value)
		{
			local newVal = null;
			switch (GetSurvSet())
			{
			case 1:
				switch (value)
				{
				case 'n':	newVal = 4;	break;
				case 'r':	newVal = 5;	break;
				case 'c':	newVal = 7;	break;
				case 'e':	newVal = 6;	break;
				case 'b':	newVal = 0;	break;
				case 'z':	newVal = 1;	break;
				case 'f':	newVal = 3;	break;
				case 'l':	newVal = 2;	break;
				}
				break;
			default:
				switch (value)
				{
				case 'n':	newVal = 0;	break;
				case 'r':	newVal = 1;	break;
				case 'c':	newVal = 2;	break;
				case 'e':	newVal = 3;	break;
				case 'b':	newVal = 4;	break;
				case 'z':	newVal = 5;	break;
				case 'f':	newVal = 6;	break;
				case 'l':	newVal = 7;	break;
				//default:	newVal = null;	break;
				}
				break;
			}
			return newVal;
		}
		
		if (chatResult.find(CMD_SPAWN_NAME) == 0)
		{
			if (!CheckAdmin()) return;
			
			local cmdLen = CMD_SPAWN_NAME.len();
			if (chatResult.len() > cmdLen)
			{
				chatResult = split(chatResult.slice(cmdLen), " ");
				local chatResult1 = null;
				try {
					chatResult[0] = chatResult[0].tointeger();
				}
				catch (err) {
					chatResult1 = chatResult[0];
					chatResult[0] = 1;
					//SpawnBot(1, GetPlayerFromUserID(params["userid"]), SPAWNTYPE_CMD);
					//return;
				}
				if (chatResult[0] < 0) return;
				
				if (chatResult1 == null)
					chatResult1 = (1 in chatResult) ? chatResult[1] : null;
				
				// don't be too big or it'll affect future spawnbots
				if (chatResult1 != null)
				{
					local chatResult2 = null;
					if (2 in chatResult)
					{
						try {
							chatResult2 = chatResult[2].tointeger();
							if (chatResult2 > chatResult[0])
								chatResult2 = chatResult[0];
						}
						catch (err) {
							chatResult2 = chatResult[0];
						}
					}
					else
					{
						chatResult2 = chatResult[0];
					}
					
					try
					{
						chatResult1 = chatResult1.tointeger();
					}
					catch (err)
					{
						if (0 in chatResult1)
						{
							chatResult1 = GetSurvFromStrVal(chatResult1[0]);
						}
						else
							chatResult1 = null;
					}
					if (chatResult1 < 0 || chatResult1 > 7)
						chatResult1 = null;
					
					if (chatResult1 != null)
					{
						enforcedChars = [chatResult1, chatResult2];
					}
				}
				
				if (!isDedicated)
				{
					switch (chatResult[0])
					{
					case 69:
					case 4001:
					case 420:
					case 1337:
					case 96:
						ClientPrint(client, 3, "\x03"+"[VSSm.......] "+"\x01"+"bruh.");
						break;
					}
				}
				
				SpawnBot(chatResult[0], GetPlayerFromUserID(params["userid"]), SPAWNTYPE_CMD);
			}
			else
				SpawnBot(1, GetPlayerFromUserID(params["userid"]), SPAWNTYPE_CMD);
			
			return; // need to return to not trigger the switch case way below
		}
		else if (chatResult.find(CMD_COUNT_NAME) == 0)
		{
			if (!CheckAdmin()) return;
			
			local cmdLen = CMD_COUNT_NAME.len();
			if (chatResult.len() > cmdLen)
			{
				try {
					chatResult = chatResult.slice(cmdLen).tointeger();
					//printl("chatResult: "+chatResult)
					//chatResult = chatResult;
					//printl("chatResult tointeger: "+chatResult)
				}
				catch (err) {
					ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Please specify a number to set survCount to.\nCurrent survCount setting is "+Settings.survCount+".");
					return;
				}
				if (chatResult < 0)
				{
					ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"You can't set survCount lower than 0!");
					return;
				}
				
				if (!isDedicated)
				{
					switch (chatResult)
					{
					case 69:
					case 4001:
					case 420:
					case 1337:
					case 96:
						ClientPrint(client, 3, "\x03"+"[VSSm.......] "+"\x01"+"bruh.");
						break;
					}
				}
				
				if (Settings.survCount == chatResult)
				{
					ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"survCount is already at "+chatResult+"!");
					return;
				}
				else
				{
					UpdateConfigFile({survCount = chatResult});
					ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"survCount updated to "+chatResult+" and settings have been refreshed.");
				}
				
				SpawnBot(0);
			}
			else
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Please specify a number to set survCount to.\nCurrent survCount setting is "+Settings.survCount+".");
			}
			
			return;
		}
		else if (chatResult.find(CMD_ORDER_NAME) == 0)
		{
			if (!CheckAdmin()) return;
			
			local cmdLen = CMD_ORDER_NAME.len();
			if (chatResult.len() <= cmdLen)
			{
				switch (GetSurvSet())
				{
				case 1:
					UpdateConfigFile({survCharOrderL4D1 = [
						"Bill",
						"Zoey",
						"Louis",
						"Francis",
						"Nick",
						"Rochelle",
						"Ellis",
						"Coach",
					]});
					ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"The L4D1 Map order was reset to: "+"\n"+"!"+CMD_ORDER_NAME+" b z l f n r e c");
					break;
				default:
					UpdateConfigFile({survCharOrderL4D2 = [
						"Nick",
						"Rochelle",
						"Coach",
						"Ellis",
						"Bill",
						"Zoey",
						"Francis",
						"Louis",
					]});
					ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"The L4D2 Map order was reset to: "+"\n"+"!"+CMD_ORDER_NAME+" n r c e b z f l");
					break;
				}
				return;
			}
			
			chatResult = split(chatResult.slice(cmdLen), " ");
			for (local i = 0; i < chatResult.len(); i++)
			{
				try {
					chatResult[i] = chatResult[i].tointeger();
					if (chatResult[i] < 0 || chatResult[i] > 7)
					{
						chatResult.remove(i);
						i = i - 1;
						continue;
					}
				}
				catch (err) {
					chatResult[i] = GetSurvFromStrVal(chatResult[i][0]);
					if (chatResult[i] == null)
					{
						chatResult.remove(i);
						i = i - 1;
						continue;
					}
				}
			}
			if (!(0 in chatResult))
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Couldn't get any survivor type to set order to!");
				return;
			}
			
			local printStr = "";
			local survSet = GetSurvSet();
			for (local i = 0; i < chatResult.len(); i++)
			{
				switch (survSet)
				{
				case 1:
					switch (chatResult[i])
					{
					case 0:	chatResult[i] = "Bill";		printStr = printStr+" b";	break;
					case 1:	chatResult[i] = "Zoey";		printStr = printStr+" z";	break;
					case 2:	chatResult[i] = "Louis";	printStr = printStr+" l";	break;
					case 3:	chatResult[i] = "Francis";	printStr = printStr+" f";	break;
					case 4:	chatResult[i] = "Nick";		printStr = printStr+" n";	break;
					case 5:	chatResult[i] = "Rochelle";	printStr = printStr+" r";	break;
					case 6:	chatResult[i] = "Ellis";	printStr = printStr+" e";	break;
					case 7:	chatResult[i] = "Coach";	printStr = printStr+" c";	break;
					}
					break;
				default:
					switch (chatResult[i])
					{
					case 0:	chatResult[i] = "Nick";		printStr = printStr+" n";	break;
					case 1:	chatResult[i] = "Rochelle";	printStr = printStr+" r";	break;
					case 2:	chatResult[i] = "Coach";	printStr = printStr+" c";	break;
					case 3:	chatResult[i] = "Ellis";	printStr = printStr+" e";	break;
					case 4:	chatResult[i] = "Bill";		printStr = printStr+" b";	break;
					case 5:	chatResult[i] = "Zoey";		printStr = printStr+" z";	break;
					case 6:	chatResult[i] = "Francis";	printStr = printStr+" f";	break;
					case 7:	chatResult[i] = "Louis";	printStr = printStr+" l";	break;
					}
					break;
				}
			}
			
			switch (survSet)
			{
			case 1:
				UpdateConfigFile({survCharOrderL4D1 = chatResult})
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"The L4D1 Map order was set to: ");
				break;
			default:
				UpdateConfigFile({survCharOrderL4D2 = chatResult})
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"The L4D2 Map order was set to: ");
				break;
			}
			ClientPrint(client, 3, "!"+CMD_ORDER_NAME+printStr);
			return;
		}
		
		switch (chatResult)
		{
		case CMD_REFIXATTEMPTS_NAME:
			if (!CheckAdmin()) break;
			
			g_iBotAttempts = 0;
			ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Auto-Manager is re-enabled.");
			break;
		case CMD_TAKEOVER_NAME:
			if (!client.IsSurvivor())
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"You can only use this command as a survivor!");
				break;
			}
			if (client.IsIncapacitated() || client.IsDead() || client.IsDying() || client.IsDominatedBySpecialInfected())
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Cannot takeover while pinned, incapped, or dead.");
				break;
			}
			if (client.GetMoveParent() != null)
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"You're attached to something!");
				break;
			}
			if (!Settings.allowSurvSwapCmdForUsers)
			{
				if (!CheckAdmin()) break;
			}
			
			local eyePos = client.EyePosition();
			local traceTbl = {
				start = eyePos,
				end = eyePos + (client.EyeAngles().Forward() * 2048),
				mask = DirectorScript.TRACE_MASK_SHOT,
				ignore = client,
			};
			TraceLine(traceTbl);
			
			local function IsValidSurv(target)
			{
				if (target.GetMoveParent() != null || 
				!IsPlayerABot(target) || 
				NetProps.GetPropInt(target, "m_iTeamNum") != NetProps.GetPropInt(client, "m_iTeamNum") || 
				target.IsIncapacitated() || 
				target.IsDead() || target.IsDying() || 
				target.IsDominatedBySpecialInfected()) return false;
				
				local survChar = NetProps.GetPropInt(target, "m_survivorCharacter");
				if (survChar < 0 || survChar > 7) return false;
				
				return true;
			}
			
			local chosenCl = null;
			if ("enthit" in traceTbl && traceTbl.enthit.IsValid() && traceTbl.enthit.IsPlayer() && 
			IsValidSurv(traceTbl.enthit))
			{
				chosenCl = traceTbl.enthit;
			}
			else
			{
				local distance = null;
				
				local survList = RetrieveSurvList(false);
				foreach (key, loopClient in survList)
				{
					if (loopClient == client || 
					!IsValidSurv(loopClient)) continue;
					
					local loopOrigin = loopClient.GetOrigin();
					local distVars = (loopOrigin-eyePos).LengthSqr();
					if ("pos" in traceTbl)
					{
						//DebugDrawCircle(traceTbl.pos, Vector(255, 0, 255), 127, 30, true, 10.0);
						distVars = (distVars + (loopOrigin-traceTbl.pos).LengthSqr());
					}
					//printl("distance of "+loopClient+" is "+distance)
					if (distance == null || distVars < distance)
					{
						distance = distVars;
						chosenCl = loopClient;
					}
				}
			}
			
			if (chosenCl == null)
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Can't find suitable target! Make sure the bot is not pinned, incapped, or dead.");
				break;
			}
			
			SimpleTakeover(client, chosenCl);
			// as much as it'd be great to use sb_takecontrol
			// matter of the fact is it's locked behind cheat protection
			// and there is no VScript method like client.Takeover() implemented yet
			// so I have to make very hacky do
			/*local testCmd = SpawnEntityFromTable("point_clientcommand",{});
			DoEntFire("!self", "Command", "sb_takecontrol", 0, client, testCmd);
			DoEntFire("!self", "Kill", "", 0.01, null, testCmd);*/
			break;
		case CMD_KICK_NAME:
			if (!CheckAdmin()) break;
			
			local eyePos = client.EyePosition();
			local traceTbl = {
				start = eyePos,
				end = eyePos + (client.EyeAngles().Forward() * 2048),
				mask = DirectorScript.TRACE_MASK_SHOT,
				ignore = client,
			};
			TraceLine(traceTbl);
			
			local function IsValidSurv(target)
			{
				if (!target.IsSurvivor() || !IsPlayerABot(target)) return false;
				
				return true;
			}
			
			local chosenCl = null;
			if ("enthit" in traceTbl && traceTbl.enthit.IsValid() && traceTbl.enthit.IsPlayer() && 
			IsValidSurv(traceTbl.enthit))
			{
				chosenCl = traceTbl.enthit;
			}
			else
			{
				local distance = null;
				
				local survList = RetrieveSurvList(false);
				foreach (key, loopClient in survList)
				{
					if (loopClient == client || 
					!IsValidSurv(loopClient)) continue;
					
					local loopOrigin = loopClient.GetOrigin();
					local distVars = (loopOrigin-eyePos).LengthSqr();
					if ("pos" in traceTbl)
					{
						distVars = (distVars + (loopOrigin-traceTbl.pos).LengthSqr());
					}
					if (distance == null || distVars < distance)
					{
						distance = distVars;
						chosenCl = loopClient;
					}
				}
			}
			
			if (chosenCl == null)
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Can't find any bot to remove!");
				break;
			}
			
			if (!chosenCl.ValidateScriptScope())
			{
				ClientPrint(client, 3, "\x03"+"[VSSM] "+"\x01"+"Something went wrong with getting the bot's script scope needed to remove them!");
				break;
			}
			local clScope = chosenCl.GetScriptScope();
			
			local strToUse = "Input"+GetFromStringTable("Kill", chosenCl);
			if ((strToUse in clScope) && clScope[strToUse] == IFKillRef)
				delete clScope[strToUse];
			
			DoEntFire("!self", "Kill", "", 0, null, chosenCl);
			break;
		}
	}
	
	function AlterChar1()
	{
		survManager.AlterSurvivorNetProps(null, true);
		/*g_existingPlys.clear();
		for (local player; player = Entities.FindByClassname( player, "player" );)
		{
			if (player == null) continue;
			g_existingPlys.append(player);
		}*/
		delete this.VSSMFunc;
	}
	
	function AlterCharMid()
	{
		//local survList = survManager.RetrieveSurvList(false);
		survManager.AlterSurvivorNetProps(null, true);
		//g_ModeScript.DeepPrintTable(survList);
	}
	
	function AlterChar2()
	{
		//local survList = survManager.RetrieveSurvList(false);
		//survManager.AlterSurvivorNetProps(survList, false);
		survManager.AlterSurvivorNetProps(null, false);
		/*foreach (key, client in survList)
		{
			if (g_iBots == 0) break;
			if (client == null || g_existingPlys.find(client) != null) continue;
			survManager.InitPlaySurvivor(client);
			g_iBots--;
			continue;
		}*/
		
		survManager.CharCheck();
		
		if (g_iBots != 0)
		{
			g_iBotAttempts = g_iBotAttempts + 1;
			if (g_iBotAttempts >= MAX_SPAWN_ATTEMPTS)
			{
				if ((survManager.Settings.survCount + g_iBots) > maxPlayers)
				{
					local brokeIt = (survManager.Settings.survCount <= maxPlayers);
					if (brokeIt)
					{g_iBotAttempts = 0;}
					if (!isDedicated)
					{
						local host = GetListenServerHost();
						ClientPrint(host, 3, "\x03"+"[VSSM]"+"\x01"+"\nThe maximum amount of survivors is "+maxPlayers+"! What are you doing?");
						if (brokeIt) ClientPrint(host, 3, "Auto-Manager disabled.");
					}
					else
					{
						printl("[VSSM]\nThe maximum amount of survivors is "+maxPlayers+"! What are you doing?");
						if (brokeIt) printl("Auto-Manager disabled.");
					}
				}
				else
				{
					//g_iBots = 0; // wow this broke the entire system
					if (!isDedicated)
					{
						local host = GetListenServerHost();
						ClientPrint(host, 3, "\x03"+"[VSSM]"+"\x01"+"\nUnable to spawn bots!");
						ClientPrint(host, 3, "Auto-Manager disabled.");
					}
					else
					{
						printl("[VSSM]\nUnable to spawn bots!\nAuto-Manager disabled.");
					}
				}
				if (survManager.enforcedChars != null) survManager.enforcedChars = null;
				delete this.VSSMFunc2;
				return;
			}
			printl("[VSSM] Something went wrong and "+g_iBots+" failed to spawn! Respawning.");
			if (!("VSSMFix" in this) || this.VSSMFix == null)
			{
				this.VSSMFix <- survManager.RetryBots.weakref();
				DoEntFire("!self", "CallScriptFunction", "VSSMFix", 0.1, null, self);
			}
		}
		delete this.VSSMFunc2;
	}
	function RetryBots()
	{ survManager.SpawnBot(); delete this.VSSMFix; }
	
	function EnsureSpawner()
	{
		if (VSSMSpawner == null || !VSSMSpawner.IsValid())
		{
			VSSMSpawner = SpawnEntityFromTable("info_l4d1_survivor_spawn",{
				character = 4,
				targetname = "VSSMSpawner",
				classname = "vssm_spawner",
			});
			if (!VSSMSpawner.ValidateScriptScope()) return;
			
			local entScope = VSSMSpawner.GetScriptScope();
			//entScope.mdlSeqIdxs <- {};
			entScope.Charged <- [];
			entScope.ChargeState <- [];
			entScope.ChargeTime <- [];
			//entScope.ChargeAnimTime <- [];
			//if (survManager.GetSurvSet() == 1)
			//	entScope.DoFakeTalker <- null;
			
			/*entScope.PrecacheAnimIdxs <- function(target, mdlIdx)
			{
				mdlSeqIdxs[mdlIdx] <- [];
				for (local i = 0; i <= 2; i++)
				{
					// see ACT_consts
					local tgtSeq = -1;
					switch (i)
					{
						case 0: // Victim gets up after charger impact or pounding
							tgtSeq = target.LookupSequence("ACT_TERROR_CHARGERHIT_LAND_SLOW");
							break;
						case 1: // Charger impacts victim away, happens when already carrying someone
							tgtSeq = target.LookupSequence("ACT_TERROR_IDLE_FALL_FROM_CHARGERHIT");
							break;
						case 2: // Initial frame of charger impact, dumb but gotta check for this
							tgtSeq = target.LookupSequence("ACT_TERROR_HIT_BY_CHARGER");
							break;
					}
					if (tgtSeq != -1) mdlSeqIdxs[mdlIdx].insert(i, tgtSeq);
				}
				if (mdlSeqIdxs[mdlIdx].len() == 0)
					mdlSeqIdxs[mdlIdx] <- null;
			}*/
			
			entScope.IsThinking <- null;
			entScope.CullThink <- function()
			{
				AddThinkToEnt(self, null);
				this.IsThinking = null;
			}
			
			entScope.ToggleClient <- function(client, boolean = true)
			{
				if (client == null) return;
				
				switch (boolean)
				{
				case true:
					if (this.Charged.find(client) == null)
					{
						if (this.Charged.len() == 0)
						{
							AddThinkToEnt(self, "VSSMThink");
							this.IsThinking = true;
						}
						this.Charged.append(client);
						this.ChargeState.append(0);
						this.ChargeTime.append(null);
						//this.ChargeAnimTime.append(0);
						//NetProps.SetPropFloat(client, "m_mainSequenceStartTime", Time());
					}
					break;
				default:
					local arrLoc = this.Charged.find(client);
					if (arrLoc != null)
					{
						local activeWep = client.GetActiveWeapon();
						if (activeWep != null)
						{
							NetProps.SetPropEntity(client, "m_hActiveWeapon", null);
							client.SwitchToItem(activeWep.GetClassname());
						}
						this.Charged.remove(arrLoc);
						this.ChargeState.remove(arrLoc);
						this.ChargeTime.remove(arrLoc);
						//this.ChargeAnimTime.remove(arrLoc);
						if (this.Charged.len() == 0)
						{
							AddThinkToEnt(self, null);
							this.IsThinking = null;
						}
					}
					break;
				}
			}
			
			entScope.timeTilThink1 <- 0;
			entScope.timeTilThink2 <- 0;
			entScope.VSSMThink <- function()
			{
				//printl("VSSMThink running")
				local time = Time();
				if (0 in this.Charged)
				{
					//local time = Time();
					local doThink1 = (timeTilThink1 <= time);
					for (local i = 0; i < this.Charged.len(); i++)
					{
						if (this.Charged[i] == null || !this.Charged[i].IsValid() || 
						!this.Charged[i].IsSurvivor() || 
						(this.ChargeTime[i] != null && this.ChargeTime[i] <= time))
						{
							local activeWep = this.Charged[i].GetActiveWeapon();
							if (activeWep != null)
							{
								NetProps.SetPropEntity(this.Charged[i], "m_hActiveWeapon", null);
								this.Charged[i].SwitchToItem(activeWep.GetClassname());
							}
							this.Charged.remove(i);
							this.ChargeState.remove(i);
							this.ChargeTime.remove(i);
							//this.ChargeAnimTime.remove(i);
							i = i - 1;
							continue;
						}
						//printl("Charged: "+this.Charged[i])
						//printl("ChargeState: "+this.ChargeState[i])
						//printl("ChargeTime: "+this.ChargeTime[i])
						
						//local overrideStop = null;
						if (doThink1)
						{
							timeTilThink1 = time + 0.5;
							local activeWep = this.Charged[i].GetActiveWeapon();
							if (activeWep != null)
							{
								local lolTime = time+99;
								NetProps.SetPropFloat(activeWep, "LocalActiveWeaponData.m_flNextPrimaryAttack", lolTime);
								NetProps.SetPropFloat(activeWep, "LocalActiveWeaponData.m_flNextSecondaryAttack", lolTime);
							}
							/*local vel = this.Charged[i].GetVelocity();
							if (vel.x == 0 && vel.y == 0 && vel.z == 0)
							{
								overrideStop = true;
							}*/
						}
						
						local flags = NetProps.GetPropInt(this.Charged[i], "m_fFlags");
						switch (!!(flags & (1 << 0))) // FL_ONGROUND
						{
						case true:
							// 1 = initial charge, 2 = sent flying to air, 3 = landed on ground
							switch (this.ChargeState[i])
							{
							case 0:
								::survAnim.ForceSequence(this.Charged[i], "ACT_TERROR_HIT_BY_CHARGER");
								this.ChargeState[i] = 1;
								break;
							case 2:
								::survAnim.ForceSequence(this.Charged[i], "ACT_TERROR_CHARGERHIT_LAND_SLOW");
								this.ChargeState[i] = 3;
								if (this.ChargeTime[i] == null)
								{
									NetProps.SetPropFloat(this.Charged[i], "m_mainSequenceStartTime", time);
									local stunTime = 3;
									this.ChargeTime[i] = time + stunTime;
									NetProps.SetPropFloat(this.Charged[i], "m_stunTimer.m_duration", stunTime);
									local timeDur = time+stunTime;
									NetProps.SetPropFloat(this.Charged[i], "m_stunTimer.m_timestamp", timeDur);
									NetProps.SetPropFloat(this.Charged[i], "m_jumpSupressedUntil", timeDur);
									NetProps.SetPropFloat(this.Charged[i], "m_TimeForceExternalView", timeDur);
								}
								break;
							}
							break;
						default:
							switch (this.ChargeState[i])
							{
							case 0:
								::survAnim.ForceSequence(this.Charged[i], "ACT_TERROR_HIT_BY_CHARGER");
								this.ChargeState[i] = 1;
								break;
							case 1:
								::survAnim.ForceSequence(this.Charged[i], "ACT_TERROR_IDLE_FALL_FROM_CHARGERHIT");
								this.ChargeState[i] = 2;
								break;
							}
							break;
						}
					}
				}
				
				if (/*"DoFakeTalker" in this && */this.timeTilThink2 <= time)
				{
					timeTilThink2 = time + 1.0;
					// 4 = bill / nick
					// 5 = zoey / rochelle
					// 6 = francis / ellis
					// 7 = louis / coach
					
					local extraSetSurvs = {};
					local survList = survManager.RetrieveSurvList(false);
					for (local i = 0; i < survList.len(); i++)
					{
						local survChar = NetProps.GetPropInt(survList[i], "m_survivorCharacter");
						if (survChar in extraSetSurvs) continue;
						
						switch (survChar)
						{
						case 4:
						case 5:
						case 6:
						case 7:
							if (survList[i].IsDead() || survList[i].IsDying())
								extraSetSurvs[survChar] <- null;
							else
								extraSetSurvs[survChar] <- survList[i];
							
							//survList.remove(i);
							//i = i - 1;
							if (extraSetSurvs.len() >= 4) break;
							break;
						}
					}
					
					if (extraSetSurvs.len() != 0)
					{
						foreach (key, client in survList)
						{
							foreach (key, extraSetPlayer in extraSetSurvs)
							{
								if (extraSetPlayer == client) continue;
								if (extraSetPlayer == null)
								{
									switch (survManager.GetSurvSet())
									{
									case 1:
										switch (key)
										{
										case 4:
											client.SetContextNum("IsGamblerAlive", 0, -1);
											break;
										case 5:
											client.SetContextNum("IsProducerAlive", 0, -1);
											break;
										case 6:
											client.SetContextNum("IsMechanicAlive", 0, -1);
											break;
										case 7:
											client.SetContextNum("IsCoachAlive", 0, -1);
											break;
										}
										break;
									default:
										switch (key)
										{
										case 4:
											client.SetContextNum("IsNamVetAlive", 0, -1);
											break;
										case 5:
											client.SetContextNum("IsTeenGirlAlive", 0, -1);
											break;
										case 6:
											client.SetContextNum("IsBikerAlive", 0, -1);
											break;
										case 7:
											client.SetContextNum("IsManagerAlive", 0, -1);
											break;
										}
										break;
									}
									continue;
								}
								// floods stringtable like crazy
								// context isn't worth the eventual crash
								//local clOrigin = client.GetOrigin();
								//local fakeOrigin = extraSetPlayer.GetOrigin();
								
								//local distVars = (clOrigin-fakeOrigin).Length().tointeger() / 10;
								//distVars *= 10;
								switch (survManager.GetSurvSet())
								{
								case 1:
									switch (key)
									{
									case 4:
										client.SetContextNum("IsGamblerAlive", 1, 1);
										//client.SetContextNum("DistToGambler", distVars, 1);
										break;
									case 5:
										client.SetContextNum("IsProducerAlive", 1, 1);
										//client.SetContextNum("DistToProducer", distVars, 1);
										break;
									case 6:
										client.SetContextNum("IsMechanicAlive", 1, 1);
										//client.SetContextNum("DistToMechanic", distVars, 1);
										break;
									case 7:
										client.SetContextNum("IsCoachAlive", 1, 1);
										//client.SetContextNum("DistToCoach", distVars, 1);
										break;
									}
									break;
								default:
									switch (key)
									{
									case 4:
										client.SetContextNum("IsNamVetAlive", 1, 1);
										//client.SetContextNum("DistToNamVet", distVars, 1);
										break;
									case 5:
										client.SetContextNum("IsTeenGirlAlive", 1, 1);
										//client.SetContextNum("DistToTeenGirl", distVars, 1);
										break;
									case 6:
										client.SetContextNum("IsBikerAlive", 1, 1);
										//client.SetContextNum("DistToBiker", distVars, 1);
										break;
									case 7:
										client.SetContextNum("IsManagerAlive", 1, 1);
										//client.SetContextNum("DistToManager", distVars, 1);
										break;
									}
									break;
								}
								//if ("white_printl" in g_rr)
								//{
								//	g_rr.white_printl("SetContextNuming "+client+" with "+distVars+" from "+extraSetPlayer)
								//}
								//printl("SetContextNuming "+client+" with "+distVars+" from "+extraSetPlayer);
							}
						}
						if (Entities.FindByClassname(null, "info_remarkable") != null)
						{
							local remarkList = [];
							for (local remarkable; remarkable = Entities.FindByClassname( remarkable, "info_remarkable" );)
							{
								if (remarkable == null) continue;
								remarkList.append(remarkable);
							}
							
							local remarkDistCVar = Convars.GetFloat("rr_remarkable_maxdist");
							foreach (key, extraSetPlayer in extraSetSurvs)
							{
								if (extraSetPlayer == null) continue;
								local eyePos = extraSetPlayer.EyePosition();
								
								local traceTbl = {
									start = eyePos,
									end = eyePos + (extraSetPlayer.EyeAngles().Forward() * 2048),
									mask = DirectorScript.TRACE_MASK_SHOT,
									ignore = extraSetPlayer,
								};
								TraceLine(traceTbl);
								
								local closestRemark = null;
								local remarkDist = null;
								foreach (key, remarkable in remarkList)
								{
									local remarkOrigin = remarkable.GetOrigin();
									
									local distVars = (remarkOrigin-eyePos).LengthSqr();
									local distTest = distVars / remarkDistCVar;
									if (distTest > remarkDistCVar || 
									(remarkDist != null && distTest >= remarkDist)) continue;
									
									if ("pos" in traceTbl)
									{
										//DebugDrawCircle(traceTbl.pos, Vector(255, 0, 255), 127, 30, true, 10.0);
										distVars = (distVars + (remarkOrigin-traceTbl.pos).LengthSqr());
									}
									if (remarkDist == null || distVars < remarkDist)
									{
										closestRemark = remarkable;
										remarkDist = distVars;
									}
								}
								
								if (closestRemark != null)
								{
									//printl("found closestRemark "+closestRemark+" for "+extraSetPlayer);
									local remarkOrigin = closestRemark.GetOrigin();
									local traceTbl =
									{
										start = eyePos,
										end = remarkOrigin,
										mask = (1 | 16384), 
										//CONTENTS_SOLID|CONTENTS_MOVEABLE
									}
									TraceLine(traceTbl);
									
									local isVisible = false;
									if ("hit" in traceTbl && "pos" in traceTbl)
									{
										local vStart = traceTbl.pos; // retrieve our trace endpoint
										
										local dist1 = (eyePos-vStart).LengthSqr();
										local dist2 = (eyePos-remarkOrigin).LengthSqr();
										local trCalc1 = (dist1 / dist2);
										local trCalc2 = (dist2 / dist1);
										if (trCalc1 >= trCalc2)
										{
											isVisible = true;
										}
									}
									else
									{
										isVisible = true;
									}
									traceTbl.clear();
									
									//printl("isVisible: "+isVisible);
									if (!isVisible) continue;
									
									local remarkContext = NetProps.GetPropString(closestRemark, "m_szRemarkContext");
									//extraSetPlayer.SetContext("subject", remarkContext, 1);
									//extraSetPlayer.SetContextNum("distance", (remarkOrigin-eyePos).Length(), 1);
									QueueSpeak(extraSetPlayer, "TLK_REMARK", 0, "subject:"+remarkContext+",distance:"+(remarkOrigin-eyePos).Length());
								}
							}
						}
					}
					//else
					//	delete this.DoFakeTalker;
				}
				
				/*if (!(0 in this.Charged) && !("DoFakeTalker" in this))
				{
					DoEntFire("!self", "CallScriptFunction", "CullThink", 0, null, self);
				}*/
				return 0.03; // 0.03
			}
			
			for (local i = 4; i <= 7; i++)
			{
				local client = GetPlayerFromCharacter(i);
				if (client == null) continue;
				if (entScope.IsThinking == null)
				{
					AddThinkToEnt(VSSMSpawner, "VSSMThink");
					entScope.IsThinking = true;
				}
				break;
			}
		}
	}
	
	function SpawnBot(number = 1, client = null, spawnTypeNum = SPAWNTYPE_CHECK)
	{
		if (g_iBotAttempts >= MAX_SPAWN_ATTEMPTS && spawnTypeNum == SPAWNTYPE_CHECK) return;
		
		local worldSpawn = Entities.First();
		if (!worldSpawn.ValidateScriptScope()) return;
		
		local survList = null;
		g_vecSummon = null;
		if (client != null)
		{
			g_vecSummon = client.GetOrigin();
		}
		else
		{
			survList = RetrieveSurvList(false);
			foreach (key, loopClient in survList)
			{
				if (NetProps.GetPropInt(loopClient, "m_iTeamNum") != 2) continue;
				if (loopClient.IsDead() || loopClient.IsDying()) continue;
				if (loopClient.IsHangingFromLedge())
				{
					g_vecSummon = NetProps.GetPropVector(loopClient, "m_hangStandPos");
					break;
				}
				else
				{
					g_vecSummon = loopClient.GetOrigin();
					break;
				}
			}
			/*if (g_vecSummon == null)
			{
				local plyStart = Entities.FindByClassname( survPos, "info_player_start" );
				if (plyStart != null)
					g_vecSummon = plyStart.GetOrigin();
			}*/
		}
		
		if (spawnTypeNum == SPAWNTYPE_CHECK)
		{
			if (survList == null)
				survList = RetrieveSurvList(false);
			
			for (local i = 0; i < survList.len(); i++)
			{
				if (NetProps.GetPropInt(survList[i], "m_iTeamNum") != 2 || 
				VSSMEssentialBots.find(survList[i]) != null)
				{
					survList.remove(i);
					i = i - 1;
				}
			}
			local survListLen = survList.len();
			local missingSurvs = survManager.Settings.survCount - survListLen;
			if (missingSurvs > 0)
			{
				printl("[VSSM] Adding "+missingSurvs+" more bots as survCount setting is "+survManager.Settings.survCount);
				number = missingSurvs;
			}
			else if (number == 0 && missingSurvs < 0 && Settings.removeExcessSurvivors)
			{
				local removeSurvs = -(missingSurvs);
				printl("[VSSM] Removing "+removeSurvs+" bots as survCount setting is "+survManager.Settings.survCount);
				
				/*local time = Time();
				if (g_lastBotKillTime + BOTKILL_WARN_TIME > time)
				{
					if (!isDedicated)
					{
						ClientPrint(GetListenServerHost(), 3, "\x03"+"[VSSM] "+"\x01"+"Be careful removing bots too often! It may cause a crash!");
					}
					else
					{
						printl("[VSSM] Be careful removing bots too often! It may cause a crash!");
					}
				}
				g_lastBotKillTime = time;*/
				
				for (local i = (survListLen-1); i >= 0; i--)
				{
					//if (NetProps.GetPropInt(survList[i], "m_iTeamNum") != 2) continue;
					if (removeSurvs == 0) break;
					if (!IsPlayerABot(survList[i]) || 
					(NetProps.HasProp(survList[i], "m_humanSpectatorUserID") && 
					NetProps.GetPropInt(survList[i], "m_humanSpectatorUserID") != 0)) continue;
					
					survList[i].Kill();
					removeSurvs = removeSurvs - 1;
				}
			}
			if (survManager.Settings.autoCheckpointFirstAid)
				survManager.HandleCheckpointKits();
		}
		if (number == 0)
		{
			survManager.CharCheck();
			return;
		}
		
		EnsureSpawner();
		if (VSSMSpawner == null)
		{
			survManager.CharCheck();
			return;
		}
		
		if (g_vecSummon != null) VSSMSpawner.SetOrigin(g_vecSummon);
		
		g_iBots = number;
		
		local worldScope = worldSpawn.GetScriptScope();
		if (!("VSSMFunc" in worldScope) || worldScope.VSSMFunc == null)
		{
			worldScope.VSSMFunc <- AlterChar1.weakref();
			DoEntFire("!self", "CallScriptFunction", "VSSMFunc", 0, null, worldSpawn);
		}
		
		for (local i = 0; i < number; i++)
		{
			DoEntFire("!self", "SpawnSurvivor", "", 0, null, VSSMSpawner);
			// iterating through players every time here
			// does not bode well for optimization, but for the interest of
			// doing things in an instant to minimize the window of failure
			// it can't be helped
			if (!("VSSMFunc3" in worldScope) || worldScope.VSSMFunc3 == null)
			{
				worldScope.VSSMFunc3 <- AlterCharMid.weakref();
			}
			DoEntFire("!self", "CallScriptFunction", "VSSMFunc3", 0, null, worldSpawn);
			//SendToServerConsole("sb_add bill");
			// dont use SendToServerConsole it has a bias to player-triggered funcs
			// and is probably only triggerable with sv_cheats
			// friendship ended with SendToServerConsole
			// now info_l4d1_survivor_spawn is my best friend
		}
		//local worldScope = worldSpawn.GetScriptScope();
		
		//if (spawnTypeNum != SPAWNTYPE_CHECK)
		//{worldScope.VSSMSpTy <- spawnTypeNum;}
		
		if (!("VSSMFunc2" in worldScope) || worldScope.VSSMFunc2 == null)
		{
			worldScope.VSSMFunc2 <- AlterChar2.weakref();
			DoEntFire("!self", "CallScriptFunction", "VSSMFunc2", 0, null, worldSpawn);
		}
	}
	
	function AlterSurvivorNetProps(survList = null, boolean = true)
	{
		if (survList == null)
			survList = RetrieveSurvList(false);
		
		switch (boolean)
		{
		case true:
			//printl("AlterSurvivorNetProps true called")
			//local survSetTmp = GetSurvSet();
			foreach (key, client in survList)
			{
				//local char = NetProps.GetPropInt(client, "m_survivorCharacter");
				//if (survSetTmp != 1 && char != 4/* || survSetTmp == 1 && char != 0*/) continue;
				
				local survId = client.GetPlayerUserId();
				if (survId in g_survCharacter) continue;
				
				g_survCharacter[survId] <- NetProps.GetPropInt(client, "m_survivorCharacter");
				NetProps.SetPropInt(client, "m_survivorCharacter", 8);
				
				/*local survSet = GetSurvSet();
				if ((survSet == 1 && char == 0) || char == 4)
				{
					local userId = client.GetPlayerUserId();
					if (char == 4)
					{if (g_survBCharacter.find(userId) == null) g_survBCharacter.append(userId);}
					else
					{if (g_survNCharacter.find(userId) == null) g_survNCharacter.append(userId);}
					NetProps.SetPropInt(client, "m_survivorCharacter", 8);
				}*/
			}
			//g_ModeScript.DeepPrintTable(g_survCharacter);
			break;
		default:
			//printl("AlterSurvivorNetProps false called")
			if (g_survCharacter.len() != 0)
			{
				foreach (key, client in survList)
				{
					//local char = NetProps.GetPropInt(client, "m_survivorCharacter");
					//if (GetSurvSet() != 1 && char != 0 && char != 4) continue;
					local survId = client.GetPlayerUserId();
					if (!(survId in g_survCharacter)) continue;
					
					NetProps.SetPropInt(client, "m_survivorCharacter", g_survCharacter[survId]);
					delete g_survCharacter[survId];
				}
			}
			/*if (g_survBCharacter.len() != 0)
			{
				for (local i = 0; i < g_survBCharacter.len(); i++)
				{
					local client = GetPlayerFromUserID(g_survBCharacter[i]);
					if (client == null)
					{
						g_survBCharacter.remove(i); i = i - 1;
						continue;
					}
					
					NetProps.SetPropInt(client, "m_survivorCharacter", 4);
					g_survBCharacter.remove(i); i = i - 1;
				}
			}
			if (g_survNCharacter.len() != 0)
			{
				for (local i = 0; i < g_survNCharacter.len(); i++)
				{
					local client = GetPlayerFromUserID(g_survNCharacter[i]);
					if (client == null)
					{
						g_survNCharacter.remove(i); i = i - 1;
						continue;
					}
					
					NetProps.SetPropInt(client, "m_survivorCharacter", 0);
					g_survNCharacter.remove(i); i = i - 1;
				}
			}*/
			//g_ModeScript.DeepPrintTable(g_survCharacter);
			break;
		}
	}
	
	// --=EVENT=-- Map Transition Inventory Saving
	function OnGameEvent_map_transition( params )
	{
		if (!Settings.restoreExtraSurvsItemsOnTransition) return;
		switch (baseMode)
		{
		case "versus":
		case "scavenge":
			return;
		}
		if (!("VSSMMapTrans" in getroottable()))
		{
			SpawnEntityGroupFromTable({
				[0] = {
					env_global = {
						spawnflags = (1 << 0),
						initialstate = 1,
						globalstate = "mapTransitioned"
					}
				}
			});
		}
		
		//local bottedIDs = [];
		
		// game apparently lowers case of healthbuffer to healthbuffer which 
		// breaks the check for exactly healthbuffer
		// for no reason
		// but NOT revivecount, revivecount is untouched
		// WHY DOES THIS INCONSISTENCY EXIST
		// WHAT THE FLYING FUCK SaveTable
		// edit: may be related to Squirrel's equivalent of stringtables
		local saveTbl = {};
		local survList = RetrieveSurvList(false);
		local gameSurvSlots = survManager.GetNumberOrderSlots(survList);
		foreach (key, client in survList)
		{
			if (NetProps.GetPropInt(client, "m_iTeamNum") != 2)
				continue;
			//if (NetProps.HasProp(client, "m_humanSpectatorUserID"))
			//{bottedIDs.append(NetProps.GetPropInt(client, "m_humanSpectatorUserID"));}
			
			local survSlot = gameSurvSlots.find(client);
			if (survSlot == null) continue;
			// first 4 slots are already handled by the game, ideally shouldn't save
			// but there are edge cases with team 4 survivors that can block this
			// gadzooks
			
			local invTable = {};
			GetInvTable(client, invTable);
			
			local converTable = {};
			converTable["character"] <- NetProps.GetPropInt(client, "m_survivorCharacter");
			local isHanging = client.IsHangingFromLedge();
			local isDead = (client.IsDead() || client.IsDying());
			if (isDead)
			{converTable["health"] <- 0;}
			else if (client.IsIncapacitated() && !isHanging)
			{
				converTable["incapped"] <- 0;
			}
			else
			{
				if (isHanging) client.ReviveFromIncap();
				
				converTable["health"] <- client.GetHealth();
				local healthbuffer = client.GetHealthBuffer();
				if (healthbuffer != 0)
				{converTable["healthbuffer"] <- healthbuffer;}
			}
			local revivecount = NetProps.GetPropInt(client, "m_currentReviveCount");
			if (!isDead && revivecount != 0)
			{converTable["revivecount"] <- revivecount;}
			
			foreach (key, val in invTable)
			{
				switch (key)
				{
				case "slot0":
					converTable["slot0"] <- {};
					converTable.slot0.classname <- val.GetClassname();
					
					local saveVal = val.Clip1();
					if (saveVal != -1) converTable.slot0.clip1 <- saveVal;
					saveVal = val.Clip2();
					if (saveVal != -1) converTable.slot0.clip2 <- saveVal;
					
					saveVal = 
					(NetProps.HasProp(val, "m_upgradeBitVec")) ? NetProps.GetPropInt(val, "m_upgradeBitVec") : 0;
					if (saveVal != 0) converTable.slot0.upgradebit <- saveVal;
					saveVal = 
					(NetProps.HasProp(val, "m_nUpgradedPrimaryAmmoLoaded")) ? NetProps.GetPropInt(val, "m_nUpgradedPrimaryAmmoLoaded") : 0;
					if (saveVal != 0) converTable.slot0.upgradeclip <- saveVal;
					
					saveVal = 
					NetProps.GetPropIntArray(client, "m_iAmmo", NetProps.GetPropInt(val, "m_iPrimaryAmmoType"));
					if (saveVal != 0 && saveVal != -1) converTable.slot0.ammo <- saveVal;
					
					saveVal = 
					NetProps.GetPropInt(val, "m_nSkin");
					if (saveVal != 0) converTable.slot0.skin <- saveVal;
					break;
				case "slot1":
					converTable["slot1"] <- {};
					converTable.slot1.classname <- val.GetClassname();
					
					local saveVal = null;
					if (NetProps.HasProp(val, "m_strMapSetScriptName"))
					{
						saveVal = 
						NetProps.GetPropString(val, "m_strMapSetScriptName");
						if (saveVal.len() != 0) converTable.slot1.melee <- saveVal;
						
						saveVal = 
						NetProps.GetPropInt(val, "m_iBloodyWeaponLevel");
						if (saveVal != 0) converTable.slot1.bloodlevel <- saveVal;
					}
					else
					{
						local saveVal = val.Clip1();
						if (saveVal != -1) converTable.slot1.clip1 <- saveVal;
						saveVal = val.Clip2();
						if (saveVal != -1) converTable.slot1.clip2 <- saveVal;
						
						saveVal = 
						(NetProps.HasProp(val, "m_isDualWielding")) ? NetProps.GetPropInt(val, "m_isDualWielding") : 0;
						if (saveVal != 0) converTable.slot1.dual <- saveVal;
					}
					
					saveVal = 
					NetProps.GetPropInt(val, "m_nSkin");
					if (saveVal != 0) converTable.slot1.skin <- saveVal;
					break;
				case "slot2":
				case "slot3":
				case "slot4":
				case "slot5": // gnome or cola, TODO: can't delete old ones because it's autodropped and converted to prop_physics so we end up having dupes
					if (!("extras" in converTable))
					{converTable["extras"] <- {};}
					
					converTable.extras[(converTable.extras.len())] <- val.GetClassname();
					break;
				}
			}
			
			saveTbl[survSlot] <- converTable;
		}
		//g_ModeScript.DeepPrintTable(saveTbl);
		SaveTable("VSSM_SlotInvs", saveTbl);
		// todo: finish spec preference
		// maybe probably not workable
		/*local specTblTemp = {};
		local specList = RetrieveSpecList(false);
		foreach (key, client in specList)
		{
			if (IsPlayerABot(client)) continue;
			switch (NetProps.GetPropInt(client, "m_iTeamNum"))
			{
				case 0:
				case 1:
					if (!(client.GetPlayerUserId() in bottedIDs))
						specTblTemp.append(client.GetNetworkIDString());
					break;
			}
		}
		if (specTblTemp.len() != 0) SaveTable("VSSM_PreferSpec", specTblTemp);*/
	}
	
	transItemsEvent = null,
	function EvFunc1()
	{
		if (activator == null) return;
		this.VSSMOldState <- NetProps.GetPropInt(activator, "m_lifeState");
		NetProps.SetPropInt(activator, "m_lifeState", 2);
	}
	function EvFunc2()
	{
		if (!("VSSMOldState" in this)) return;
		if (activator != null)
			NetProps.SetPropInt(activator, "m_lifeState", this.VSSMOldState);
		
		delete this.VSSMOldState;
	}
	function DoTransEvent(client, wasDead = null)
	{
		if (transItemsEvent == null || !transItemsEvent.IsValid())
		{
			transItemsEvent = SpawnEntityFromTable("logic_game_event", {
				eventName = "player_transitioned",
				spawnflags = 1,
			});
			if (transItemsEvent == null) return;
		}
		if (wasDead != null)
		{
			local worldSpawn = Entities.First();
			if (worldSpawn.ValidateScriptScope())
			{
				local worldScope = worldSpawn.GetScriptScope();
				if (!("VSSMEvFunc1" in worldScope) || worldScope.VSSMEvFunc1 == null)
					worldScope.VSSMEvFunc1 <- EvFunc1.weakref();
				if (!("VSSMEvFunc2" in worldScope) || worldScope.VSSMEvFunc2 == null)
					worldScope.VSSMEvFunc2 <- EvFunc2.weakref();
				
				DoEntFire("!self", "CallScriptFunction", "VSSMEvFunc1", 0, client, worldSpawn);
				DoEntFire("!self", "FireEvent", "", 0, client, transItemsEvent);
				DoEntFire("!self", "CallScriptFunction", "VSSMEvFunc2", 0, client, worldSpawn);
				return;
			}
		}
		DoEntFire("!self", "FireEvent", "", 0.01, client, transItemsEvent);
	}
	/*function OnGameEvent_player_transitioned( params )
	{
		printl("player_transitioned");
		g_ModeScript.DeepPrintTable(params);
		if ("userid" in params)
		{
			local client = GetPlayerFromUserID(params["userid"]);
			if (client != null && client.IsValid())
			{
				local invTable = {};
				GetInvTable(client, invTable);
				printl("inventory of "+client+":");
				g_ModeScript.DeepPrintTable(invTable);
			}
		}
	}*/
	
	function ConvertTbl(targetTbl)
	{
		foreach (key, val in targetTbl)
		{
			local keyLower = key.tolower();
			if (typeof(val) == "table")
			{
				ConvertTbl(val);
			}
			if (key != keyLower)
			{
				targetTbl[keyLower] <- val;
				delete targetTbl[key];
			}
		}
	}
	function RestoreTransItems(client, origWeps = null, survSlot = null, doEvent = null)
	{
		if (!Settings.restoreExtraSurvsItemsOnTransition) return false;
		if (VSSMTransItemsTbl == null) return false;
		if (!("VSSMMapTrans" in getroottable()))
		{
			VSSMTransItemsTbl = null;
			return false;
		}
		
		if (VSSMTransItemsTbl.len() == 0)
		{
			RestoreTable("VSSM_SlotInvs", VSSMTransItemsTbl);
			// bullshit vscript parser Nescius says is screwing up and
			// setting some keys in this table to wrong cases, idk how but 
			// gotta use tolower brute force
			ConvertTbl(VSSMTransItemsTbl);
		}
		if (VSSMTransItemsTbl.len() != 0)
		{
			if (survSlot == null) survSlot = client.GetSurvivorSlot();
			if (survSlot in transItemsGranted) return false;
			
			local survSlotStr = survSlot.tostring();
			if (survSlotStr in VSSMTransItemsTbl)
			{
				local clOrigin = client.EyePosition();
				local wasDead = null;
				foreach (key, val in VSSMTransItemsTbl[survSlotStr])
				{
					//printl("key: "+key+" val: "+val);
					switch (key)
					{
					case "character":
						SetCharacter(client, val);
						break;
					case "health":
						if (val == 0)
						{
							wasDead = true;
							client.SetHealth(Convars.GetFloat("z_survivor_respawn_health"));
						}
						else
							client.SetHealth(val);
						break;
					case "healthbuffer":
						client.SetHealthBuffer(val);
						break;
					case "incapped":
						client.SetHealth(1);
						client.SetHealthBuffer(Convars.GetFloat("survivor_revive_health"));
						if (!("revivecount" in VSSMTransItemsTbl[survSlotStr]))
						{
							client.SetReviveCount(1);
							NetProps.SetPropInt(client, "m_isGoingToDie", 1);
						}
						break;
					case "revivecount":
						if ("incapped" in VSSMTransItemsTbl[survSlotStr]) val = val + 1;
						client.SetReviveCount(val);
						NetProps.SetPropInt(client, "m_isGoingToDie", 1);
						break;
					
					case "slot0":
					case "slot1":
						local isMelee = ("melee" in VSSMTransItemsTbl[survSlotStr][key]);
						local newWepTbl = {
							origin = clOrigin,
						};
						if (isMelee) newWepTbl.melee_script_name <- VSSMTransItemsTbl[survSlotStr][key].melee;
						
						local newWep = SpawnEntityFromTable(VSSMTransItemsTbl[survSlotStr][key].classname, newWepTbl);
						if (newWep == null || !newWep.IsValid()) break;
						
						if (isMelee)
						{
							if ("bloodlevel" in VSSMTransItemsTbl[survSlotStr][key])
							{NetProps.SetPropInt(newWep, "m_iBloodyWeaponLevel", VSSMTransItemsTbl[survSlotStr][key].bloodlevel);}
						}
						else
						{
							if ("clip1" in VSSMTransItemsTbl[survSlotStr][key])
							{newWep.SetClip1(VSSMTransItemsTbl[survSlotStr][key].clip1);}
							if ("clip2" in VSSMTransItemsTbl[survSlotStr][key])
							{newWep.SetClip2(VSSMTransItemsTbl[survSlotStr][key].clip2);}
							
							if ("ammo" in VSSMTransItemsTbl[survSlotStr][key])
							{NetProps.SetPropIntArray(client, "m_iAmmo", VSSMTransItemsTbl[survSlotStr][key].ammo, NetProps.GetPropInt(newWep, "m_iPrimaryAmmoType"));}
							
							if ("upgradebit" in VSSMTransItemsTbl[survSlotStr][key])
							{NetProps.SetPropInt(newWep, "m_upgradeBitVec", VSSMTransItemsTbl[survSlotStr][key].upgradebit);}
							if ("upgradeclip" in VSSMTransItemsTbl[survSlotStr][key])
							{NetProps.SetPropInt(newWep, "m_nUpgradedPrimaryAmmoLoaded", VSSMTransItemsTbl[survSlotStr][key].upgradeclip);}
							
							if ("dual" in VSSMTransItemsTbl[survSlotStr][key])
							{
								//local newWep2 = SpawnEntityFromTable(VSSMTransItemsTbl[survSlotStr][key].classname, newWepTbl);
								//DoEntFire("!self", "Use", "", 0, client, newWep2);
								NetProps.SetPropInt(newWep, "m_isDualWielding", VSSMTransItemsTbl[survSlotStr][key].dual);
							}
						}
						
						if ("skin" in VSSMTransItemsTbl[survSlotStr][key])
						{NetProps.SetPropInt(newWep, "m_nSkin", VSSMTransItemsTbl[survSlotStr][key].skin);}
						NetProps.SetPropInt(newWep, "m_MoveType", 0);
						DoEntFire("!self", "Use", "", 0, client, newWep);
						break;
					
					case "extras":
						for (local i = 0; i < VSSMTransItemsTbl[survSlotStr][key].len(); i++)
						{
							local newWep = SpawnEntityFromTable(VSSMTransItemsTbl[survSlotStr][key][i.tostring()], {
								origin = clOrigin,
							});
							NetProps.SetPropInt(newWep, "m_MoveType", 0);
							DoEntFire("!self", "Use", "", 0, client, newWep);
						}
						break;
					}
				}
				transItemsGranted.append(survSlot);
				if (origWeps != null && wasDead == null)
				{
					foreach (key, val in origWeps)
					{
						if (NetProps.HasProp(val, "m_isDualWielding") && NetProps.GetPropInt(val, "m_isDualWielding") != 0)
						{
							NetProps.SetPropInt(val, "m_isDualWielding", 0);
						}
						survManager.DropItemCheck(client, val.GetClassname());
						val.Kill();
					}
				}
				if (doEvent != null) DoTransEvent(client, wasDead);
				return true;
			}
		}
		else
		{ VSSMTransItemsTbl = null; }
		return false;
	}
	
	function GiveStartItems(client, origWeps = null, noDirItems = null)
	{
		//if (startItemsGranted.find(client.GetSurvivorSlot()) != null) return;
		
		local clOrigin = client.EyePosition();
		
		local function DoMelee(val)
		{
			local newWep = SpawnEntityFromTable("weapon_melee", {
				origin = clOrigin,
				melee_script_name = val,
			});
			if (newWep == null) return null;
			if (NetProps.GetPropInt(newWep, "m_nModelIndex") == errorMeleeIdx)
			{
				newWep.Kill();
				return null;
			}
			return newWep;
		}
		local function BackupPistol()
		{
			local newWep = SpawnEntityFromTable("weapon_pistol", {
				origin = clOrigin,
			});
			if (newWep != null)
				DoEntFire("!self", "Use", "", 0, client, newWep);
		}
		
		local function IterateTbl(key, val)
		{
			//printl("key: "+key+" val: "+val)
			if (val == "base") return;
			
			local hasKey = (key in startWepsType);
			local typeWep = null;
			if (startWepsType.len() != 0 && hasKey)
			{
				switch (startWepsType[key])
				{
				case 0: // gun
					typeWep = 0;
					break;
				case 1: // melee
					typeWep = 1;
					break;
				}
				// otherwise keyval is null, default to spawning pistol
				if (typeWep == null)
				{
					BackupPistol();
					return;
				}
			}
			
			local newType = null;
			local newWep = null;
			switch (typeWep)
			{
			case 1:
				newWep = DoMelee(val);
				if (!hasKey) newType = 1;
				break;
			default:
				// both null and 0 considered gun
				// difference with null is if we reach here, there isn't a table key
				local classWep = null;
				if (6 in val && val[0] == 'w' && val[1] == 'e' && val[2] == 'a' && 
				val[3] == 'p' && val[4] == 'o' && val[5] == 'n' && 
				val[6] == '_')
					classWep = val;
				else
					classWep = "weapon_"+val;
				
				newWep = SpawnEntityFromTable(classWep, {
					origin = clOrigin,
				});
				if (newWep == null)
				{
					// if classname is invalid, maybe it's a melee
					newWep = DoMelee(val);
					if (!hasKey) newType = 1;
				}
				else
				{if (!hasKey) newType = 0;}
				break;
			}
			
			if (newWep != null)
			{
				DoEntFire("!self", "Use", "", 0, client, newWep);
				if (!hasKey) startWepsType[key] <- newType;
			}
			else
			{
				if (!hasKey) startWepsType[key] <- null;
				if (newType == 1)
				{
					// spawn backup pistol if melee doesn't exist
					// this will also trigger for odd things like weapon_wtf
					// if people want to break it then so be it
					BackupPistol();
				}
			}
			// For some reason trying to pickup items with 
			// 0 delay causes consistent crashes
			// weapons still like to crash sometimes......
		}
		
		local survStartWeaponsLen = survManager.Settings.survStartWeapons.len();
		local dirOptionDefaultItemsLen = survManager.dirOptionDefaultItems.len();
		
		local keepBase = survManager.Settings.survStartWeapons.find("base") != null;
		local pistols = 0;
		
		if (keepBase && !(0 in survManager.dirOptionDefaultItems))
		{
			local dirOptions = DirectorScript.GetDirectorOptions();
			if ("GetDefaultItem" in dirOptions)
			{
				local option = 0;
				for (local i = 0; (option = dirOptions.GetDefaultItem(i)) != 0; i++)
				{
					survManager.dirOptionDefaultItems.append(option);
				}
				dirOptionDefaultItemsLen = survManager.dirOptionDefaultItems.len();
			}
		}
		
		if ((dirOptionDefaultItemsLen != 0 && noDirItems == null) || survStartWeaponsLen != 0 && !keepBase)
		{
			if (origWeps != null)
			{
				// TODO: potential entity slots can be filled by old weapons and 
				// new weapons at same time momentarily
				// maybe delay the weapon spawning?
				foreach (key, val in origWeps)
				{
					if (NetProps.HasProp(val, "m_isDualWielding") && NetProps.GetPropInt(val, "m_isDualWielding") != 0)
					{
						NetProps.SetPropInt(val, "m_isDualWielding", 0);
					}
					survManager.DropItemCheck(client, val.GetClassname());
					val.Kill();
				}
				// DropItem needs to be called because Kill doesn't remove
				// from inventory immediately, so it can block Use pickups
			}
		}
		
		// the game gives weapons only on (re)start, not to newly spawned survs
		if (dirOptionDefaultItemsLen != 0 && noDirItems == null)
		{
			for (local i = 0; i < dirOptionDefaultItemsLen; i++)
			{
				IterateTbl(i, survManager.dirOptionDefaultItems[(i)]);
			}
		}
		if (survStartWeaponsLen != 0)
		{
			for (local i = 0; i < survStartWeaponsLen; i++)
			{
				IterateTbl(i, survManager.Settings.survStartWeapons[(i)]);
			}
		}
	}
	
	// fix the extra survivors being left behind by dynamically spawning positions
	function OnGameEvent_finale_vehicle_leaving( params )
	{
		//local survList = null;
		local survCount = null;
		if (!("survivorcount" in params))
		{
			local finaleTrig = FindRescueAreaTrigger();
			if (finaleTrig == null) return;
			
			local survList = survManager.RetrieveSurvList(false);
			local survListLen = survList.len();
			foreach (key, client in survList)
			{
				if (NetProps.GetPropInt(client, "m_iTeamNum") != 2 || 
				!finaleTrig.IsTouching(client))
				{
					survListLen = survListLen - 1;
				}
				//printl("toucher: "+client);
			}
			survCount = survListLen;
		}
		else
			survCount = params.survivorcount;
		
		// survivorcount keeps track of the extra survivors at least
		//printl("finale_vehicle_leaving");
		//g_ModeScript.DeepPrintTable(params);
		
		local survPositions = [];
		local survOrders = [];
		for (local survPos; survPos = Entities.FindByClassname( survPos, "info_survivor_position" );)
		{
			if (survPos == null) continue;
			
			// Cambalache 2 decide to reuse survival-only marked positions as rescue
			// but it also revealed gamemode doesn't matter for finale rescues
			// https://steamcommunity.com/sharedfiles/filedetails/?id=2888803926
			//local survName = NetProps.GetPropString(survPos, "m_iszSurvivorName");
			//local gameModeStr = NetProps.GetPropString(survPos, "m_iszGameMode");
			//if (gameModeStr.len() != 0 && gameModeStr.find(baseMode) == null) continue;
			
			survPositions.append(survPos);
			local order = NetProps.GetPropInt(survPos, "m_order");
			if (order > 0)
				survOrders.append(order);
			//else
			//	survOrders.append(null);
		}
		//g_ModeScript.DeepPrintTable(survPositions);
		//g_ModeScript.DeepPrintTable(survOrders);
		local survPositionsLen = survPositions.len();
		if (survPositionsLen == 0)
		{
			// umm, what kind of finale is this shit
			if (!isDedicated)
			{
				ClientPrint(GetListenServerHost(), 3, "\x03"+"[VSSM]"+"\x04"+"\nWARNING:"+"\x01"+"\nCouldn't find proper info_survivor_position entities for rescue!");
			}
			else
			{
				printl("[VSSM]\nWARNING:\nCouldn't find proper info_survivor_position entities for rescue!");
			}
			/*if (survList == null) survList = survManager.RetrieveSurvList(false);
			survPositions.clear();
			survOrders.clear();
			foreach (key, client in survList)
			{
				survPositions = survList;
				survPositionsLen = survList.len();
			}*/
			return;
		}
		
		//local posTbl = {};
		local posVar = 0;
		for (local i = 1; i <= survCount; i++)
		{
			if (survPositionsLen != 0)
			{
				if (survOrders.find(i) != null) continue;
				//if (i <= survPositionsLen) continue;
			
				local basePos = survPositions[posVar];
				posVar++;
				if (posVar >= survPositionsLen) posVar = 0;
				
				SpawnEntityFromTable("info_survivor_position", {
					origin = basePos.GetOrigin().ToKVString(),
					angles = basePos.GetAngles().ToKVString(),
					order = i,
				});
			}
			else
			{
				SpawnEntityFromTable("info_survivor_position", {
					order = i,
				});
				// TODO
				/*SpawnEntityGroupFromTable({
					[0] = {
						info_survivor_position = {
							origin = basePos.GetOrigin().ToKVString(),
						}
					}
				});*/
			}
		}
	}
	
	function OnMapSpawn()
	{
		IncludeScript("vssm/map_support", getroottable());
	}
}
local weakRef = survManager.ChargerGrabOrImpact.weakref();
survManager.OnGameEvent_charger_impact <- weakRef;
survManager.OnGameEvent_charger_carry_start <- weakRef;

survManager.IFOverride0Ref <- survManager.IFOverride0.weakref();
survManager.IFOverride1Ref <- survManager.IFOverride1.weakref();
survManager.IFKillRef <- survManager.IFKill.weakref();
survManager.IFKillHierarchyRef <- survManager.IFKillHierarchy.weakref();
survManager.IFTeleportToSurvivorPositionRef <- survManager.IFTeleportToSurvivorPosition.weakref();
survManager.IFReleaseFromSurvivorPositionRef <- survManager.IFReleaseFromSurvivorPosition.weakref();
survManager.IFSetGlowEnabledRef <- survManager.IFSetGlowEnabled.weakref();
survManager.IFClearContextRef <- survManager.IFClearContext.weakref();

if (!("VSSM_rr_GetResponseTargets" in this) && survManager.GetSurvSet() == 1)
{
	this.VSSM_rr_GetResponseTargets <- this.rr_GetResponseTargets;
	this.rr_GetResponseTargets <- function()
	{
		local responseTbl = {};
		local survList = survManager.RetrieveSurvList(false);
		foreach (key, client in survList)
		{
			local survChar = NetProps.GetPropInt(client, "m_survivorCharacter");
			switch (survChar)
			{
			case 4:
				responseTbl["Gambler"] <- client;
				break;
			case 5:
				responseTbl["Producer"] <- client;
				break;
			case 7:
				responseTbl["Coach"] <- client;
				break;
			case 6:
				responseTbl["Mechanic"] <- client;
				break;
			case 0:
				responseTbl["NamVet"] <- client;
				break;
			case 1:
				responseTbl["TeenGirl"] <- client;
				break;
			case 3:
				responseTbl["Biker"] <- client;
				break;
			case 2:
				responseTbl["Manager"] <- client;
				break;
			default:
				responseTbl["Unknown"] <- client;
				break;
			}
		}
		return responseTbl;
	}
}

//if (errorMeleeIdx == null)
//{
if (!IsModelPrecached("models/v_models/weapons/v_claw_hunter.mdl"))
{errorMeleeIdx = PrecacheModel("models/v_models/weapons/v_claw_hunter.mdl");}
else
{errorMeleeIdx = GetModelIndex("models/v_models/weapons/v_claw_hunter.mdl");}
//}

survManager.EnsureSpawner();
survManager.ParseConfigFile();

if (!FileToString(info_path))
{
	/*StringToFile(info_path,"THIS IS ONLY AN INFO FILE IN CASE YOU DON'T KNOW WHAT THE SETTINGS DO.\n
	Don't edit this to change the settings.\n
	Delete this file and load a map with updated mod version to regenerate new info for updated settings.\n
	\n
	Chat Commands (use with / or !):\n
	\t!survcount <number> - Set the survCount setting and refresh it in-game. This will spawn in the appropriate amount of survivor bots, handles the auto-management of number of survivors and saves permanently across all games in it's settings file.\n
	\t!survkick - Remove a bot in your crosshair, or nearest to it.\n
	\t!survbot <number, leave empty for 1> <forced character, use first letter like z for zoey> <number of forced characters, optional and defaults to number of added bots> - Manually add survivor bots.\n
	\t!survorder <character list> - Change the survivor order the Auto-Manager spawns bots in. Leave empty to reset to default survivor order.\n
	\tExample: !survorder b z e f n c l r z l\n
	\t!survswap - Takeover control to your crosshair's nearest survivor bot. Will not work if you or the bot are pinned, downed, or dead.\n
	\t!survfix - Re-enables the Auto-Manager if you screw up the bot count.\n
	\tRemember folks, don't be a funnyman and type in 69 or 4001 or some other big number. It gets you nowhere.\n
	\n
	- survCount (Survivor count the mod aims for when auto-checking when a new player joins or map changes, etc.\n
	The max amount that is mostly safe is 8, going beyond it can block special infected from spawning.\n
	The game has a max limit of 18 survivors, trying to spawn more survivors will fail)\n
	\n
	- removeExcessSurvivors (Remove survivor bots over the limit.)\n
	\n
	- survStartWeapons (List of weapons to give to newly-spawned survivors. Any weapon can be given, but primary weapons will have no reserve ammo.\n
	Use the give command as a reference of items that can be given. Everything must be lower-case. There is one exclusive key for this setting.\n
	To keep weapons given to the survivors including mutations, eg. a pistol or katana, use \"base\" and add to this setting as if it were a weapon.)\n
	\n
	- survCharOrderL4D* (Survivor order to pick from. This order will loop back around if the entire order is already picked.\n
	survCharOrderL4D1 for maps that use playable L4D1 survivor set.\n
	survCharOrderL4D2 for maps that use playable L4D2 survivor set.)\n
	\n
	- fixUpgradePacks (Fixes upgrade packs for 5+ survivors. Side-effects:\n
	Upgrade packs will glow even if you already used them.\n
	Survivor bots will gain 1 upgrade ammo by using it again due to bypassing VScript hooks.)\n
	\n
	- autoControlExtraBots (Auto-assigns any spectators to a survivor bot on join.\n
	Main use is for lobby. Untested as of 7/18/2023)\n
	\n
	- fixChargerHits (Fixes chargers unable to hit and toss same-character survivors like 3 Coaches acting as brick walls. Side-effects:\n
	This is a fake effect, it is impossible to use the real effect with VScript as of 7/18/2023.\n
	Animation does not work properly for clone survivors, they will spaz out and always loop first animation frames.\n
	Likely server-intensive, runs on a situational think hook.)\n
	\n
	- fixDefibrillator (Fixes defibrillators reviving the wrong survivors. Side-effects:\n
	Uses text chat to tell players who defibbed who.\n
	Plugins won't respond properly to this hacky fix defib by VScript.\n
	L4D2 survivors don't defib at all on L4D1 survivor set if corresponding proper L4D1 survivor is not in game.\n
	{Example: If you don't have Louis, you can't defib Coach. If you don't have Bill, you can't defib Nick.}\n
	Likely server-intensive, DefibCheck function pops up in console being 2 miliseconds long.)\n
	\n
	- fixFriendlyFireLines (Fixes friendly fire lines not playing on the extra survivors.\n
	However, the Don't shoot teammates! instruction will not appear.)\n
	\n
	- autoCheckpointFirstAid (Automatically alter the first aid kits to fit the number of survCount in checkpoints to next maps.\n
	Doesn't affect starting saferoom.)\n
	\n
	- restoreExtraSurvsItemsOnTransition (Let the mod store and restore the inventories of the 5th survivor and more.\nBy default, these extra survivors' inventories get wiped.)\n
	\n
	- allowSurvSwapCmdForUsers (Allow swap control over bot survivors for everyone instead of just admins.\n
	Does not use sb_takecontrol, uses a very hacky method to do so, can cause bugs with other scripts and plugins.)");*/
	
	StringToFile(info_path,"THIS IS ONLY AN INFO FILE IN CASE YOU DON'T KNOW WHAT THE SETTINGS DO.\nDon't edit this to change the settings.\nDelete this file and load a map with updated mod version to regenerate new info for updated settings.\n\nChat Commands (use with / or !):\n\t!survcount <number> - Set the survCount setting and refresh it in-game. This will spawn in the appropriate amount of survivor bots, handles the auto-management of number of survivors and saves permanently across all games in it's settings file.\n\t!survkick - Remove a bot in your crosshair, or nearest to it.\n\t!survbot <number, leave empty for 1> <forced character, use first letter like z for zoey> <number of forced characters, optional and defaults to number of added bots> - Manually add survivor bots.\n\t!survorder <character list> - Change the survivor order the Auto-Manager spawns bots in. Leave empty to reset to default survivor order.\n\tExample: !survorder b z e f n c l r z l\n\t!survswap - Takeover control to your crosshair's nearest survivor bot. Will not work if you or the bot are pinned, downed, or dead.\n\t!survfix - Re-enables the Auto-Manager if you screw up the bot count.\n\tRemember folks, don't be a funnyman and type in 69 or 4001 or some other big number. It gets you nowhere.\n\n- survCount (Survivor count the mod aims for when auto-checking when a new player joins or map changes, etc.\nThe max amount that is mostly safe is 8, going beyond it can block special infected from spawning.\nThe game has a max limit of 18 survivors, trying to spawn more survivors will fail)\n\n- removeExcessSurvivors (Remove survivor bots over the limit.)\n\n- survStartWeapons (List of weapons to give to newly-spawned survivors. Any weapon can be given, but primary weapons will have no reserve ammo.\nUse the give command as a reference of items that can be given. Everything must be lower-case. There is one exclusive key for this setting.\nTo keep weapons given to the survivors including mutations, eg. a pistol or katana, use \"base\" and add to this setting as if it were a weapon.)\n\n- survCharOrderL4D* (Survivor order to pick from. This order will loop back around if the entire order is already picked.\nsurvCharOrderL4D1 for maps that use playable L4D1 survivor set.\nsurvCharOrderL4D2 for maps that use playable L4D2 survivor set.)\n\n- fixUpgradePacks (Fixes upgrade packs for 5+ survivors. Side-effects:\nUpgrade packs will glow even if you already used them.\nSurvivor bots will gain 1 upgrade ammo by using it again due to bypassing VScript hooks.)\n\n- autoControlExtraBots (Auto-assigns any spectators to a survivor bot on join.\nMain use is for lobby. Untested as of 7/18/2023)\n\n- fixChargerHits (Fixes chargers unable to hit and toss same-character survivors like 3 Coaches acting as brick walls. Side-effects:\nThis is a fake effect, it is impossible to use the real effect with VScript as of 7/18/2023.\nAnimation does not work properly for clone survivors, they will spaz out and always loop first animation frames.\nLikely server-intensive, runs on a situational think hook.)\n\n- fixDefibrillator (Fixes defibrillators reviving the wrong survivors. Side-effects:\nUses text chat to tell players who defibbed who.\nPlugins won't respond properly to this hacky fix defib by VScript.\nL4D2 survivors don't defib at all on L4D1 survivor set if corresponding proper L4D1 survivor is not in game.\n{Example: If you don't have Louis, you can't defib Coach. If you don't have Bill, you can't defib Nick.}\nLikely server-intensive, DefibCheck function pops up in console being 2 miliseconds long.)\n\n- fixFriendlyFireLines (Fixes friendly fire lines not playing on the extra survivors.\nHowever, the Don't shoot teammates! instruction will not appear.)\n\n- autoCheckpointFirstAid (Automatically alter the first aid kits to fit the number of survCount in checkpoints to next maps.\nDoesn't affect starting saferoom.)\n\n- restoreExtraSurvsItemsOnTransition (Let the mod store and restore the inventories of the 5th survivor and more.\nBy default, these extra survivors' inventories get wiped.)\n\n- allowSurvSwapCmdForUsers (Allow swap control over bot survivors for everyone instead of just admins.\nDoes not use sb_takecontrol, uses a very hacky method to do so, can cause bugs with other scripts and plugins.)");
}

SpawnEntityGroupFromTable({
	[0] = {
		logic_relay = {
			spawnflags = (1 << 0),
			connections =
			{
				OnSpawn =
				{
					cmd1 = "worldspawnRunScriptCodesurvManager.OnMapSpawn()01"
				}
			}
		}
	},
});
}

__CollectEventCallbacks(survManager, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);

if (!("g_MapName" in this)) g_MapName <- Director.GetMapName().tolower();
// do this in here as map_support runs too late
// it's ugly but it's the only thing that can be done
switch (g_MapName)
{
case "glubtastic4_7":
	local giverTrigger = Entities.FindByClassnameNearest("trigger_once", Vector(-860, -100, -960), 20);
	if (giverTrigger != null)
	{
		EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "louis", "SpawnSurvivor", "");
		EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "francis", "SpawnSurvivor", "");
		EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "!francis", "SetGlowEnabled", "false");
		EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "!louis", "SetGlowEnabled", "false");
		EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "!francis", "RunScriptFile", "giveshotgun");
		EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "!louis", "RunScriptFile", "giveshotgun");
		
		EntFire("francis", "SpawnSurvivor", "", 0.1);
		EntFire("louis", "SpawnSurvivor", "", 0.1);
		EntFire("!francis", "SetGlowEnabled", "0", 0.15);
		EntFire("!louis", "SetGlowEnabled", "0", 0.15);
	}
	break;
}

// unused for now, not finished
//IncludeScript( "vscript_music_set", getroottable() );
/*} catch (err) {
	if (!IsDedicatedServer())
	{
		ClientPrint(null, 3, "\x03"+"[VSSM]"+"\x04"+"\nCODE ERROR: "+"\x01"+err);
	}
	else
	{
		printl("[VSSM]\nCODE ERROR: "+err);
	}
}*/