import 'dart:io';
import 'dart:typed_data';

import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:health/health.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'challengeManager.dart';

class HealthManager with ChangeNotifier {
  final ChallengeProvider challengeProvider;
  final PocketBase pb;

  HealthManager(this.challengeProvider, this.pb);

  int? _steps;

  int? get steps => _steps;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  List<HealthType> _capabilities = List.empty(growable: true);

  List<HealthType> get capabilities => _capabilities;

  /// Checks the connection state and updates `isConnected`
  Future<void> checkConnectionState() async {
    final health = Health();
    final type = await HealthTypeManager().getHealthType();

    if (Platform.isAndroid) {
      final isAvailable = types
          .map((type) => health.isDataTypeAvailable(type))
          .every((item) => item == true);
      if (isAvailable) _capabilities.add(HealthType.systemManaged);

      final FlutterWearOsConnectivity flutterWearOsConnectivity =
          FlutterWearOsConnectivity();
      await flutterWearOsConnectivity.configureWearableAPI();
      var caps = await flutterWearOsConnectivity.getAllCapabilities();
      debugPrint("Caps: $caps");

      if (caps.containsKey("verify_wear_app")) {
        capabilities.add(HealthType.watch);
      }

      if (type == HealthType.systemManaged) {
        final hasPermissions =
            await health.hasPermissions(types, permissions: permissions);

        _isConnected = isAvailable && (hasPermissions ?? false);
      } else if (type == HealthType.watch) {
        _isConnected = caps.containsKey("verify_wear_app");
      }
    }

    notifyListeners();
  }

  /// Attempts to fetch health data if all permissions are granted
  void fetchHealthData({BuildContext? context}) async {
    final health = Health();
    final type = await HealthTypeManager().getHealthType();

    if (!pb.authStore.isValid) return;
    var userId = pb.authStore.model?.id;

    if (type == HealthType.systemManaged && Platform.isAndroid) {
      final isAvailable = types
          .map((type) => health.isDataTypeAvailable(type))
          .every((item) => item == true);
      if (!isAvailable) return;

      final hasPermissions =
          await health.hasPermissions(types, permissions: permissions);

      if (hasPermissions == true) {
        var now = DateTime.now();
        var midnight = DateTime(now.year, now.month, now.day);
        _steps = await Health().getTotalStepsInInterval(midnight, now);
        _isConnected = true;
        notifyListeners(); // Notify listeners about the change
      }
    } else if (type == HealthType.watch && Platform.isAndroid) {
      final FlutterWearOsConnectivity flutterWearOsConnectivity =
          FlutterWearOsConnectivity();

      await flutterWearOsConnectivity.configureWearableAPI();
      var devices = await flutterWearOsConnectivity.getConnectedDevices();

      for (var device in devices) {
        await flutterWearOsConnectivity
            .sendMessage(Uint8List(1),
                deviceId: device.id,
                path: "/request-sync",
                priority: MessagePriority.high)
            .then((d) => debugPrint(d.toString()));
      }

      await Future.delayed(const Duration(seconds: 2));
      // Fetches most recent data, even if it's from yesterday
      var data = await flutterWearOsConnectivity.getAllDataItems();
      const id = "com.turtlepaw.fitness_challenges.steps";
      const timeId = "com.turtlepaw.fitness_challenges.timestamp";
      debugPrint(data.toString());

      if (devices.isNotEmpty) _isConnected = true;

      if (data.isEmpty) {
        return debugPrint("No steps from today");
      }

      if (data?.first?.mapData[id] != null) {
        // This makes sure it doesn't use data
        // from yesterday
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

  static String formatType(HealthType? type) {
    return switch (type) {
      HealthType.systemManaged => "System",
      HealthType.watch => _getWatchType(),
      null => "Unknown",
    };
  }

  static String _getWatchType() {
    if (Platform.isAndroid) {
      return "Wear OS";
    } else if (Platform.isIOS) {
      return "Apple Watch";
    } else {
      return "Watch";
    }
  }
}
