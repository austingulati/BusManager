class Station extends Route {
	_town = null;
	_stationId = null;
	_vehicles  = null;
	_isBusStation = null;
	_tile = null;
	_passengers = null;
	_passengersToGive = null;
	_baseName = null;

	constructor(town, stationId) {
		_town = town;
		_stationId = stationId;
		_vehicles = [];
		_isBusStation = false;
		_baseName = Name();
		Log("new station");
		_passengers = Metric(this, "passengers", 1, -1);
		_passengersToGive = 0;
	}

	function Name() {
		return AIStation.GetName(_stationId);
	}

	function Maintain() {
		CollectMetrics();

		if (_isBusStation) {
			_passengers.Summarize();
			return;
		}

		if (!_initialized) {
			local depot = _town.NextDepot();
			if (depot == null) {
				Log("no depot");
				return;
			}

			if (_town.BusStation() == null) {
				Log("no bus station");
				return;
			}

			if (_town.BusStation() == this) {
				return;
			}

			InitializeRoute(_town, this, _town.BusStation(), depot);
		}

		if (_initialized) {
			MaintainRoute();

			local currentCount = _vehicles.len();
			if (_passengers.SumOverLast(90) > 50
			  && AllProfitableAt(1)) {
				NewVehicle(); 
				if (_passengers.TotalValue() > 500
					&& AllProfitableAt(1000)) {
					NewVehicle();
				}
				if (_passengers.TotalValue() > 1000
					&& AllProfitableAt(2500)) {
					NewVehicle();
				}
			}
		}

		Summarize();
	}

	function ApplyOrders(vehicle) {
		vehicle.PickUp(_source);
		vehicle.Transfer(_destination);
	}

	function Passengers() {
		return _passengers;
	}

	function CollectMetrics() {
		_passengers.Record(AIStation.GetCargoWaiting(_stationId,
			_town.CargoId()), 0);

		if (_isBusStation) {
			_passengersToGive = 0;
			if (HasGainedPassengers(200)) {
				local totalPassengers = Passengers().TotalValue();

				if (totalPassengers > 100) {
					_passengersToGive++;
				}

				if (totalPassengers > 200) {
					_passengersToGive++;
				}

				if (totalPassengers > 500) {
					_passengersToGive++;
				}

				if (totalPassengers > 1000 && HasGainedPassengers(500)) {
					_passengersToGive++;
				}
			}

			Log("passengers to give: " + _passengersToGive);
		}
	}

	function HasPassengersToGive() {
		return _passengersToGive >= 1;
	}

	function TakePassengers() {
		_passengersToGive--;
	}

	function HasGainedPassengers(perYear) {
		return _passengers.SumOverLast(90) >= perYear / 4
		  || _passengers.SumOverLast(180) >= perYear / 2
		  || _passengers.SumOverLast(360) >= perYear;
	}

	function Summarize() {
		if (_initialized) {
			local name = _baseName;
			name += "V " + _vehicles.len() + " ";
			name += VehiclesProfitableAt(0) + ">0 ";
			name += VehiclesProfitableAt(0) + ">2k ";
			name += VehiclesProfitableAt(0) + ">5k | P ";
			name += _passengers.SumOverLast(90) + "Q ";
			name += _passengers.SumOverLast(180) + "H ";
			name += _passengers.SumOverLast(360) + "Y ";
		}
	}

	function PromoteToBusStation() {
		_isBusStation = true;
	}

	function Tile() {
		if (_tile == null) {
			local tileList = AITileList_StationType(_stationId,
				AIStation.STATION_BUS_STOP);

			_tile = tileList.Begin();
		}

		return _tile;
	}

	function Log(msg) {
		AILog.Info("[" + _vehicles.len() + "] " + _baseName + ": " + msg);
	}
}