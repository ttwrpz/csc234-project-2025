import 'package:flutter/material.dart';

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
