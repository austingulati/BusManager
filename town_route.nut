class BusRoute extends Route {
	_engineId = null;
	_cargoId = null;

	function EngineId() {
		if (_engineId == null) {
			local engineList = AIEngineList(AIVehicle.VT_ROAD);

			local maxSpeed = 0;

			foreach (engineId, value in engineList) {
				local cargoId = AIEngine.GetCargoType(engineId);
				local cargoType = AICargo.GetCargoLabel(cargoId);
				local engineSpeed = AIEngine.GetMaxSpeed(engineId);

				if (cargoType == "PASS" &&
					engineSpeed > maxSpeed &&
					AIEngine.IsBuildable(engineId)) {
					_engineId = engineId;
					_cargoId = cargoId;
					maxSpeed = engineSpeed;
				}
			}
			Log("using engine " + AIEngine.GetName(_engineId));
		}

		return _engineId;
	}

	function CargoId() {
		if (_cargoId == null) {
			EngineId();
		}
		return _cargoId;
	}
}

class CrossTownBusRoute extends BusRoute {
	_srcTown = null;
	_destTown = null;
	_engineId = null;
	_cargoId = null;

	constructor(source, destination) {
		_srcTown = source;
		_destTown = destination;
		_vehicles = [];
	}

	function CanInitialize() {
		if (_srcTown.DistanceFrom(_destTown) > 500) {
			Log("too far");
			return false;
		}

		local depot = _srcTown.NextDepot();
		if (depot == null) {
			Log("no source depot");
			return false;
		}

		if (_srcTown.BusStation() == null) {
			Log("no source bus station");
			return false;
		}

		if (_destTown.BusStation() == null) {
			Log("no destination bus station");
			return false;
		}

		if (!_srcTown.BusStation().HasPassengersToGive()) {
			Log("not enough passengers");
			return false;
		}

		return true;
	}

	function CanExpand() {
		return AllProfitableAt(100)
		  && _source.HasPassengersToGive()
		  && _destination.HasPassengersToGive();
	}

	function SourceStation() {
		return _srcTown.BusStation();
	}

	function DestinationStation() {
		return _destination.BusStation();
	}

	function NextDepot() {
		return depot;
	}


	function CollectMetrics() {
		if (_initialized) {
			_source.CollectMetrics();
			_destination.CollectMetrics();
		}
	}

	function NextDepot() {
		return _srcTown.NextDepot();
	}

	function ApplyOrders(vehicle) {
		vehicle.PickUp(_source);
		vehicle.PickUp(_destination);
	}

	function Log(msg) {
		_srcTown.Log("to " + _destTown.Name() + ": " + msg);
	}
}