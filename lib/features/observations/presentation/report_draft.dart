import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportDraftData {
  final String typeTitle;
  final String typeIcon;
  final String description;
  final String? photoName;
  final String street;
  final String cityLine;
  final double latitude;
  final double longitude;

  const ReportDraftData({
    required this.typeTitle,
    required this.typeIcon,
    required this.description,
    required this.photoName,
    required this.street,
    required this.cityLine,
    required this.latitude,
    required this.longitude,
  });

  ReportDraftData copyWith({
    String? typeTitle,
    String? typeIcon,
    String? description,
    String? photoName,
    bool clearPhoto = false,
    String? street,
    String? cityLine,
    double? latitude,
    double? longitude,
  }) {
    return ReportDraftData(
      typeTitle: typeTitle ?? this.typeTitle,
      typeIcon: typeIcon ?? this.typeIcon,
      description: description ?? this.description,
      photoName: clearPhoto ? null : photoName ?? this.photoName,
      street: street ?? this.street,
      cityLine: cityLine ?? this.cityLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

final reportDraftProvider =
    NotifierProvider<ReportDraftNotifier, ReportDraftData>(
      ReportDraftNotifier.new,
    );

class ReportDraftNotifier extends Notifier<ReportDraftData> {
  @override
  ReportDraftData build() {
    return const ReportDraftData(
      typeTitle: 'Séismes (tremblements de terre)',
      typeIcon: 'assets/icons/report-waves.svg',
      description: '',
      photoName: 'fissures-facade.jpg',
      street: '24 rue Sainte',
      cityLine: '13001 Marseille',
      latitude: 43.295,
      longitude: 5.375,
    );
  }

  void setType({required String title, required String icon}) {
    state = state.copyWith(typeTitle: title, typeIcon: icon);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setPhoto(String? name) {
    state = state.copyWith(photoName: name, clearPhoto: name == null);
  }

  void setPlace({
    required String street,
    required String cityLine,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      street: street,
      cityLine: cityLine,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
