import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';
import 'package:urban_resilience/features/observations/presentation/report_draft.dart';

class _ReportType {
  final String id;
  final String title;
  final String subtitle;
  final String icon;

  const _ReportType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ReportCategory {
  final String label;
  final List<_ReportType> types;

  const _ReportCategory({required this.label, required this.types});
}

const _categories = [
  _ReportCategory(
    label: 'Risques naturels',
    types: [
      _ReportType(
        id: 'flood',
        title: 'Inondation',
        subtitle: 'Crues, débordements, eaux montantes',
        icon: 'assets/icons/report-waves-water.svg',
      ),
      _ReportType(
        id: 'heatwave',
        title: 'Chaleur',
        subtitle: 'Canicules, chaleur extrême, vagues de chaleur prolongées',
        icon: 'assets/icons/report-sun.svg',
      ),
      _ReportType(
        id: 'landslide',
        title: 'Glissement de terrain',
        subtitle: 'Glissements, éboulements, coulées de neige',
        icon: 'assets/icons/report-mountain.svg',
      ),
    ],
  ),
];

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key, this.zoneId, this.hazardType});

  final String? zoneId;
  final String? hazardType;

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  String _selectedId = 'flood';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(reportDraftProvider.notifier);
      final previous = ref.read(reportDraftProvider);
      // Keep context if already set; otherwise apply route query.
      final zone = widget.zoneId?.trim().isNotEmpty == true
          ? widget.zoneId!.trim()
          : previous.zoneId;
      final hazard = widget.hazardType?.trim().isNotEmpty == true
          ? widget.hazardType!.trim()
          : previous.hazardType;
      notifier.reset();
      if ((zone != null && zone.isNotEmpty) ||
          (hazard != null && hazard.isNotEmpty)) {
        notifier.setContext(zoneId: zone, hazardType: hazard);
      }
    });
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      _HeaderButton(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/map');
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faire un signalement',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aidez à informer votre zone',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/report-info.svg',
                            width: 18,
                            height: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'En cas de danger immédiat, contacter les autorités compétentes.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choisissez un type de catastrophe',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sélectionnez le phénomène principal pour mieux cadrer votre signalement.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StepChip(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final category in _categories) ...[
                            Text(
                              category.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final type in category.types) ...[
                              _TypeRow(
                                type: type,
                                selected: type.id == _selectedId,
                                onTap: () =>
                                    setState(() => _selectedId = type.id),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
          onPressed: () {
            final type = _categories
                .expand((category) => category.types)
                .firstWhere((item) => item.id == _selectedId);
            ref
                .read(reportDraftProvider.notifier)
                .setType(
                  id: type.id,
                  title: type.title,
                  icon: type.icon,
                );
            context.push('/report/description');
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          child: const Text(
            'Continuer vers la description',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
                ),
              ),
              const ReportNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: SvgPicture.asset(
            'assets/icons/risk-arrow-left.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/report-dot.svg', width: 8, height: 8),
          const SizedBox(width: 8),
          Text(
            'Étape 1',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final _ReportType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeRow({
    required this.type,
    required this.selected,
    required this.onTap,
  });

@override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(type.icon, width: 20, height: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SelectionMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  final bool selected;

  const _SelectionMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: selected
          ? SvgPicture.asset(
              'assets/icons/report-check.svg',
              width: 12,
              height: 12,
            )
          : null,
    );
  }
}
