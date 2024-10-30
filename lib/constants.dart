import 'package:health/health.dart';
import 'package:intl/intl.dart';

const String apiUrl = "https://fitnesschallenges.webredirect.org";
const types = [
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.WATER,
  HealthDataType.TOTAL_CALORIES_BURNED,
];

var permissions = types.map((type) => HealthDataAccess.READ).toList();

final pbDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');