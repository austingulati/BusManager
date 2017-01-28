class Date {
	_date = null;

	constructor(date) {
		_date = date;
	}

	function Year() {
		return AIDate.GetYear(_date);
	}

	function Month() {
		return AIDate.GetMonth(_date);
	}

	function Day() {
		return AIDate.GetDayOfMonth(_date);
	}

	function YearsAfter(other) {
		return Year() - other.Year();
	}

	function DaysAfter(other) {
		return _date - other._date;
	}
}

class Metric {
	_entity = null;
	_name = null;
	_entries = null;
	_totalDays = null;
	_last = null;
	_lastValue = null;
	_downThreshold = null;
	_upThreshold = null;

	constructor(entity, name, downThreshold, upThreshold) {
		_entity = entity;
		_name = name;
		_downThreshold = downThreshold;
		_upThreshold = upThreshold;
		_entries = [];
		_entries.insert(0, MetricEntry(0, 0));
		_totalDays = 0;
		_last = Date(AIDate.GetCurrentDate());
		_lastValue = 0;
	}

	function TotalValue() {
		return _lastValue;
	}

	function Record(thisYear, lastYear) {
		local today = Date(AIDate.GetCurrentDate());
		if (_last == today) {
			return;
		}

		if (today.YearsAfter(_last) == 0 || lastYear == 0) {
			local days = today.DaysAfter(_last);
			local value = thisYear - _lastValue;
			_Record(days, value);
		} else if (today.YearsAfter(_last)  == 1) {
			local days = today.DaysAfter(_last);
			local value = lastYear - _lastValue + thisYear;
			_Record(days, value);
		} else {
			Log("ERROR! missing data!")
		}
		_last = today;
		_lastValue = thisYear;
	}

	function _Record(days, value) {
		local prefix = "";
		if (value > 0) {
			prefix = "+";
		}
		// Log(prefix + value + " in last " + days);
		_totalDays += days;
		_entries.insert(0, MetricEntry(days, value));
	}

	function Summarize() {
		if (SumOverLast(90) > _upThreshold || SumOverLast(90) < _downThreshold
			|| SumOverLast(180) > _upThreshold || SumOverLast(180) > _downThreshold
			|| SumOverLast(360) > _upThreshold || SumOverLast(360) > _downThreshold) {
			Log(" moved: " + SumOverLast(90) + " quarter " + SumOverLast(180) +
				"half " + SumOverLast(360) + "year");
		}
	}

	function SumOverLast(totalDays) {
		if (totalDays > _totalDays) {
			return 0;
		}

		local i = 0;
		local sum = 0;
		local daysLeft = totalDays;
		while (daysLeft > 0) {
			local days = _entries[i].Days();

			if (days <= daysLeft) {
				sum += _entries[i].Value();
				daysLeft -= days;
			} else {
				local fraction = daysLeft / days;
				sum += fraction * _entries[i].Value();
				daysLeft = 0;
			}
			i++;
		}

		return sum;
	}

	function Log(msg) {
		_entity.Log(_name + ": " + msg);
	}
}

class MetricEntry {
	_days = null;
	_value = null;

	constructor(days, value) {
		_days = days;
		_value = value;
	}

	function Days() {
		return _days;
	}

	function Value() {
		return _value;
	}
}

class Route {
	_vehicles = [];
	_source = null;
	_destination = null;
	_depot = null;
	_initialized = false;

	constructor() {}

	function InitializeRoute(town, source, destination, depot) {
		_source = source;
		_destination = destination;
		_depot = depot;
		_initialized = true;
		_vehicles = [];
	}

	function MaintainRoute() {
		if (_vehicles.len() == 0) {
			Log("creating first vehicle");
			NewVehicle();
		}

		foreach (vehicleId, vehicle in _vehicles) {
			vehicle.Maintain();
			vehicle.CollectMetrics();
			
			if (vehicle.IsUnprofitableLongTerm()) {
				vehicle.MarkForDeletion();
			}

			if (vehicle.InDepot()) {
				vehicle.Sell();
				_vehicles.remove(vehicleId);
			}
		}
	}

	function AllProfitableAt(perYear) {
		return VehiclesProfitableAt(perYear) == _vehicles.len();
	}

	function VehiclesProfitableAt(perYear) {
		local profitable = 0;
		foreach (vehicleId, vehicle in _vehicles) {
			if (vehicle.IsProfitableAt(perYear)) {
				profitable++;
			}
		}
		return profitable;
	}

	function NextDepot() {}

	function EngineId() {}

	function NewVehicle() {
		if (engineId != null) {
			local vehicle = depot.CreateVehicle(engineId);
			if (vehicle == null) {
				Log("cannot create, probably too poor");
				return false;
			}
			_vehicles.append(vehicle);

			ApplyOrders(vehicle);
			vehicle.Start();
			return true;
		}
	}
}