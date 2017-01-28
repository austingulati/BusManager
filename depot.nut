class Depot {
	_town = null;
	_depotTile = null;

	constructor(town, depotTile) {
		_town = town;
		_depotTile = depotTile;
	}

	function CreateVehicle(engineId) {
		local vehicleId = null;
		try {
			vehicleId = AIVehicle.BuildVehicle(_depotTile,
				engineId);
		} catch (exception) {
			print(exception);
			return null;
		}
		if (!AIVehicle.IsValidVehicle(vehicleId)) {
			return null;
		}
		return Vehicle(vehicleId);
	}

	function CloneVehicle(vehicle) {
		local vehicleId = null;
		try {
			vehicleId = AIVehicle.CloneVehicle(_depotTile,
				vehicle.EngineId(), true);
		} catch (exception) {
			print(exception);
		}
		local vehicle = Vehicle(vehicleId);
	}

	function Tile() {
		return _depotTile;
	}

	function Log(msg) {
		AILog.Info(_town.Name() + " depot: " + msg);
	}
}