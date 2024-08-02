import 'package:health/health.dart';
import 'package:intl/intl.dart';

const String apiUrl = "https://fitnesschallenges.pockethost.io";
const types = [
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
];

const permissions = [
  HealthDataAccess.READ,
  HealthDataAccess.READ,
];

final pbDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');