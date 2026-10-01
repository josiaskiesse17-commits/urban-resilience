import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urban_resilience/features/location/domain/selected_place.dart';

final selectedPlaceProvider = NotifierProvider<SelectedPlaceNotifier, SelectedPlace?>(
  SelectedPlaceNotifier.new,
);

class SelectedPlaceNotifier extends Notifier<SelectedPlace?> {
  static const String _key = 'selected_place';

  @override
  SelectedPlace? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return;
    }

    state = SelectedPlace.fromJson(Map<String, Object?>.from(decoded));
  }

  Future<void> select(SelectedPlace place) async {
    state = place;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(place.toJson()));
  }
}
