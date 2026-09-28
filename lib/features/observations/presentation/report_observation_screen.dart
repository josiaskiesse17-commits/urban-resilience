import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/photo_stamper.dart';
import '../domain/observation.dart';
import 'providers/observations_providers.dart';

class ReportObservationScreen extends ConsumerStatefulWidget {
  const ReportObservationScreen({super.key});

  @override
  ConsumerState<ReportObservationScreen> createState() =>
      _ReportObservationScreenState();
}

class _ReportObservationScreenState
    extends ConsumerState<ReportObservationScreen> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  ObservationType _type = ObservationType.flooding;
  File? _mediaFile;
  ObservationMediaType? _mediaType;
  Position? _position;

  bool _loadingLocation = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final file = await _picker.pickMedia();

    if (file == null) return;

    final isVideo = file.mimeType?.startsWith('video/') ??
        RegExp(
          r'\.(mp4|mov|avi|mkv)$',
          caseSensitive: false,
        ).hasMatch(file.path);

    setState(() {
      _mediaFile = File(file.path);
      _mediaType = isVideo
          ? ObservationMediaType.video
          : ObservationMediaType.image;
    });
  }

  Future<void> _chooseMediaSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Les coordonnées GPS seront ajoutées'),
              onTap: () => Navigator.of(sheetContext).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(sheetContext).pop('gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'camera') {
      await _takePhoto();
    } else if (choice == 'gallery') {
      await _pickMedia();
    }
  }

  Future<void> _takePhoto() async {
    // Les coordonnées sont nécessaires pour les incruster sur la photo.
    if (_position == null) {
      await _getLocation();
    }
    if (_position == null) {
      if (mounted) {
        _showMessage(
          'Position GPS requise pour prendre une photo.',
        );
      }
      return;
    }

    try {
      final captured = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (captured == null) return;

      final stamped = await PhotoStamper.stampCoordinates(
        source: File(captured.path),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
      );

      if (!mounted) return;

      setState(() {
        _mediaFile = stamped;
        _mediaType = ObservationMediaType.image;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('Impossible de prendre la photo : $error');
    }
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(
          'Activez la localisation de votre téléphone.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'Permission de localisation refusée.',
        );
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _position = position;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage('$error');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();

    if (description.length < 10) {
      _showMessage(
        'La description doit contenir au moins 10 caractères.',
      );
      return;
    }

    if (_position == null) {
      _showMessage(
        'Récupérez votre position avant l’envoi.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final observationId = await ref
          .read(observationsRepositoryProvider)
          .createObservation(
            type: _type,
            latitude: _position!.latitude,
            longitude: _position!.longitude,
            description: description,
            mediaFile: _mediaFile,
            mediaType: _mediaType,
          );

      if (!mounted) return;

      context.go(
        '/observations/success?id=$observationId',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Échec de l’envoi : $error',
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: const Text(
          'Nouveau signalement',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------
              // ALERTE 112
              // ---------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEFF1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF146F78),
                      size: 30,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'En cas de danger immédiat, appelez le 112.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF123C43),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Que constatez-vous ?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF123C43),
                ),
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------
              // TYPES
              // ---------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      icon: Icons.water,
                      label: 'Inondation',
                      selected: _type == ObservationType.flooding,
                      onTap: () {
                        setState(() {
                          _type = ObservationType.flooding;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      icon: Icons.landscape_outlined,
                      label: 'Éboulement',
                      selected: _type == ObservationType.landslide,
                      onTap: () {
                        setState(() {
                          _type = ObservationType.landslide;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Incendie',
                      selected: _type == ObservationType.other,
                      onTap: () {
                        setState(() {
                          _type = ObservationType.other;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------
              // DESCRIPTION
              // ---------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Décrivez la situation',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123C43),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _descriptionController,
                    builder: (_, value, __) {
                      return Text(
                        '${value.text.length} / 300',
                        style: const TextStyle(
                          color: Color(0xFF60777B),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _descriptionController,
                minLines: 5,
                maxLines: 7,
                maxLength: 300,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF17353B),
                ),
                decoration: InputDecoration(
                  hintText:
                      'Décrivez précisément ce que vous constatez...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF789096),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFF197A83),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(22),
                ),
              ),

              const SizedBox(height: 26),

              // ---------------------------------------------------------
              // PHOTO
              // ---------------------------------------------------------
              const Text(
                'Ajouter une photo',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF123C43),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _chooseMediaSource,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD3E1E3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDEFF1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          _mediaFile == null
                              ? Icons.camera_alt_outlined
                              : Icons.check_circle_outline,
                          size: 34,
                          color: const Color(0xFF147782),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mediaFile == null
                                  ? 'Prendre ou choisir une photo'
                                  : 'Média sélectionné',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17353B),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _mediaFile == null
                                  ? 'JPG ou PNG • coordonnées GPS ajoutées'
                                  : _mediaFile!.path
                                      .split(Platform.pathSeparator)
                                      .last,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF60777B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // LOCALISATION
              // ---------------------------------------------------------
              GestureDetector(
                onTap: _loadingLocation ? null : _getLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD3E1E3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDEFF1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF147782),
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _position == null
                                  ? 'Localisation'
                                  : 'Localisation détectée',
                              style: const TextStyle(
                                color: Color(0xFF60777B),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _position == null
                                  ? 'Appuyez pour détecter votre position'
                                  : '${_position!.latitude.toStringAsFixed(5)}, '
                                      '${_position!.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Color(0xFF17353B),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_loadingLocation)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Text(
                          'Modifier',
                          style: TextStyle(
                            color: Color(0xFF147782),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ---------------------------------------------------------
              // ENVOYER
              // ---------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF197A83),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_outlined,
                          size: 27,
                        ),
                  label: Text(
                    _submitting
                        ? 'Envoi en cours...'
                        : 'Envoyer le signalement',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Center(
                child: Text(
                  'Votre signalement sera vérifié avant publication.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF60777B),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 138,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFDDEFF1)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? const Color(0xFF197A83)
                : const Color(0xFFD3E1E3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: selected
                  ? const Color(0xFF147782)
                  : const Color(0xFF60777B),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF147782)
                    : const Color(0xFF60777B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}