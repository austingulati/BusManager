require("version.nut"); // get SELF_VERSION
require("common.nut");
require("vehicle.nut");
require("town.nut");
require("depot.nut");
require("station.nut");
require("town_route.nut");

class MainClass extends AIController 
{
	_loaded_data = null;
	_loaded_from_version = null;
	_init_done = null;

	_stations = null;
	_towns = null;
	_depots = null;
	_townRoutes = null;

	_mode = null;

	constructor()
	{
		this._init_done = false;
		this._loaded_data = null;
		this._loaded_from_version = null;
		this._stations = {};
		this._towns = {};
		this._depots = {};
		this._townRoutes = {};

		this._mode = AIExecMode();
	}
}

function MainClass::Start()
{
	AIController.Sleep(1);
	this.Init();
	AIController.Sleep(1);

	// Game has now started and if it is a single player game,
	// company 0 exist and is the human company.

	local last_loop_date = AIDate.GetCurrentDate();
	while (true) {
		local loop_start_tick = AIController.GetTick();
		AILog.Info("== TICK ==");

		this.HandleEvents();

		// Reached new year/month?
		// local current_date = AIDate.GetCurrentDate();
		// if (last_loop_date != null) {
		// 	local year = AIDate.GetYear(current_date);
		// 	local month = AIDate.GetMonth(current_date);
		// 	if (year != AIDate.GetYear(last_loop_date)) {
		// 		this.EndOfYear();
		// 	}
		// 	if (month != AIDate.GetMonth(last_loop_date)) {
		// 		this.EndOfMonth();
		// 	}
		// }
		// last_loop_date = current_date;

		local depotTileList = AIDepotList(AITile.TRANSPORT_ROAD);
		foreach (depotTile, value in depotTileList) {
			if (!_depots.rawin(depotTile)) {
				local townId = AITile.GetClosestTown(depotTile);

				if (!_towns.rawin(townId)) {
					_towns[townId] <- Town(townId);
				}

				_depots[depotTile] <-
					_towns[townId].RegisterDepot(depotTile);
			}
		}

		local stationList = AIStationList(AIStation.STATION_BUS_STOP);
		foreach (stationId, value in stationList) {
			if (!_stations.rawin(stationId)) {
				local townId =
					AIStation.GetNearestTown(stationId);

				if (!_towns.rawin(townId)) {
					_towns[townId] <- Town(townId);
				}

				_stations[stationId] <-
					_towns[townId].RegisterStation(stationId);
			}

		}

		foreach (townId, town in _towns) {
			town.Maintain();

			if (!_townRoutes.rawin(townId)) {
				_townRoutes[townId] <- {};
			}
		}

		foreach (srcTownId, srcTown in _towns) {
			foreach (destTownId, destTown in _towns) {
				if (srcTownId != destTownId) {
					if (!_townRoutes[srcTownId].rawin(destTownId)) {
						_townRoutes[srcTownId][destTownId] <- CrossTownBusRoute(srcTown,
							destTown);
					}
				}
			}
		}

		foreach (srcTownId, townRoutes in _townRoutes) {
			foreach (destTownId, townRoute in townRoutes) {
				townRoute.Maintain();
			}
		}

		// Loop with a frequency of five days
		local ticks_used = AIController.GetTick() - loop_start_tick;
		AIController.Sleep(max(1, 5 * 74 - ticks_used));
	}
}

/*
 * This method is called during the initialization of your Game Script.
 * As long as you never call Sleep() and the user got a new enough OpenTTD
 * version, all initialization happens while the world generation screen
 * is shown. This means that even in single player, company 0 doesn't yet
 * exist. The benefit of doing initialization in world gen is that commands
 * that alter the game world are much cheaper before the game starts.
 */
function MainClass::Init()
{
	if (this._loaded_data != null) {
		// Copy loaded data from this._loaded_data to this.*
		// or do whatever you like with the loaded data
	} else {
		// construct goals etc.
	}

	// Indicate that all data structures has been initialized/restored.
	this._init_done = true;
	this._loaded_data = null; // the loaded data has no more use now after that _init_done is true.
}

function MainClass::HandleEvents()
{
	if(AIEventController.IsEventWaiting()) {
		local ev = AIEventController.GetNextEvent();
		if (ev == null) return;

		local ev_type = ev.GetEventType();
		switch (ev_type) {
			case AIEvent.ET_VEHICLE_WAITING_IN_DEPOT : {
				local depotEvent = AIEventVehicleWaitingInDepot.Convert(ev);
				local vehicleId = depotEvent.GetVehicleID();
				AIVehicle.SellVehicle(vehicleId);

				break;
			}
		}
	}
}

function MainClass::Save()
{
	// In case (auto-)save happens before we have initialized all data,
	// save the raw _loaded_data if available or an empty table.
	if (!this._init_done) {
		return this._loaded_data != null ? this._loaded_data : {};
	}

	return { 
		some_data = null,
		//some_other_data = this._some_variable,
	};
}

function MainClass::Load(version, tbl)
{
	this._loaded_data = {}
   	foreach(key, val in tbl) {
		this._loaded_data.rawset(key, val);
	}

	this._loaded_from_version = version;
}
