import 'dart:math';

import 'package:fitness_challenges/utils/data.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../types/challenges.dart';

class Bingo {
  List<BingoDataActivity> generateBingoActivities(Difficulty difficulty) {
    final random = Random();
    final stepsRange = _getStepsRange(difficulty);
    final distanceRange = _getDistanceRange(difficulty);
    final activeMinutesRange = _getActiveMinutesRange(difficulty);

    final List<BingoDataActivity> activities = List.generate(25, (index) {
      if (index % 3 == 0) {
        final steps = (random.nextInt(stepsRange[1] - stepsRange[0]) + stepsRange[0]).roundToNearest(5);
        return BingoDataType.steps.toActivity(steps);
      } else if (index % 3 == 1) {
        final distance = (random.nextInt(distanceRange[1] - distanceRange[0]) + distanceRange[0]).roundToNearest(5);
        return BingoDataType.distance.toActivity(distance);
      } else {
        final activeMinutes = (random.nextInt(activeMinutesRange[1] - activeMinutesRange[0]) + activeMinutesRange[0]).roundToNearest(5);
        return BingoDataType.azm.toActivity(activeMinutes);
      }
    });

    activities.shuffle();
    return activities;
  }

  List<int> _getStepsRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [1000, 5000];
      case Difficulty.medium:
        return [5000, 10000];
      case Difficulty.hard:
        return [10000, 20000];
      default:
        return [1000, 5000];
    }
  }

  List<int> _getDistanceRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [1, 5];
      case Difficulty.medium:
        return [5, 10];
      case Difficulty.hard:
        return [10, 20];
      default:
        return [1, 5];
    }
  }

  List<int> _getActiveMinutesRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [10, 30];
      case Difficulty.medium:
        return [30, 60];
      case Difficulty.hard:
        return [60, 120];
      default:
        return [10, 30];
    }
  }
}

extension on num {
  int roundToNearest(int n) {
    return (this / n).round() * n;
  }
}