class Town {
	_townId = null;
	_busStation = null;
	_stations = null;
	_depotTile = null;
	_engineId = null;
	_cargoId = null;

	constructor(townId) {
		_townId = townId;
		_stations = {};
		Log("new town");
	}

	function Name() {
		return AITown.GetName(_townId);
	}

	function RegisterStation(stationId) {
		_stations[stationId] <- Station(this, stationId);
		return _stations[stationId];
	}

	function RegisterDepot(depotTile) {
		_depotTile = Depot(this, depotTile);
		return _depotTile;
	}

	function Maintain() {
		Log("maintenance");
		foreach (stationId, station in _stations) {
			station.Maintain();
		}
	}

	function BusStation() {
		if (_busStation == null) {
			foreach (stationId, station in _stations) {
				if (station.Name().find("Bus Station") != null) {
					_busStation = station;
					_busStation.PromoteToBusStation();
					Log("found bus station");
				}
			}
		}

		return _busStation;
	}

	function NextDepot() {
		return _depotTile;
	}


	function Tile() {
		return AITown.GetLocation(_townId);
	}

	function DistanceFrom(otherTown) {
		return AITown.GetDistanceManhattanToTile(_townId, otherTown.Tile());
	}

	function Log(msg) {
		AILog.Info("====> [" + _stations.len() + "] " + Name() + ": " + msg);
	}
}