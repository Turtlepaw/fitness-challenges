import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:health/health.dart';
import 'package:pocketbase/pocketbase.dart';

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
    final isAvailable = types
        .map((type) => health.isDataTypeAvailable(type))
        .every((item) => item == true);
    final hasPermissions =
        await health.hasPermissions(types, permissions: permissions);

    if (isAvailable && hasPermissions! && pb.authStore.isValid) {
      var userId = pb.authStore.model?.id;
      var now = DateTime.now();
      var midnight = DateTime(now.year, now.month, now.day);
      _steps = await Health().getTotalStepsInInterval(midnight, now);

      for(final challenge in challengeProvider.challenges){
        var type = TypesExtension.of(challenge.getIntValue("type"));

        if(type == Types.steps && steps != null){
          final manager = StepsDataManager.fromJson(
            challenge.getDataValue("data")
          );

          manager.updateUserActivity(userId, steps!);
          pb.collection(Collection.challenges).update(challenge.id, body: {
            'data': manager.toJson()
          });
        }
      }

      if(context != null && context.mounted){
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
  }
}
