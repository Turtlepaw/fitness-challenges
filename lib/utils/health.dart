import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:health/health.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../manager.dart';

class HealthManager with ChangeNotifier {
  final ChallengeProvider challengeProvider;
  final PocketBase pb;

  HealthManager(this.challengeProvider, this.pb);

  int? _steps;
  int? get steps => _steps;

  /// Attempts to fetch health data if all permissions are granted
  void fetchHealthData({BuildContext? context}) async {
    final health = Health();
    final type = await HealthTypeManager().getHealthType();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final isAvailable = types
        .map((type) => health.isDataTypeAvailable(type))
        .every((item) => item == true);
    final hasPermissions =
        await health.hasPermissions(types, permissions: permissions);

    if (!pb.authStore.isValid) return;
    var userId = pb.authStore.model?.id;

    if (isAvailable && hasPermissions! && type == HealthType.systemManaged) {
      var now = DateTime.now();
      var midnight = DateTime(now.year, now.month, now.day);
      _steps = await Health().getTotalStepsInInterval(midnight, now);
      notifyListeners(); // Notify listeners about the change
    } else if (type == HealthType.watch) {
      final FlutterWearOsConnectivity _flutterWearOsConnectivity =
          FlutterWearOsConnectivity();

      // Fetches most recent data, even if it's from yesterday
      _flutterWearOsConnectivity.configureWearableAPI();
      var data = await _flutterWearOsConnectivity.getAllDataItems();
      final id = "com.turtlepaw.fitness_challenges.steps";
      final timeId = "com.turtlepaw.fitness_challenges.timestamp";
      if (data.first.mapData[id] != null) {
        var _timestamp = DateTime.parse(data.first.mapData[timeId]);
        if (isToday(_timestamp)) {
          _steps = data.first.mapData[id];

          notifyListeners(); // Notify listeners about the change
          debugPrint("Steps are at $_steps");
        } else {
          debugPrint("No steps from today");
        }
      }

      if (context != null && context.mounted) {
        challengeProvider.reloadChallenges(context);
      }
    }

    for (final challenge in challengeProvider.challenges) {
      // Check if challenge has ended
      if (challenge.getBoolValue("ended") == true) continue;

      var type = TypesExtension.of(challenge.getIntValue("type"));

      if (type == Types.steps && steps != null) {
        final manager =
            StepsDataManager.fromJson(challenge.getDataValue("data"));

        manager.updateUserActivity(userId, steps!);
        pb
            .collection(Collection.challenges)
            .update(challenge.id, body: {'data': manager.toJson()});
      }
    }

    if (context != null && context.mounted) {
      challengeProvider.reloadChallenges(context);
    }

    // Heart Rate will be done later
    // using age ->

    // var heartRate = await Health().getHealthDataFromTypes(
    //     startTime: midnight,
    //     endTime: now,
    //     types: [HealthDataType.HEART_RATE]);
    // print(heartRate.map((hr) => (hr.value as NumericHealthValue).numericValue));
    //print(heartRate);
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

enum HealthType { systemManaged, watch }

class HealthTypeManager {
  final dataId = "healthType";

  /// Sets the health type
  void setHealthType(HealthType type) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(dataId, type.index);
  }

  /// Gets the health type, defaults to HealthType.systemManaged
  Future<HealthType?> getHealthType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = prefs.getInt(dataId);
    return data != null ? HealthType.values.elementAt(data) : null;
  }
}
