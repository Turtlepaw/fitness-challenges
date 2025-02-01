import 'package:intl/intl.dart';

String formatInt(int number) {
  return NumberFormat.decimalPattern().format(number);
}

String formatNumber(num number) {
  return NumberFormat.decimalPattern().format(number.toInt());
}

String trimString(String input, int maxCharacters) {
  if (input.length <= maxCharacters) {
    return input;
  } else {
    return '${input.substring(0, maxCharacters - 3)}...';
  }
}
