import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthIcon extends StatelessWidget {
  final String asset;
  final Color color;
  final double? size;

  const AuthIcon({
    super.key,
    required this.asset,
    required this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
