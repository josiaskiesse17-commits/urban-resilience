import 'package:flutter/material.dart';

class RiskDetailsScreen extends StatelessWidget {
  final String riskId;

  const RiskDetailsScreen({
    super.key,
    required this.riskId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Risk Details: $riskId'),
      ),
    );
  }
}