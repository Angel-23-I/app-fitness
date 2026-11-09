import 'package:intl/intl.dart';

/// 60.0 -> "60", 62.5 -> "62.5"
String fmtNum(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Whole number with Spanish digit grouping.
String fmtThousands(num v) => NumberFormat.decimalPattern('es').format(v.round());

String fmtDate(DateTime d) => DateFormat.yMMMd('es').format(d);

String fmtDateTime(DateTime d) => DateFormat.yMMMd('es').add_Hm().format(d);

/// Parses user input accepting a decimal comma.
double? parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
