import 'dart:io';
import 'dart:typed_data';

import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/data_source_manager.dart';
import 'package:fitness_challenges/utils/sharedLogger.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:health/health.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'challengeManager.dart';

class HealthManager with ChangeNotifier {
  final ChallengeProvider challengeProvider;
  final PocketBase pb;
  final SharedLogger logger;

  HealthManager(this.challengeProvider, this.pb, {required this.logger});

  int? _steps;

  int? get steps => _steps;

  int? _azm;

  int? get activeMinutes => _azm;

  num? _calories;

  num? get calories => _calories;

  num? _water;

  num? get water => _water;

  num? _distance;

  num? get distance => _distance;

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

      try {
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
      } catch (e, stacktrace) {
        debugPrint("Error in Wear OS connection: $e");
        debugPrint(stacktrace.toString());
      }
    }

    notifyListeners();
  }

  Future<num> getDataFromType(DateTime start, HealthDataType type) async {
    var points = await Health().getHealthDataFromTypes(
        startTime: start, endTime: DateTime.now(), types: [type]);
    final data = Health().removeDuplicates(points).map((it) {
      final value = it.value;
      if (value is NumericHealthValue) {
        return value.numericValue;
      } else {
        return 0;
      }
    });

    if (data.isEmpty) {
      return 0; // Return 0 if data is empty
    } else {
      return data.reduce((value, element) => value + element);
    }
  }

  /// Attempts to fetch health data if all permissions are granted
  Future<bool> fetchHealthData({BuildContext? context}) async {
    final health = Health();
    final type = await HealthTypeManager().getHealthType();

    if (!pb.authStore.isValid) {
      logger.debug("Pocketbase auth store not valid");
      return false;
    }
    var userId = pb.authStore.model?.id;

    logger.debug(
        "Using ${HealthTypeManager.formatType(type)} ($type) to sync health data");
    if (type == HealthType.systemManaged && Platform.isAndroid) {
      final isAvailable = types
          .map((type) => health.isDataTypeAvailable(type))
          .every((item) => item == true);
      if (!isAvailable) {
        logger.debug("Missing some health types");
        HealthTypeManager().clearHealthType();
        if(context != null && context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync failed: Missing data types'),
            ),
          );
        }
        return false;
      }

      final hasPermissions = await Future.wait(types.map((type) async {
        final hasPermission = await health
                .hasPermissions([type], permissions: [HealthDataAccess.READ]) ??
            false;
        logger.debug(
            "Permission for $type is ${hasPermission ? 'granted ✅' : 'denied ❌'}");
        return hasPermission;
      })).then((results) => results.every((item) => item == true));

      if (hasPermissions == true) {
        var now = DateTime.now();
        var midnight = DateTime(now.year, now.month, now.day);
        final startTime = midnight;
        _steps = await Health().getTotalStepsInInterval(midnight, now);
        _calories = await getDataFromType(startTime, HealthDataType.TOTAL_CALORIES_BURNED);
        _water = await getDataFromType(startTime, HealthDataType.WATER);
        _distance = await getDataFromType(startTime, HealthDataType.DISTANCE_DELTA);
        _isConnected = true;
        notifyListeners(); // Notify listeners about the change
        logger.debug("Successfully synced:\n\n👟 Steps: $steps\n🔥 Calories: $calories\n💦 Water: $water\n🏃 Distance: $distance");
      } else {
        logger.debug("No health permissions, sync failed");
        HealthTypeManager().clearHealthType();
        if(context != null && context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sync failed: Missing permissions'),
              action: SnackBarAction(label: "Fix", onPressed: () async {
                await HealthConnectFactory.openHealthConnectSettings();
              }),
            ),
          );
        }
        return false;
      }
    } else if (type == HealthType.watch && Platform.isAndroid) {
      try {
        final FlutterWearOsConnectivity flutterWearOsConnectivity =
            FlutterWearOsConnectivity();

        await flutterWearOsConnectivity.configureWearableAPI();
        var devices = await flutterWearOsConnectivity.getConnectedDevices();
        if (devices.isEmpty) {
          logger.debug("No connected devices");
          return false;
        }

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
          logger.debug("No data from Wear OS client");
          return false;
        }

        if (data?.first?.mapData[id] != null) {
          // This makes sure it doesn't use data
          // from yesterday
          var _timestamp = DateTime.parse(data.first.mapData[timeId]);
          if (isToday(_timestamp)) {
            _steps = data.first.mapData[id];

            notifyListeners(); // Notify listeners about the change
            logger.debug("Synced $_steps steps from Wear OS client");
          } else {
            logger.debug("No steps from today using Wear OS client");
            return false;
          }
        }
      } catch (e, stacktrace) {
        logger.error("Error fetching health data from Wear OS: $e");
        logger.error(stacktrace.toString());
        return false;
      }
    }

    for (final challenge in challengeProvider.challenges) {
      // Check if challenge has ended
      if (challenge.getBoolValue("ended") == true) continue;

      var challengeType = TypesExtension.of(challenge.getIntValue("type"));
      var dataSourceManager = DataSourceManager.fromChallenge(challenge);

      if (type != null) {
        dataSourceManager.setDataSource(userId, getSource(type));
      }

      if (challengeType == Types.steps && steps != null) {
        final manager =
            StepsDataManager.fromJson(challenge.getDataValue("data"));

        logger
            .debug("Updating ${challenge.getStringValue("name")} to ${steps}");
        manager.updateUserActivity(userId, steps!);

        try {
          await pb.collection(Collection.challenges).update(challenge.id,
              body: {
                'data': manager.toJson(),
                'dataSources': dataSourceManager.toJson()
              });
        } catch (e, stacktrace) {
          logger.error("Error updating challenge: $e");
          logger.error(stacktrace.toString());
        }
      } else if (challengeType == Types.bingo) {
        await pb.collection(Collection.challenges).update(challenge.id,
            body: {'dataSources': dataSourceManager.toJson()});
      }
    }

    if (context != null && context.mounted) {
      await Future.delayed(const Duration(seconds: 2));
      await challengeProvider.reloadChallenges(context);
    }

    return true;
  }

  DataSource getSource(HealthType type) {
    if (type == HealthType.watch && Platform.isAndroid) {
      return DataSource.wearOS;
    } else if (type == HealthType.systemManaged && Platform.isAndroid) {
      return DataSource.healthConnect;
    } else {
      return DataSource.unknown;
    }
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
  Future<void> setHealthType(HealthType type) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt(dataId, type.index);
  }

  void clearHealthType() async {
    final prefs = SharedPreferencesAsync();
    await prefs.remove(dataId);
  }

  /// Gets the health type, defaults to HealthType.systemManaged
  Future<HealthType?> getHealthType() async {
    final prefs = SharedPreferencesAsync();
    final data = await prefs.getInt(dataId);
    return data != null ? HealthType.values.elementAt(data) : null;
  }

  static String formatType(HealthType? type) {
    return switch (type) {
      HealthType.systemManaged => _getSystemType(),
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

  static String _getSystemType() {
    if (Platform.isAndroid) {
      return "Health Connect";
    } else if (Platform.isIOS) {
      return "Apple Health";
    } else {
      return "Unavailable";
    }
  }
}
