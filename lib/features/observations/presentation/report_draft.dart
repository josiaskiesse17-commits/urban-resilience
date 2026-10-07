import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
      photoName: photoName ?? this.photoName,
      photoPath: photoPath ?? this.photoPath,
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
  static const String _draftKey = 'report_draft';

  @override
  ReportDraftData build() {
    _loadDraft().then((draft) {
      if (draft != null) {
        state = draft;
      }
    });
    return const ReportDraftData(
      typeTitle: '',
      typeIcon: 'assets/icons/report-alert.svg',
      description: '',
      street: '',
      cityLine: '',
      photoName: null,
      photoPath: null,
      latitude: null,
      longitude: null,
      zoneId: null,
      hazardType: null,
      submittedId: null,
    );
  }

   Future<ReportDraftData?> _loadDraft() async {
     final prefs = await SharedPreferences.getInstance();
     final json = prefs.getString(_draftKey);
     if (json == null) {
       return null;
     }
     try {
       final draft = _decodeDraft(json);
       return draft;
     } catch (e) {
       return null;
     }
   }

   String _encodeDraft(ReportDraftData draft) {
     return jsonEncode({
       'typeId': draft.typeId,
       'typeTitle': draft.typeTitle,
       'typeIcon': draft.typeIcon,
       'description': draft.description,
       'photoName': draft.photoName,
       'photoPath': draft.photoPath,
       'street': draft.street,
       'cityLine': draft.cityLine,
       'latitude': draft.latitude,
       'longitude': draft.longitude,
       'zoneId': draft.zoneId,
       'hazardType': draft.hazardType,
       'submittedId': draft.submittedId,
     });
   }

   ReportDraftData? _decodeDraft(String json) {
     try {
       final map = jsonDecode(json) as Map<String, dynamic>;
       return ReportDraftData(
         typeId: map['typeId'] as String?,
         typeTitle: map['title'] as String,
         typeIcon: map['typeIcon'] as String,
         description: map['description'] as String,
         photoName: map['photoName'] as String?,
         photoPath: map['photoPath'] as String?,
         street: map['street'] as String,
         cityLine: map['cityLine'] as String,
         latitude: map['latitude'] as double?,
         longitude: map['longitude'] as double?,
         zoneId: map['zoneId'] as String?,
         hazardType: map['hazardType'] as String?,
         submittedId: map['submittedId'] as String?,
       );
     } catch (e) {
       return null;
     }
   }

   void setState(ReportDraftData newState) {
     state = newState;
     _saveDraft(newState);
   }

  void _saveDraft(ReportDraftData draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, _encodeDraft(draft));
  }

   void reset() {
     state = const ReportDraftData(
       typeTitle: '',
       typeIcon: 'assets/icons/report-alert.svg',
       description: '',
       street: '',
       cityLine: '',
       photoName: null,
       photoPath: null,
       latitude: null,
       longitude: null,
       zoneId: null,
       hazardType: null,
       submittedId: null,
     );
     _saveDraft(state);
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
