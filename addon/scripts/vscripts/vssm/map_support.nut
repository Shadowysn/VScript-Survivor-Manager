//printl("map_support is run!")
if (!("g_MapName" in this)) g_MapName <- Director.GetMapName().tolower();

local function GetWorldSpawn()
{
	local worldSpawn = Entities.First();
	if (!worldSpawn.ValidateScriptScope()) return null;
	return [worldSpawn, worldSpawn.GetScriptScope()];
}

survManager.AlterStrip1 <- function()
{
	survManager.AlterSurvivorNetProps(true);
	if (!("VSSMIFOvr" in this)) this.VSSMIFOvr <- null;
}
survManager.AlterStrip2 <- function()
{
	survManager.AlterSurvivorNetProps(false);
	if ("VSSMIFOvr" in this) delete this.VSSMIFOvr;
}

survManager.IFSpawnSurvivor <- function()
{
	if (!("VSSMIFOvr" in this))
	{
		local chosenChar = NetProps.GetPropInt(self, "m_character");
		if (chosenChar in infoSpawnedSurvsList)
		{
			local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[chosenChar]);
			if (infoBot != null)
			{
				infoBot.SetOrigin(self.GetOrigin());
				return false;
			}
		}
		
		DoEntFire("!self", "CallScriptFunction", "VSSMFunc", 0, null, self);
		DoEntFire("!self", "SpawnSurvivor", "", 0, activator, self);
		DoEntFire("!self", "CallScriptFunction", "VSSMFunc2", 0, null, self);
		survManager.expectedInfoBots = survManager.expectedInfoBots + 1;
		return false;
	}
	else
		return true;
}
survManager.IFSpawnSurvivorRef <- survManager.IFSpawnSurvivor.weakref();
survManager.AlterStrip1Ref <- survManager.AlterStrip1.weakref();
survManager.AlterStrip2Ref <- survManager.AlterStrip2.weakref();

local director = Entities.FindByClassname(null, "info_director");
if (director != null && director.ValidateScriptScope())
{
	local directorScope = director.GetScriptScope();
	directorScope.VSSMGetPos <- function()
	{
		local survPosChars = [];
		local survPosList = [];
		for (local survPos; survPos = Entities.FindByClassname( survPos, "info_survivor_position" );)
		{
			survPosList.append(survPos);
			local survName = NetProps.GetPropString(survPos, "m_iszSurvivorName").tolower();
			switch (survName)
			{
			case "nick":		survPosChars.append(0);		break;
			case "bill":		survPosChars.append(4);		break;
			case "rochelle":	survPosChars.append(1);		break;
			case "zoey":		survPosChars.append(5);		break;
			case "coach":		survPosChars.append(2);		break;
			case "louis":		survPosChars.append(7);		break;
			case "ellis":		survPosChars.append(3);		break;
			case "francis":		survPosChars.append(6);		break;
			//default:			survPosChars.append(null);	break;
			}
		}
		if (survPosList.len() == 0) return null;
		
		return [survPosList, survPosChars];
	}
	directorScope.IFForceSurvivorPositions <- function()
	{
		local survPosLists = VSSMGetPos();
		if (survPosLists == null) return true;
		
		local survList = survManager.RetrieveSurvList(false);
		
		//local survPosLists = survPosLists;
		/*local survPosLists = [[], []];
		local function ReClone()
		{
			foreach (k,v in survPosLists[0])
			{survPosLists[0].append(v);}
			foreach (k,v in survPosLists[1])
			{survPosLists[1].append(v);}
		}*/
		
		local isSurvSet1 = (survManager.GetSurvSet() == 1);
		
		local firstCharSurvs = [];
		for (local i = 0; i <= (isSurvSet1 ? 3 : 7); i++)
		{
			local handledChar = GetPlayerFromCharacter(i);
			if (handledChar != null)
				firstCharSurvs.append(handledChar);
		}
		
		local function GetEquivalentChar(survChar)
		{
			switch (survChar)
			{
			case 0:		return 4;
			case 1:		return 5;
			case 2:		return 7;
			case 3:		return 6;
			case 4:		return 0;
			case 5:		return 1;
			case 6:		return 3;
			case 7:		return 2;
			}
			return null;
		}
		foreach (key, client in survList)
		{
			if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
			
			local survChar = NetProps.GetPropInt(client, "m_survivorCharacter");
			if (isSurvSet1)
				survChar = GetEquivalentChar(survChar);
			
			if (survChar < 0 || survChar > 7 || survChar == null) continue;
			
			//local survPosListLen = survPosLists[0].len();
			
			//local dontAdvance = null;
			local chosenPos = null;
			local charArrPos = survPosLists[1].find(survChar);
			if (charArrPos != null)
			{
				// default ForceSurvivorPositions already handles first target survs
				if (firstCharSurvs.find(client) == null)
					chosenPos = survPosLists[0][charArrPos];
				//printl("Found a charArrPos!: "+chosenPos)
				//if (charArrPos != i) dontAdvance = true;
			}
			else
			{
				survChar = GetEquivalentChar(survChar);
				if (survChar != null)
				{
					charArrPos = survPosLists[1].find(survChar);
					if (charArrPos != null)
						chosenPos = survPosLists[0][charArrPos];
				}
			}
			
			/*if (dontAdvance == null)
			{
				i = i + 1;
				if (i >= survPosListLen)
				{
					i = 0;
					//if (survPosListLen == 0)
					//	ReClone();
				}
				chosenPos = survPosLists[0][i];
			}*/
			
			if (chosenPos != null)
			{
				//printl("Teleporting "+GetCharacterDisplayName(client)+" to "+survChar)
				DoEntFire("!self", "RunScriptCode", "self.__KeyValueFromString(\"targetname\",\"vssmtelehack\")", 0, null, chosenPos);
				DoEntFire("!self", "CallScriptFunction", "IFOverride1", 0, null, client);
				DoEntFire("!self", "TeleportToSurvivorPosition", "vssmtelehack", 0, self, client);
				DoEntFire("!self", "CallScriptFunction", "IFOverride0", 0, null, client);
				DoEntFire("!self", "RunScriptCode", "self.__KeyValueFromString(\"targetname\",\""+NetProps.GetPropString(chosenPos, "m_iName")+"\")", 0, null, chosenPos);
				
				/*survPosLists[0].remove(i);
				survPosLists[1].remove(i);
				i = i - 1;*/
				continue;
			}
		}
		firstCharSurvs.clear();
		return true;
	}
	/*directorScope.IFReleaseSurvivorPositions <- function()
	{
		
	}*/
	directorScope.IFForceSurvivorPositionsRef <- directorScope.IFForceSurvivorPositions.weakref();
	local strToUse = "Input"+survManager.GetFromStringTable("ForceSurvivorPositions", director);
	if (!(strToUse in directorScope))
		directorScope[strToUse] <- directorScope.IFForceSurvivorPositionsRef;
	
	// TODO: on official campaigns CharCheck seems to not run before
	// ForceSurvivorPositions is fired, so extra survivors use the 
	// incorrect position when spawning in the map for the first time
	// an inconsistency that needs to be noted
}

/*local outroStats = Entities.FindByClassname(null, "env_outtro_stats");
if (outroStats != null && outroStats.ValidateScriptScope())
{
	local outroScope = outroStats.GetScriptScope();
	outroScope.ZoeySurvs <- {};
	outroScope.IFRollStatsCrawl <- function()
	{
		local survList = survManager.RetrieveSurvList(false);
		foreach (key, client in survList)
		{
			if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
			
			local survChar = NetProps.GetPropInt(client, "m_survivorCharacter");
			if (survChar != 5) continue;
			
			NetProps.SetPropInt(client, "m_survivorCharacter", 1);
			ZoeySurvs.append(client.GetPlayerUserId());
		}
		return true;
	}
	outroScope.ResetChar <- function()
	{
		
	}
	
	outroScope.IFRollStatsCrawlRef <- outroScope.IFRollStatsCrawl.weakref();
	local strToUse = "Input"+survManager.GetFromStringTable("RollStatsCrawl", director);
	if (!(strToUse in outroScope))
		outroScope[strToUse] <- outroScope.IFRollStatsCrawlRef;
}*/

survManager.UpdateMapEntHooking <- function()
{
	for (local survSpawner; survSpawner = Entities.FindByClassname( survSpawner, "info_l4d1_survivor_spawn" );)
	{
		// map-spawned spawners have m_iHammerID != 0
		if (NetProps.GetPropInt(survSpawner, "m_iHammerID") <= 0 || !survSpawner.ValidateScriptScope()) continue;
		
		local spawnerScope = survSpawner.GetScriptScope();
		local strToUse = "Input"+survManager.GetFromStringTable("SpawnSurvivor", survSpawner);
		if (!(strToUse in spawnerScope))
			spawnerScope[strToUse] <- survManager.IFSpawnSurvivorRef;
		
		if (!("VSSMFunc" in spawnerScope))
			spawnerScope.VSSMFunc <- survManager.AlterStrip1Ref;
		if (!("VSSMFunc2" in spawnerScope))
			spawnerScope.VSSMFunc2 <- survManager.AlterStrip2Ref;
	}
}
survManager.UpdateMapEntHooking();
survManager.UpdateMapEntHookingRef <- survManager.UpdateMapEntHooking.weakref();

local function IterateTemplate(template)
{
	/*local hasSpawner = null;
	for (local i = 0; i < NetProps.GetPropArraySize(template, "m_iszTemplateEntityNames"); i++)
	{
		local target = NetProps.GetPropStringArray(template, "m_iszTemplateEntityNames", i);
		if ()
	}*/
	
	if (!template.ValidateScriptScope()) return;
	
	local templateScope = template.GetScriptScope();
	if (!("VSSMUpdMHook" in templateScope))
		templateScope.VSSMUpdMHook <- survManager.UpdateMapEntHookingRef;
	
	EntityOutputs.AddOutput(template, "OnEntitySpawned", "!self", "CallScriptFunction", "VSSMUpdMHook", 0, -1);
}
for (local template; template = Entities.FindByClassname( template, "point_template" );)
{IterateTemplate(template);}
for (local template; template = Entities.FindByClassname( template, "point_script_template" );)
{IterateTemplate(template);}
for (local template; template = Entities.FindByClassname( template, "env_entity_maker" );)
{IterateTemplate(template);}

local function AttachItemFunc(scope, weaponName, overRideChar = null)
{
	scope.botWep <- weaponName;
	if (overRideChar != null) scope.botChar <- overRideChar;
	scope.GiveBotWep <- function()
	{
		local char = null;
		if ("botChar" in this)
			char = this.botChar;
		else
			char = NetProps.GetPropInt(self, "m_character");
		if (char in ::infoSpawnedSurvsList)
		{
			local infoBot = GetPlayerFromUserID(infoSpawnedSurvsList[char]);
			if (infoBot != null)
			{
				infoBot.GiveItem(this.botWep);
			}
		}
	}
}

switch (g_MapName)
{
case "c6m1_riverbank":
	// stupid Valve employee left millions of empty survivor positions all over the place
	for (local i = null; i = Entities.FindByClassname(i, "info_survivor_position");)
	{
		if ( NetProps.GetPropInt(i, "m_order") == 1 && !(0 in i.GetName()) )
		{
			i.Kill();
		}
	}
	local relay = Entities.FindByName(null, "relay_intro_start");
	if (relay != null)
	{
		local worldSpawn = GetWorldSpawn();
		worldSpawn[1].VSSMMF1 <- function()
		{
			local survList = survManager.RetrieveSurvList(false);
			foreach (key, client in survList)
			{
				if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
				
				local position = NetProps.GetPropEntity(client, "m_positionEntity");
				if (position == null) continue;
				
				switch (position.GetName())
				{
				case "survivorPos_intro_01":
				case "survivorPos_intro_02":
				case "survivorPos_intro_03":
				case "survivorPos_intro_04":
					break;
				default:
					local introPosName = "survivorPos_intro_01";
					switch (NetProps.GetPropInt(client, "m_survivorCharacter"))
					{
					case 0:
					case 4:
						introPosName = "survivorPos_intro_04";
						break;
					case 1:
					case 5:
						introPosName = "survivorPos_intro_02";
						break;
					case 3:
					case 6:
						//introPosName = "survivorPos_intro_01";
						break;
					case 2:
					case 7:
						introPosName = "survivorPos_intro_03";
						break;
					}
					
					local introPos = Entities.FindByName(null, introPosName);
					if (introPos != null)
					{
						DoEntFire("!self", "ReleaseFromSurvivorPosition", "", 0.0, null, client);
						
						local introPosOrigin = introPos.GetOrigin();
						DoEntFire("!self", "RunScriptCode", "self.SetOrigin(Vector("+introPosOrigin.x+","+introPosOrigin.y+","+introPosOrigin.z+"))", 0.0, null, client);
						DoEntFire("!self", "CallScriptFunction", "IFOverride1", 0.1, null, client);
						DoEntFire("!self", "TeleportToSurvivorPosition", introPosName, 0.1, null, client);
						DoEntFire("!self", "CallScriptFunction", "IFOverride0", 0.1, null, client);
					}
					break;
				}
			}
		}
		EntityOutputs.AddOutput(relay, "OnTrigger", "worldspawn", "CallScriptFunction", "VSSMMF1", 0.01, -1);
	}
	break;
	// Silent Hill: Otherside of Life (original 4.7)
	// https://www.gamemaps.com/details/7592
case "sa_01":
	for (local i = null; i = Entities.FindByClassnameWithin(i, "info_survivor_position", Vector(2376, 14592, 1500), 50.0);)
	{
		i.Kill();
	}
	break;
case "sa_07":
	for (local i = null; i = Entities.FindByClassnameWithin(i, "info_survivor_position", Vector(11210, -15936.1, -144), 125.0);)
	{
		i.Kill();
	}
	break;
	// 4 Sided Coin
	// https://steamcommunity.com/sharedfiles/filedetails/?id=3032383972
case "4sc_seperate":
	local trigStats = [];
	for (local i = null; i = Entities.FindByClassnameWithin(i, "trigger_teleport", Vector(12832, 13824, -1248), 10.0);)
	{
		if (!(0 in trigStats))
		{
			trigStats.append(i.GetOrigin());
			trigStats.append(i.GetModelName());
		}
		
		i.Kill();
	}
	
	if (0 in trigStats)
	{
		local replaceTrig = SpawnEntityFromTable("trigger_multiple", {
			origin = trigStats[0].ToKVString(),
			model = trigStats[1],
			spawnflags = (1 << 0),
			filtername = "survivorfilter",
			wait = 1,
		});
		if (replaceTrig.ValidateScriptScope())
		{
			local trigScope = replaceTrig.GetScriptScope();
			trigScope.TestMySurvivor <- function()
			{
				if (activator == null) return;
				
				if (!("TelePositions" in this))
				{
					this.TelePositions <- [];
					for (local i = 1; i < 4; i++)
					{
						local posEnt = Entities.FindByName(null, "teledest"+i);
						if (posEnt != null)
							this.TelePositions.append(posEnt);
					}
					if (this.TelePositions.len() < 3) this.TelePositions = null;
				}
				if (this.TelePositions == null) return;
				
				// bill		= teledest1
				// zoey		= teledest2
				// louis	= teledest3
				// francis	= teledest4
				local survChar = NetProps.GetPropInt(activator, "m_survivorCharacter");
				switch (survChar)
				{
				case 0: case 1: case 2: case 3: break;
				case 4:		survChar = 0;		break;
				case 5:		survChar = 1;		break;
				case 6:		survChar = 3;		break;
				case 7:		survChar = 2;		break;
				default:	survChar = null;	break;
				}
				if (survChar != null && survChar in this.TelePositions)
				{
					local posEnt = this.TelePositions[survChar];
					if (posEnt != null && posEnt.IsValid())
					{
						activator.SetOrigin(posEnt.GetOrigin());
						activator.SnapEyeAngles(posEnt.GetAngles());
					}
				}
				else if (0 in this.TelePositions)
				{
					local posEnt = this.TelePositions[RandomInt(0, this.TelePositions.len()-1)];
					if (posEnt != null && posEnt.IsValid())
					{
						activator.SetOrigin(posEnt.GetOrigin());
						activator.SnapEyeAngles(posEnt.GetAngles());
					}
				}
			}
			replaceTrig.ConnectOutput("OnStartTouch", "TestMySurvivor");
		}
		else
			replaceTrig.Kill();
	}
	break;
	// Deadenator
	// https://steamcommunity.com/sharedfiles/filedetails/?id=672231603
/*case "ddntr1_01urban":
	local worldSpawn = GetWorldSpawn();
	local relay = Entities.FindByName(null, "relay_skydive2");
	if (relay != null)
	{
		worldSpawn[1].VSSMMF1 <- function()
		{
			local survPosArr = [];
			local survAngArr = [];
			for (local survPos; survPos = Entities.FindByName( survPos, "skydive_teleport" );)
			{
				survPosArr.append(survPos.GetOrigin());
				local survPosAng = survPos.GetAngles(); survPosAng.z = 0;
				survAngArr.append(survPosAng);
			}
			if (survPosArr.len() == 0) return;
			
			local i = -1;
			
			local survList = survManager.RetrieveSurvList(false);
			foreach (key, client in survList)
			{
				if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
				
				local position = NetProps.GetPropEntity(client, "m_positionEntity");
				if (position != null) continue;
				
				i = i + 1;
				if (i >= survPosArr.len()) i = 0;
				
				local randomX = RandomInt(-20,20);
				local randomY = RandomInt(-20,20);
				local newVec = Vector(
					survPosArr[i].x + randomX,
					survPosArr[i].y + randomY,
					survPosArr[i].z
				);
			//	local newPos = SpawnEntityFromTable("info_survivor_position", {
			//		origin = newVec.ToKVString(),
			//		angles = survAngArr[i],
			//		targetname = "skydive_teleport",
			//		order = 1,
			//	});
			//	
			//	DoEntFire("!self", "CallScriptFunction", "IFOverride1", 0, null, client);
			//	DoEntFire("!self", "TeleportToSurvivorPosition", "!activator", 0, newPos, client);
			//	DoEntFire("!self", "CallScriptFunction", "IFOverride0", 0, null, client);
				client.SetOrigin(newVec);
				client.SnapEyeAngles(survAngArr[i]);
			}
		}
		EntityOutputs.AddOutput(relay, "OnTrigger", "worldspawn", "CallScriptFunction", "VSSMMF1", 0.2, -1);
	}
	
	relay = Entities.FindByName(null, "relay_intro_start");
	if (relay != null)
	{
		worldSpawn[1].VSSMMF2 <- function()
		{
			local survPosArr = [];
			local survAngArr = [];
			for (local survPos; survPos = Entities.FindByName( survPos, "surv_set*" );)
			{
				survPosArr.append(survPos.GetOrigin());
				local survPosAng = survPos.GetAngles(); survPosAng.z = 0;
				survAngArr.append(survPosAng);
			}
			if (survPosArr.len() == 0) return;
			
			local i = -1;
			
			local survList = survManager.RetrieveSurvList(false);
			foreach (key, client in survList)
			{
				if (NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
				
				local position = NetProps.GetPropEntity(client, "m_positionEntity");
				if (position != null) continue;
				
				i = i + 1;
				if (i >= survPosArr.len()) i = 0;
				client.SetOrigin(survPosArr[i]);
				client.SnapEyeAngles(survAngArr[i]);
			}
		}
		EntityOutputs.AddOutput(relay, "OnTrigger", "worldspawn", "CallScriptFunction", "VSSMMF2", 3.0, -1);
	}
	break;*/
	// Glubtastic 4
	// https://steamcommunity.com/sharedfiles/filedetails/?id=2459037122
case "glubtastic4_4":
	local hateCommand = Entities.FindByName(null, "botkick");
	if (hateCommand != null) hateCommand.Kill();
	EntFire("!francis", "Kill");
	EntFire("!zoey", "Kill");
	EntFire("!louis", "Kill");
	EntFire("!bill", "Kill");
	
	local francisBot = Entities.FindByName(null, "francis_bot");
	if (francisBot != null && francisBot.ValidateScriptScope())
	{
		EntityOutputs.RemoveOutput(francisBot, "OnUser1", "!francis", "RunScriptFile", "giveshotgun");
		local spawnerScope = francisBot.GetScriptScope();
		AttachItemFunc(spawnerScope, "autoshotgun");
		EntityOutputs.AddOutput(francisBot, "OnUser1", "!self", "CallScriptFunction", "GiveBotWep", 0.2, 1);
	}
	local zoeyBot = Entities.FindByName(null, "zoey_bot_s");
	if (zoeyBot != null && zoeyBot.ValidateScriptScope())
	{
		EntityOutputs.RemoveOutput(zoeyBot, "OnUser1", "!zoey", "RunScriptFile", "givepistol");
		local spawnerScope = zoeyBot.GetScriptScope();
		AttachItemFunc(spawnerScope, "pistol", 5);
		EntityOutputs.AddOutput(zoeyBot, "OnUser1", "!self", "CallScriptFunction", "GiveBotWep", 0.3, 1);
	}
	local louisBot = Entities.FindByName(null, "louis_bot");
	if (louisBot != null && louisBot.ValidateScriptScope())
	{
		local spawnerScope = louisBot.GetScriptScope();
		AttachItemFunc(spawnerScope, "cola_bottles");
		
		for (local button; button = Entities.FindByClassname( button, "func_button" );)
		{
			if (NetProps.GetPropString(button, "m_sGlowEntity") != "pillz_cap") continue;
			
			EntityOutputs.RemoveOutput(button, "OnPressed", "!louis", "RunScriptFile", "givebat");
			EntityOutputs.AddOutput(button, "OnPressed", "louis_bot", "CallScriptFunction", "GiveBotWep", 1.6, 1);
			break;
		}
	}
	
	local telePortal = Entities.FindByName(null, "bots_forward");
	local teleDest = Entities.FindByName(null, "bots");
	if (telePortal != null && teleDest != null)
	{
		local replaceTrig = SpawnEntityFromTable("trigger_multiple", {
			targetname = "bots_forward",
			origin = telePortal.GetOrigin().ToKVString(),
			model = telePortal.GetModelName(),
			StartDisabled = NetProps.GetPropInt(telePortal, "m_bDisabled"),
			spawnflags = NetProps.GetPropInt(telePortal, "m_spawnflags"),
			filtername = NetProps.GetPropString(telePortal, "m_iFilterName"),
			wait = 1,
		});
		if (replaceTrig.ValidateScriptScope())
		{
			local trigScope = replaceTrig.GetScriptScope();
			trigScope.TeleDest <- teleDest;
			trigScope.TeleBot <- function()
			{
				if (activator == null || !this.TeleDest.IsValid() || 
				NetProps.GetPropInt(activator, "m_iTeamNum") != 4) return;
				
				if (activator.IsIncapacitated()) activator.ReviveFromIncap();
				
				activator.SetOrigin(this.TeleDest.GetOrigin());
				activator.SnapEyeAngles(this.TeleDest.GetAngles());
			}
			EntityOutputs.AddOutput(replaceTrig, "OnStartTouch", "!self", "CallScriptFunction", "TeleBot", 0, -1);
			telePortal.Kill();
		}
		else
			replaceTrig.Kill();
	}
	break;
case "glubtastic4_5":
	local teleHacker = Entities.FindByName(null, "endtele");
	if (teleHacker != null && teleHacker.ValidateScriptScope())
	{
		EntityOutputs.RemoveOutput(teleHacker, "OnTrigger", "!coach", "AddOutput", "origin -8832 8448 120");
		EntityOutputs.RemoveOutput(teleHacker, "OnTrigger", "!ellis", "AddOutput", "origin -8832 8448 120");
		EntityOutputs.RemoveOutput(teleHacker, "OnTrigger", "!rochelle", "AddOutput", "origin -8832 8448 120");
		EntityOutputs.RemoveOutput(teleHacker, "OnTrigger", "!nick", "AddOutput", "origin -8832 8448 120");
		local relayScope = teleHacker.GetScriptScope();
		relayScope.TeleSurvs <- function()
		{
			local survList = survManager.RetrieveSurvList(false);
			foreach (key, client in survList)
			{
				if (client.IsDying() || client.IsDead() || 
				NetProps.GetPropInt(client, "m_iTeamNum") != 2) continue;
				if (client.IsIncapacitated())
					client.ReviveFromIncap();
				
				client.SetOrigin(Vector(-8832, 8448, 120));
			}
		}
		EntityOutputs.AddOutput(teleHacker, "OnTrigger", "!self", "CallScriptFunction", "TeleSurvs", 0.5, -1);
	}
	break;
case "glubtastic4_7":
	local hateCommand = Entities.FindByName(null, "botkick");
	if (hateCommand != null) hateCommand.Kill();
	EntFire("!francis", "Kill");
	EntFire("!louis", "Kill");
	
	local louisMustDie = Entities.FindByName(null, "toobcount2");
	if (louisMustDie != null)
		EntityOutputs.AddOutput(louisMustDie, "OnHitMax", "!louis", "Kill", "", 5, 1);
	
	local outtaSightOuttaMind = Entities.FindByName(null, "francis_cam2");
	if (outtaSightOuttaMind != null)
		EntityOutputs.AddOutput(outtaSightOuttaMind, "OnUser1", "!francis", "Kill", "", 1, 1);
	
	/*local giverTrigger = Entities.FindByClassnameNearest("trigger_once", Vector(-860, -100, -960), 20);
	if (giverTrigger != null)
	{*/
		// seems to be too late on restarts to stop this
		// oh well
		//EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "!francis", "RunScriptFile", "giveshotgun");
		//EntityOutputs.RemoveOutput(giverTrigger, "OnStartTouch", "!louis", "RunScriptFile", "giveshotgun");
		
		for (local spawner; spawner = Entities.FindByClassname( spawner, "info_l4d1_survivor_spawn" );)
		{
			local name = NetProps.GetPropString(spawner, "m_iName").tolower();
			if (name != "francis" && name != "louis" && !spawner.ValidateScriptScope()) continue;
			
			local spawnerScope = spawner.GetScriptScope();
			AttachItemFunc(spawnerScope, "autoshotgun");
			//EntityOutputs.AddOutput(spawner, "OnUser2", "!self", "CallScriptFunction", "GiveBotWep", 0, 1);
			DoEntFire("!self", "CallScriptFunction", "GiveBotWep", 0.2, null, spawner);
		}
		
		//EntityOutputs.AddOutput(giverTrigger, "OnUser1", "francis", "FireUser2", "", 0.2, 1);
		//EntityOutputs.AddOutput(giverTrigger, "OnUser1", "louis", "FireUser2", "", 0.2, 1);
	//}
	break;
}