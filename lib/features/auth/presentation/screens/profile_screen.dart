import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/core/theme/theme_provider.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _nearbyAlerts = true;
  bool _reportUpdates = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final place = ref.watch(selectedPlaceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Camille Bernard';
    final email = (user?.email.trim().isNotEmpty ?? false)
        ? user!.email.trim()
        : 'camille.bernard@exemple.fr';
    final city = place?.label ?? 'Marseille';
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profil',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mon compte et mes préférences',
                              style: TextStyle(fontSize: 13, color: AppPalette.textMuted),
                            ),
                          ],
                        ),
                      ),
                      _SquareIcon(asset: 'assets/icons/profile-help.svg'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  children: [
                    _Card(
                      padding: const EdgeInsets.all(14),
                      radius: 20,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppPalette.infoBoxBg,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.textDark,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 13, color: AppPalette.textMuted),
                                ),
                              ],
                            ),
                          ),
                          _SquareIcon(asset: 'assets/icons/profile-pencil.svg', filled: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Card(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      radius: 14,
                      child: Row(
                        children: [
                          _SquareIcon(asset: 'assets/icons/map-pin-place.svg', filled: true, size: 38),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ville principale',
                                  style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
                                ),
                                Text(
                                  city,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Modifier',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Card(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Compte',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 7),
                          _Setting(
                            icon: 'assets/icons/profile-user.svg',
                            title: 'Modifier le nom',
                          ),
                          const Divider(height: 1, color: AppPalette.inputBorder),
                          _Setting(
                            icon: 'assets/icons/profile-key.svg',
                            title: 'Mot de passe',
                            subtitle: 'Modifié il y a 3 mois',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Card(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Préférences de notifications',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textDark,
                            ),
                          ),
                          _SwitchRow(
                            title: 'Alertes près de chez moi',
                            subtitle: 'Risques autour de $city',
                            value: _nearbyAlerts,
                            onChanged: (value) => setState(() => _nearbyAlerts = value),
                          ),
                          _SwitchRow(
                            title: 'Suivi de mes signalements',
                            subtitle: 'Validation et changements de statut',
                            value: _reportUpdates,
                            onChanged: (value) => setState(() => _reportUpdates = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Card(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thème',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppPalette.background,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _ThemeChoice(
                                  asset: 'assets/icons/profile-sun.svg',
                                  label: 'Clair',
                                  selected: themeMode != ThemeMode.dark,
                                  onTap: () => ref
                                      .read(themeModeProvider.notifier)
                                      .setThemeMode(ThemeMode.light),
                                ),
                                _ThemeChoice(
                                  asset: 'assets/icons/profile-moon.svg',
                                  label: 'Sombre',
                                  selected: themeMode == ThemeMode.dark,
                                  onTap: () => ref
                                      .read(themeModeProvider.notifier)
                                      .setThemeMode(ThemeMode.dark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppPalette.primary,
                        side: const BorderSide(color: AppPalette.inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: SvgPicture.asset(
                        'assets/icons/profile-logout.svg',
                        width: 19,
                        height: 19,
                      ),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const _ProfileNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _Card({
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.inputBorder),
      ),
      child: child,
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final String asset;
  final bool filled;
  final double size;

  const _SquareIcon({
    required this.asset,
    this.filled = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppPalette.infoBoxBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: filled ? null : Border.all(color: AppPalette.inputBorder),
      ),
      child: SvgPicture.asset(asset, width: size > 36 ? 19 : 17, height: size > 36 ? 19 : 17),
    );
  }
}

class _Setting extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;

  const _Setting({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: subtitle == null ? 40 : 48,
      child: Row(
        children: [
          _SquareIcon(asset: icon, filled: true, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textDark,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppPalette.textMuted)),
              ],
            ),
          ),
          const Text(
            'Modifier',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textDark,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppPalette.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppPalette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected ? Border.all(color: AppPalette.inputBorder) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(asset, width: 17, height: 17),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppPalette.primary : AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileNavigation extends StatelessWidget {
  const _ProfileNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppPalette.inputBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Nav(label: 'Carte', asset: 'assets/icons/map-nav-map.svg', onTap: () => context.go('/map')),
          _Nav(label: 'Signaler', asset: 'assets/icons/map-nav-plus.svg', onTap: () => context.go('/report')),
          _Nav(label: 'Alertes', asset: 'assets/icons/map-nav-bell.svg', onTap: () => context.go('/alerts')),
          const _Nav(label: 'Profil', asset: 'assets/icons/map-nav-user.svg', selected: true),
        ],
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback? onTap;

  const _Nav({
    required this.label,
    required this.asset,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppPalette.infoBoxBg : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: SvgPicture.asset(asset, width: 20, height: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppPalette.primary : AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
