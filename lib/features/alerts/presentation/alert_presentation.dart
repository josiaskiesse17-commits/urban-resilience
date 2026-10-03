import 'package:flutter/material.dart';

import '../domain/risk_alert.dart';

String alertSeverityLabel(AlertSeverity severity) {
  return switch (severity) {
    AlertSeverity.info => 'Information',
    AlertSeverity.warning => 'Avertissement',
    AlertSeverity.danger => 'Danger',
    AlertSeverity.critical => 'Critique',
  };
}

Color alertSeverityColor(AlertSeverity severity) {
  return switch (severity) {
    AlertSeverity.info => Colors.blue,
    AlertSeverity.warning => Colors.orange,
    AlertSeverity.danger => Colors.deepOrange,
    AlertSeverity.critical => Colors.red,
  };
}
