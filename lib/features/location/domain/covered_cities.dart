import 'selected_place.dart';

const coveredCities = [
  SelectedPlace(
    label: 'Gombe',
    latitude: -4.310,
    longitude: 15.298,
    fromGps: false,
  ),
  SelectedPlace(
    label: 'Limete',
    latitude: -4.362,
    longitude: 15.348,
    fromGps: false,
  ),
  SelectedPlace(
    label: 'Masina',
    latitude: -4.383,
    longitude: 15.391,
    fromGps: false,
  ),
  SelectedPlace(
    label: 'N\'Djili',
    latitude: -4.386,
    longitude: 15.444,
    fromGps: false,
  ),
];

List<SelectedPlace> filterCities(String query) {
  final normalized = query.trim().toLowerCase().replaceAll('\'', '');
  if (normalized.isEmpty) {
    return coveredCities;
  }

  return coveredCities.where((city) {
    final label = city.label.toLowerCase().replaceAll('\'', '');
    return label.contains(normalized);
  }).toList();
}
