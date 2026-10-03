class RainfallWindowCalculator {
  const RainfallWindowCalculator();

  List<double> rollingSixHourTotals(List<double> hourlyRainfall) {
    if (hourlyRainfall.length < 6) {
      return [];
    }

    final totals = <double>[];

    for (var i = 5; i < hourlyRainfall.length; i++) {
      var total = 0.0;

      for (var j = i - 5; j <= i; j++) {
        total += hourlyRainfall[j];
      }

      totals.add(total);
    }

    return totals;
  }
}
