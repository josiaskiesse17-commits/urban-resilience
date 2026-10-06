import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';
import 'package:urban_resilience/features/observations/presentation/report_draft.dart';

class ReportDescriptionScreen extends ConsumerStatefulWidget {
  const ReportDescriptionScreen({super.key});

  @override
  ConsumerState<ReportDescriptionScreen> createState() =>
      _ReportDescriptionScreenState();
}

class _ReportDescriptionScreenState
    extends ConsumerState<ReportDescriptionScreen> {
  late final TextEditingController _description;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(
      text: ref.read(reportDraftProvider).description,
    );
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null) {
      return;
    }
    ref.read(reportDraftProvider.notifier).setPhoto(
          name: file.name,
          path: file.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              const SafeArea(bottom: false, child: ReportHeader()),
              const ReportProgress(step: 2, label: 'Description et photo'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    _Card(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Type de catastrophe',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.textDark,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/report'),
                                child: const Text(
                                  'Modifier',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppPalette.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppPalette.infoBoxBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SvgPicture.asset(
                                  draft.typeIcon,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  draft.typeTitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppPalette.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Que constatez-vous ?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _description,
                            minLines: 3,
                            maxLines: 5,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppPalette.textDark,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppPalette.background,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppPalette.inputBorder,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Décrivez uniquement ce que vous observez.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Photo',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.textDark,
                                  ),
                                ),
                              ),
                              Text(
                                'Facultative',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.primary,
                                ),
                              ),
                            ],
                          ),
                          if (draft.photoName != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/report-photo.svg',
                                  width: 52,
                                  height: 56,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        draft.photoName!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppPalette.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Pièce jointe illustrative',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppPalette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _PhotoButton(
                                  asset: 'assets/icons/report-camera.svg',
                                  label: 'Prendre une photo',
                                  onTap: () => _pick(ImageSource.camera),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _PhotoButton(
                                  asset: 'assets/icons/report-gallery.svg',
                                  label: 'Choisir dans la galerie',
                                  onTap: () => _pick(ImageSource.gallery),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPalette.infoBoxBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppPalette.infoText,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Restez en sécurité. Ne vous approchez pas des dégâts pour prendre une photo.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: AppPalette.infoText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ReportActionButton(
                label: 'Continuer vers la localisation',
                onPressed: () {
                  ref
                      .read(reportDraftProvider.notifier)
                      .setDescription(_description.text.trim());
                  context.push('/report/location');
                },
              ),
              const ReportNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.inputBorder),
      ),
      child: child,
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.inputBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(asset, width: 15, height: 15),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
