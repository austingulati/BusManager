class Vehicle {
	_vehicleId = null;
	_runState = null;
	_profit = null;
	_src = null;
	_dest = null;
	_markedForDeletion = null;

	constructor(vehicleId) {
		_vehicleId = vehicleId;
		_runState = false;
		_profit = Metric(this, "profit", -500, 7500);
		_markedForDeletion = false;
	}

	function PickUp(station) {
		_src = station;
		AIOrder.AppendOrder(_vehicleId,
			station.Tile(),
			AIOrder.OF_NON_STOP_INTERMEDIATE);
	}

	function Transfer(station) {
		_dest = station;
		AIOrder.AppendOrder(_vehicleId,
			station.Tile(),
			AIOrder.OF_NON_STOP_INTERMEDIATE
			| AIOrder.OF_TRANSFER
			| AIOrder.OF_NO_LOAD);	}

	function Start() {
		if (!_runState) {
			AIVehicle.StartStopVehicle(_vehicleId);
			_runState = true;
		}
	}

	function Maintain() {}

	function CollectMetrics() {
		local lastYear = AIVehicle.GetProfitLastYear(_vehicleId);
		if (lastYear == null) {
			lastYear = 0;
		}
		_profit.Record(AIVehicle.GetProfitThisYear(_vehicleId) * 2,
			lastYear * 2);
	}

	function IsProfitable() {
		return IsProfitableAt(0);
	}

	function IsProfitableAt(perYear) {
		return _profit.SumOverLast(90) >= perYear / 4
		  || _profit.SumOverLast(180) >= perYear / 2
		  || _profit.SumOverLast(360) >= perYear;
	}

	function IsUnprofitableLongTerm() {
		return !IsProfitable();
	}

	function EngineId() {
		return AIVehicle.GetEngineType(_vehicleId);
	}

	function MarkForDeletion() {
		if (!_markedForDeletion) {
			AIVehicle.SendVehicleToDepot(_vehicleId);
			_markedForDeletion = true;
		}
	}

	function InDepot() {
		return AIVehicle.IsStoppedInDepot(_vehicleId);
	}

	function Sell() {
		AIVehicle.SellVehicle(_vehicleId);
	}

	function Log(msg) {
		_src.Log("vehicle " + _vehicleId + ": " + msg)
	}
}