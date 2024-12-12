import 'package:health/health.dart';
import 'package:intl/intl.dart';

const String apiUrl = "https://fitnesschallenges.webredirect.org";
const String websiteUri = "https://fitnesschallenges.vercel.app";
const String inviteUri = "$websiteUri/invite";
const types = [
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.WATER,
  HealthDataType.TOTAL_CALORIES_BURNED,
];

var permissions = types.map((type) => HealthDataAccess.READ).toList();

final pbDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
const MAX_USERNAME_LENGTH = 35;
const maxUsernameLengthShort = 15;