import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportDraftData {
  final String? typeId;
  final String typeTitle;
  final String typeIcon;
  final String description;
  final String? photoName;
  final String? photoPath;
  final String street;
  final String cityLine;
  final double? latitude;
  final double? longitude;
  final String? zoneId;
  final String? hazardType;
  final String? submittedId;

  const ReportDraftData({
    this.typeId,
    required this.typeTitle,
    required this.typeIcon,
    required this.description,
    this.photoName,
    this.photoPath,
    required this.street,
    required this.cityLine,
    this.latitude,
    this.longitude,
    this.zoneId,
    this.hazardType,
    this.submittedId,
  });

  bool get hasType => typeId != null && typeId!.isNotEmpty;

  bool get hasPlace => latitude != null && longitude != null;

  ReportDraftData copyWith({
    String? typeId,
    String? typeTitle,
    String? typeIcon,
    String? description,
    String? photoName,
    String? photoPath,
    bool clearPhoto = false,
    String? street,
    String? cityLine,
    double? latitude,
    double? longitude,
    String? zoneId,
    String? hazardType,
    String? submittedId,
    bool clearSubmittedId = false,
  }) {
    return ReportDraftData(
      typeId: typeId ?? this.typeId,
      typeTitle: typeTitle ?? this.typeTitle,
      typeIcon: typeIcon ?? this.typeIcon,
      description: description ?? this.description,
      photoName: clearPhoto ? null : photoName ?? this.photoName,
      photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
      street: street ?? this.street,
      cityLine: cityLine ?? this.cityLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zoneId: zoneId ?? this.zoneId,
      hazardType: hazardType ?? this.hazardType,
      submittedId: clearSubmittedId
          ? null
          : submittedId ?? this.submittedId,
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
      typeTitle: '',
      typeIcon: 'assets/icons/report-alert.svg',
      description: '',
      street: '',
      cityLine: '',
    );
  }

  void reset() {
    state = build();
  }

  void setContext({String? zoneId, String? hazardType}) {
    state = state.copyWith(
      zoneId: zoneId,
      hazardType: hazardType,
    );
  }

  void setType({
    required String id,
    required String title,
    required String icon,
  }) {
    state = state.copyWith(typeId: id, typeTitle: title, typeIcon: icon);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setPhoto({String? name, String? path}) {
    if (name == null && path == null) {
      state = state.copyWith(clearPhoto: true);
      return;
    }

    state = state.copyWith(photoName: name, photoPath: path);
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

  void setSubmittedId(String id) {
    state = state.copyWith(submittedId: id);
  }
}
