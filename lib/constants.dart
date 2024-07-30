import 'package:health/health.dart';

const String apiUrl = "https://fitnesschallenges.pockethost.io";
const types = [
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
];

const permissions = [
  HealthDataAccess.READ,
  HealthDataAccess.READ,
];