if (!IsModelPrecached("models/survivors/survivor_namvet.mdl")) PrecacheModel("models/survivors/survivor_namvet.mdl");
if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl")) PrecacheModel("models/survivors/survivor_teenangst.mdl");
if (!IsModelPrecached("models/survivors/survivor_biker.mdl")) PrecacheModel("models/survivors/survivor_biker.mdl");
if (!IsModelPrecached("models/survivors/survivor_manager.mdl")) PrecacheModel("models/survivors/survivor_manager.mdl");
if (!IsModelPrecached("models/survivors/survivor_gambler.mdl")) PrecacheModel("models/survivors/survivor_gambler.mdl");
if (!IsModelPrecached("models/survivors/survivor_producer.mdl")) PrecacheModel("models/survivors/survivor_producer.mdl");
if (!IsModelPrecached("models/survivors/survivor_coach.mdl")) PrecacheModel("models/survivors/survivor_coach.mdl");
if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl")) PrecacheModel("models/survivors/survivor_mechanic.mdl");

SpawnEntityGroupFromTable({
	[0] = {
		logic_auto = {
			spawnflags = (1 << 0),
			globalstate = "mapTransitioned",
			connections =
			{
				OnMapSpawn =
				{
					cmd1 = "worldspawnRunScriptCode::VSSMMapTrans <- null01"
				}
			}
		}
	}
});