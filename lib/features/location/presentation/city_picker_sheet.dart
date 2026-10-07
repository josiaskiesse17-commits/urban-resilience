import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/location/domain/covered_cities.dart';
import 'package:urban_resilience/features/location/domain/selected_place.dart';

Future<SelectedPlace?> showCityPicker(BuildContext context) {
  return showModalBottomSheet<SelectedPlace>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _CityPickerSheet(),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cities = filterCities(_query);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.inputBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choisir ma ville',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(fontSize: 15, color: AppPalette.textDark),
            decoration: InputDecoration(
              hintText: 'Rechercher une ville',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: SvgPicture.asset(
                  'assets/icons/location-search.svg',
                  width: 18,
                  height: 18,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                maxWidth: 40,
                minHeight: 48,
                maxHeight: 48,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (cities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucune ville correspondante.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppPalette.textMuted),
              ),
            )
          else
            ...cities.map(
              (city) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  city.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textDark,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(city),
              ),
            ),
        ],
      ),
    );
  }
}
