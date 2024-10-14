import 'dart:io';
import 'dart:typed_data';

import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/data_source_manager.dart';
import 'package:fitness_challenges/utils/sharedLogger.dart';
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
  final SharedLogger logger;

  HealthManager(this.challengeProvider, this.pb, {required this.logger});

  int? _steps;

  int? get steps => _steps;

  int? _azm;

  int? get activeMinutes => _azm;

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

  /// Attempts to fetch health data if all permissions are granted
  Future<void> fetchHealthData({BuildContext? context}) async {
    final health = Health();
    final type = await HealthTypeManager().getHealthType();


    if (!pb.authStore.isValid) {
      logger.debug("Pocketbase auth store not valid");
      return;
    }
    var userId = pb.authStore.model?.id;

    logger.debug("Using ${HealthTypeManager.formatType(type)} to sync health data");
    if (type == HealthType.systemManaged && Platform.isAndroid) {
      final isAvailable = types
          .map((type) => health.isDataTypeAvailable(type))
          .every((item) => item == true);
      if (!isAvailable) {
        logger.debug("Missing some health types");
        return;
      }

      final hasPermissions =
          await health.hasPermissions(types, permissions: permissions);

      if (hasPermissions == true) {
        var now = DateTime.now();
        var midnight = DateTime(now.year, now.month, now.day);
        _steps = await Health().getTotalStepsInInterval(midnight, now);
        _isConnected = true;
        notifyListeners(); // Notify listeners about the change
        logger.debug("Successfully synced $_steps steps");
      }
    } else if (type == HealthType.watch && Platform.isAndroid) {
      try {
        final FlutterWearOsConnectivity flutterWearOsConnectivity =
            FlutterWearOsConnectivity();

        await flutterWearOsConnectivity.configureWearableAPI();
        var devices = await flutterWearOsConnectivity.getConnectedDevices();
        if (devices.isEmpty) {
          logger.debug("No connected devices");
          return;
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
          return debugPrint("No steps from today");
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
          }
        }
      } catch (e, stacktrace) {
        logger.error("Error fetching health data from Wear OS: $e");
        logger.error(stacktrace.toString());
      }
    }

    for (final challenge in challengeProvider.challenges) {
      // Check if challenge has ended
      if (challenge.getBoolValue("ended") == true) continue;

      var challengeType = TypesExtension.of(challenge.getIntValue("type"));

      if (challengeType == Types.steps && steps != null) {
        final manager =
            StepsDataManager.fromJson(challenge.getDataValue("data"));

        logger.debug("Updating ${challenge.getStringValue("name")} to ${steps}");
        manager.updateUserActivity(userId, steps!);

        final dataSourceManager =
            DataSourceManager.fromChallenge(challenge)
                .setDataSource(userId, getSource(type!));

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
      }
    }

    if (context != null && context.mounted) {
      await Future.delayed(const Duration(seconds: 2));
      await challengeProvider.reloadChallenges(context);
    }
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
