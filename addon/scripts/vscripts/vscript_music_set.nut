local survSet = Director.GetSurvivorSet();

if (!("musicControl" in this))
{

musicControl <-
{
	function EnsureMusicEnt()
	{
		if (!("Entity" in this) || this.Entity == null || !this.Entity.IsValid())
		{
			this.Entity <- SpawnEntityFromTable("ambient_music", {
				classname = "script_music",
			});
			if (this.Entity == null) return false;
			if (!this.Entity.ValidateScriptScope())
			{
				this.Entity.Kill();
				return false;
			}
			local entScope = this.Entity.GetScriptScope();
			
			entScope.OriginalLifeStates <- [];
			
			entScope.MessageArray <- [];
			entScope.MessageBefore <- function()
			{
				if (!(0 in MessageArray)) return;
				self.__KeyValueFromString("message", this.MessageArray[0]);
				if (1 in MessageArray)
				{
					local plyList = [];
					for (local client; client = Entities.FindByClassname( client, "player" );)
					{
						plyList.append(client);
					}
					
					foreach (key, client in plyList)
					{
						local shouldSkip = null;
						switch (typeof this.MessageArray[1])
						{
						case "array":
							if (this.MessageArray[1].find(client) != null)
								shouldSkip = true;
							break;
						case "instance":
							if (client == this.MessageArray[1])
								shouldSkip = true;
							break;
						}
						
						local lifeState = NetProps.GetPropInt(client, "m_lifeState");
						switch (shouldSkip)
						{
						case true:
							if (lifeState != 0)
							{
								local teamArray = [client, lifeState];
								this.OriginalLifeStates.append(teamArray);
								NetProps.SetPropInt(client, "m_lifeState", 0);
							}
							break;
						default:
							if (lifeState == 0)
							{
								local teamArray = [client, lifeState];
								this.OriginalLifeStates.append(teamArray);
								NetProps.SetPropInt(client, "m_lifeState", 1);
							}
							break;
						}
						
						/*if (shouldSkip) continue;
						
						local lifeState = NetProps.GetPropInt(client, "m_lifeState");
						if (lifeState == 0)
						{
							local teamArray = [client, lifeState];
							this.OriginalLifeStates.append(teamArray);
							NetProps.SetPropInt(client, "m_lifeState", 1);
						}*/
					}
				}
				if (2 in MessageArray && this.MessageArray[2] != null)
					self.SetOrigin(this.MessageArray[2]);
			}
			entScope.MessageAfter <- function()
			{
				if (!(0 in MessageArray)) return;
				self.__KeyValueFromString("message", this.MessageArray[0]);
				
				foreach (key, teamArray in this.OriginalLifeStates)
				{
					NetProps.SetPropInt(teamArray[0], "m_lifeState", teamArray[1]);
				}
				this.OriginalLifeStates.clear();
				
				if (2 in MessageArray)
					this.MessageArray.remove(2);
				if (1 in MessageArray)
					this.MessageArray.remove(1);
				this.MessageArray.remove(0);
			}
		}
		return true;
	}
	
	function ToggleMusic(message, target = null, origin = null, boolean = true)
	{
		if (!EnsureMusicEnt()) return;
		switch (typeof target)
		{
		case "instance":
		case "array":
			break;
		default:
			target = null;
			break;
		}
		
		local entScope = this.Entity.GetScriptScope();
		entScope.MessageArray.append(message);
		entScope.MessageArray.append(target);
		entScope.MessageArray.append(origin);
		DoEntFire("!self", "CallScriptFunction", "MessageBefore", 0, null, this.Entity);
		DoEntFire("!self", (boolean) ? "PlaySound" : "StopSound", "", 0, null, this.Entity);
		DoEntFire("!self", "CallScriptFunction", "MessageAfter", 0, null, this.Entity);
	}
}

}

if (!("musicSet" in this) || ("hasRoundEnded" in musicSet))
{

musicSet <-
{
	bleedingOutArr = [],
	function DoReplace(oldPlyId, newPlyId)
	{
		local arrFind = bleedingOutArr.find(oldPlyId);
		if (arrFind != null)
			bleedingOutArr[arrFind] = newPlyId;
	}
	function OnGameEvent_player_bot_replace(params)
	{
		if ("Disabled" in this) return;
		if (!("player" in params) || !("bot" in params)) return;
		DoReplace(params["player"], params["bot"]);
	}
	function OnGameEvent_bot_player_replace(params)
	{
		if ("Disabled" in this) return;
		if (!("player" in params) || !("bot" in params)) return;
		DoReplace(params["bot"], params["player"]);
	}
	
	function GetSurvList()
	{
		local survList = null;
		if ("survManager" in getroottable())
			survList = ::survManager.RetrieveSurvList(false);
		else
		{
			survList = [];
			for (local client; client = Entities.FindByClassname( client, "player" );)
			{
				if (!client.IsSurvivor()) continue;
				survList.append(client);
			}
		}
		return survList;
	}
	
	// Both ScenarioLose events can't be stopped with ambient_music sadly
	/*function OnGameEvent_mission_lost( params )
	{
		if ("Disabled" in this) return;
		local survList = GetSurvList();
		if (survList == null) return;
		
		for (local i = 0; i < survList.len(); i++)
		{
			local char = NetProps.GetPropInt(survList[i], "m_survivorCharacter");
			switch (char)
			{
			case 4: case 5: case 6: case 7:
				break;
			default:
				survList.remove(i);
				i--;
				break;
			}
		}
		
		switch (survSet)
		{
		case 1:
			//this.musicControl.ToggleMusic("Event.ScenarioLose_L4D1", survList, null, false);
			this.musicControl.ToggleMusic("Event.ScenarioLose", survList);
			break;
		default:
			//this.musicControl.ToggleMusic("Event.ScenarioLose", survList, null, false);
			this.musicControl.ToggleMusic("Event.ScenarioLose_L4D1", survList);
			break;
		}
	}*/
	
	function OnGameEvent_player_spawn( params )
	{
		if ("Disabled" in this) return;
		if ( !("userid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsSurvivor() ) return;
		
		local char = NetProps.GetPropInt(client, "m_survivorCharacter");
		switch (char)
		{
		case 4: case 5: case 6: case 7:
			switch (survSet)
			{
			case 1:
				this.musicControl.ToggleMusic("Event.SurvivorDeath", client, null, false);
				break;
			default:
				this.musicControl.ToggleMusic("Event.SurvivorDeath_L4D1", client, null, false);
				break;
			}
			local arrFind = this.bleedingOutArr.find(params["userid"]);
			if (arrFind != null)
				this.bleedingOutArr.remove(arrFind);
			break;
		}
	}
	
	function OnGameEvent_player_death( params )
	{
		if ("Disabled" in this) return;
		if ( !("userid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsSurvivor() ) return;
		
		local char = NetProps.GetPropInt(client, "m_survivorCharacter");
		switch (char)
		{
		case 4: case 5: case 6: case 7:
			switch (survSet)
			{
			case 1:
				this.musicControl.ToggleMusic("Event.SurvivorDeath", client, null);
				break;
			default:
				this.musicControl.ToggleMusic("Event.SurvivorDeath_L4D1", client, null);
				break;
			}
			
			local survList = GetSurvList();
			if (survList == null) break;
			local loopBackKey = survList.find(client);
			if (loopBackKey != null)
				survList.remove(loopBackKey);
			
			local clOrigin = client.GetOrigin();
			switch (survSet)
			{
			case 1:
				this.musicControl.ToggleMusic("Event.SurvivorDeathHit_L4D1", survList, null, false);
				this.musicControl.ToggleMusic("Event.SurvivorDeathHit", survList, clOrigin);
				break;
			default:
				this.musicControl.ToggleMusic("Event.SurvivorDeathHit", survList, null, false);
				this.musicControl.ToggleMusic("Event.SurvivorDeathHit_L4D1", survList, clOrigin);
				break;
			}
			break;
		}
	}
	
	function OnGameEvent_player_incapacitated( params )
	{
		if ("Disabled" in this) return;
		if ( !("userid" in params) ) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsSurvivor() ) return;
		
		local char = NetProps.GetPropInt(client, "m_survivorCharacter");
		switch (char)
		{
		case 4: case 5: case 6: case 7:
			switch (survSet)
			{
			case 1:
				this.musicControl.ToggleMusic("Event.Down", client, null);
				break;
			default:
				this.musicControl.ToggleMusic("Event.Down_L4D1", client, null);
				break;
			}
			
			local survList = GetSurvList();
			if (survList == null) break;
			local loopBackKey = survList.find(client);
			if (loopBackKey != null)
				survList.remove(loopBackKey);
			
			local clOrigin = client.GetOrigin();
			switch (survSet)
			{
			case 1:
				this.musicControl.ToggleMusic("Event.DownHit_L4D1", survList, null, false);
				this.musicControl.ToggleMusic("Event.DownHit", survList, clOrigin);
				break;
			default:
				this.musicControl.ToggleMusic("Event.DownHit", survList, null, false);
				this.musicControl.ToggleMusic("Event.DownHit_L4D1", survList, clOrigin);
				break;
			}
			/*foreach (key, loopClient in survList)
			{
				if (loopClient == client) continue;
				switch (survSet)
				{
				case 1:
					this.musicControl.ToggleMusic("Event.DownHit_L4D1", loopClient, null, false);
					this.musicControl.ToggleMusic("Event.DownHit", loopClient, clOrigin);
					break;
				default:
					this.musicControl.ToggleMusic("Event.DownHit", loopClient, null, false);
					this.musicControl.ToggleMusic("Event.DownHit_L4D1", loopClient, clOrigin);
					break;
				}
				break;
			}*/
			break;
		}
	}
	
	function OnGameEvent_revive_success( params )
	{
		if ("Disabled" in this) return;
		if ( !("subject" in params) ) return;
		
		local client = GetPlayerFromUserID( params["subject"] );
		if ( client == null || !client.IsSurvivor() ) return;
		
		local char = NetProps.GetPropInt(client, "m_survivorCharacter")
		switch (char)
		{
		case 4:
		case 5:
		case 6:
		case 7:
			switch (survSet)
			{
			case 1:
				this.musicControl.ToggleMusic("Event.Down", client, null, false);
				this.musicControl.ToggleMusic("Event.BleedingOut", client, null, false);
				break;
			default:
				this.musicControl.ToggleMusic("Event.Down_L4D1", client, null, false);
				this.musicControl.ToggleMusic("Event.BleedingOut_L4D1", client, null, false);
				break;
			}
			local arrFind = this.bleedingOutArr.find(params["userid"]);
			if (arrFind != null)
				this.bleedingOutArr.remove(arrFind);
			break;
		}
	}
	
	function OnGameEvent_player_hurt_concise( params )
	{
		if ("Disabled" in this) return;
		if ( !("userid" in params) ) return;
		if (this.bleedingOutArr.find(params["userid"]) != null) return;
		
		local client = GetPlayerFromUserID( params["userid"] );
		if ( client == null || !client.IsSurvivor() || 
		client.IsDead() || client.IsDying() || 
		!client.IsIncapacitated() || client.IsHangingFromLedge() ) return;
		
		local health = client.GetHealth();
		//printl("health of "+client+": "+health)
		if (health < 30 && health > 0)
		{
			local char = NetProps.GetPropInt(client, "m_survivorCharacter")
			switch (char)
			{
			case 4:
			case 5:
			case 6:
			case 7:
				switch (survSet)
				{
				case 1:
					this.musicControl.ToggleMusic("Event.BleedingOut", client, null);
					break;
				default:
					this.musicControl.ToggleMusic("Event.BleedingOut_L4D1", client, null);
					break;
				}
				
				local survList = GetSurvList();
				if (survList == null) break;
				local loopBackKey = survList.find(client);
				if (loopBackKey != null)
					survList.remove(loopBackKey);
				
				local clOrigin = client.GetOrigin();
				switch (survSet)
				{
				case 1:
					this.musicControl.ToggleMusic("Event.BleedingOutHit_L4D1", survList, null, false);
					this.musicControl.ToggleMusic("Event.BleedingOutHit", survList, clOrigin);
					break;
				default:
					this.musicControl.ToggleMusic("Event.BleedingOutHit", survList, null, false);
					this.musicControl.ToggleMusic("Event.BleedingOutHit_L4D1", survList, clOrigin);
					break;
				}
				
				this.bleedingOutArr.append(params["userid"]);
				break;
			}
		}
	}
	
	function OnGameEvent_round_end( params )
	{
		this.hasRoundEnded <- null;
	}
}

}

__CollectEventCallbacks(musicSet, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);