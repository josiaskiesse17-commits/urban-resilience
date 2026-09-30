import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/location/domain/selected_place.dart';
import 'package:urban_resilience/features/location/presentation/city_picker_sheet.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
  bool _isRequesting = false;
  String? _error;

  Future<void> _chooseCity() async {
    final city = await showCityPicker(context);
    if (city == null || !mounted) {
      return;
    }

    await ref.read(selectedPlaceProvider.notifier).select(city);
    if (!mounted) {
      return;
    }

    context.go('/map');
  }

  Future<void> _authorizeLocation() async {
    setState(() {
      _isRequesting = true;
      _error = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) {
        return;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isRequesting = false;
          _error = 'La localisation est nécessaire pour afficher les risques proches.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }

      await ref.read(selectedPlaceProvider.notifier).select(
            SelectedPlace(
              label: 'Ma position',
              latitude: position.latitude,
              longitude: position.longitude,
              fromGps: true,
            ),
          );
      if (!mounted) {
        return;
      }

      context.go('/map');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRequesting = false;
        _error = 'Impossible d’accéder à votre position.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 28,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _Introduction(),
                        _LocationChoices(
                          isRequesting: _isRequesting,
                          error: _error,
                          onAuthorize: _authorizeLocation,
                          onChooseCity: _chooseCity,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Introduction extends StatelessWidget {
  const _Introduction();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Brand(),
        SizedBox(height: 24),
        _ProximityIllustration(),
        SizedBox(height: 24),
        Text(
          'Les alertes utiles, au bon endroit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppPalette.textDark,
            height: 1.12,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'urban-resilience utilise votre position pour afficher les risques proches et vous prévenir uniquement lorsque cela compte.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppPalette.textMuted,
            height: 1.48,
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Emblem(),
            SizedBox(width: 8),
            Text(
              'urban-resilience',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppPalette.textDark,
                height: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          'Prévenir. Comprendre. Agir.',
          style: TextStyle(
            fontSize: 13,
            color: AppPalette.textMuted,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SvgPicture.asset(
        'assets/icons/location-shield.svg',
        width: 24,
        height: 24,
      ),
    );
  }
}

class _ProximityIllustration extends StatelessWidget {
  const _ProximityIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 190,
      decoration: BoxDecoration(
        color: AppPalette.infoBoxBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/location-halo.svg',
            width: 154,
            height: 154,
          ),
          Image(
            image: AssetImage('assets/icons/location-zone.png'),
            width: 104,
            height: 104,
          ),
          _Pin(),
          Positioned(
            left: 28,
            top: 31,
            child: _Dot(color: Color(0xFFE8A629)),
          ),
          Positioned(
            right: 30,
            bottom: 34,
            child: _Dot(color: Color(0xFFD64A45)),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppPalette.primary,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        'assets/icons/location-pin.svg',
        width: 32,
        height: 32,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LocationChoices extends StatelessWidget {
  final bool isRequesting;
  final String? error;
  final VoidCallback onAuthorize;
  final VoidCallback onChooseCity;

  const _LocationChoices({
    required this.isRequesting,
    required this.error,
    required this.onAuthorize,
    required this.onChooseCity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppPalette.error,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _ChoiceButton(
          label: 'Autoriser ma localisation',
          filled: true,
          isLoading: isRequesting,
          icon: SvgPicture.asset(
            'assets/icons/location-navigation.svg',
            width: 19,
            height: 19,
          ),
          onPressed: onAuthorize,
        ),
        const SizedBox(height: 12),
        _ChoiceButton(
          label: 'Choisir ma ville manuellement',
          filled: false,
          icon: SvgPicture.asset(
            'assets/icons/location-search.svg',
            width: 19,
            height: 19,
          ),
          onPressed: onChooseCity,
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool filled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppPalette.primary;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? AppPalette.primary : Colors.white,
          disabledBackgroundColor: AppPalette.primary.withValues(alpha: 0.7),
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: filled ? AppPalette.primary : AppPalette.inputBorder,
            ),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
