import 'package:flutter/material.dart';

import '../domain/risk_alert.dart';

/// Single place where an alert severity becomes its French label.
String alertSeverityLabel(AlertSeverity severity) {
  return switch (severity) {
    AlertSeverity.info => 'Information',
    AlertSeverity.warning => 'Avertissement',
    AlertSeverity.danger => 'Danger',
    AlertSeverity.critical => 'Critique',
  };
}

/// Single place where an alert severity becomes its display colour.
Color alertSeverityColor(AlertSeverity severity) {
  return switch (severity) {
    AlertSeverity.info => Colors.blue,
    AlertSeverity.warning => Colors.orange,
    AlertSeverity.danger => Colors.deepOrange,
    AlertSeverity.critical => Colors.red,
  };
}
