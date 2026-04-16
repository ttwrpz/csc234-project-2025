import 'package:flutter/material.dart';

/// Screen-size breakpoint utilities for responsive layout decisions.
class Responsive {
  static const double compactMaxWidth = 600;
  static const double expandedMaxWidth = 840;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactMaxWidth;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compactMaxWidth;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedMaxWidth;
}
