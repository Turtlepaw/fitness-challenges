import 'package:intl/intl.dart';

String formatInt(int number) {
  return NumberFormat.decimalPattern().format(number);
}

String formatNumber(num number) {
  return NumberFormat.decimalPattern().format(number.toInt());
}
