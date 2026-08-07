/// Shared number formatting so case counts (which range from tens to tens
/// of millions across dengue/malaria/cholera) read consistently everywhere
/// they're displayed.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:intl/intl.dart';

class Formatting {
  Formatting._();

  static final NumberFormat _caseCount = NumberFormat.decimalPattern('en_US');

  static String caseCount(double? value) {
    if (value == null) return '—';
    return _caseCount.format(value.round());
  }

  static String temperature(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)}°C';
  }

  static String precipitation(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)} mm';
  }
}
