import 'dart:math';

import 'package:fitness_challenges/utils/bingo/data.dart';

import '../../types/challenges.dart';

class Bingo {
  List<BingoDataActivity> generateBingoActivities(Difficulty difficulty) {
    final random = Random();
    final stepsRange = _getStepsRange(difficulty);
    final distanceRange = _getDistanceRange(difficulty);
    final activeMinutesRange = _getActiveMinutesRange(difficulty);
    final caloriesRange = _getCaloriesRange(difficulty);
    final waterRange = _getWaterRange(difficulty);

    final List<BingoDataActivity> activities = List.generate(25, (index) {
      switch (index % 5) {
        case 0:
          final steps = (random.nextInt(stepsRange[1] - stepsRange[0] + 1) +
                  stepsRange[0])
              .roundToNearest(50)
              .clamp(stepsRange[0], stepsRange[1]);
          return BingoDataType.steps.toActivity(steps);

        case 1:
          final distance = ((random.nextDouble() *
                          (distanceRange[1] - distanceRange[0]) +
                      distanceRange[0])
                  .roundToNearestNum(0.5)) // Use as double to keep precision
              .clamp(distanceRange[0], distanceRange[1]);
          return BingoDataType.distance
              .toActivity(distance); // Convert to int for compatibility

        case 2:
          final activeMinutes = (random.nextInt(
                      activeMinutesRange[1] - activeMinutesRange[0] + 1) +
                  activeMinutesRange[0])
              .roundToNearest(5)
              .clamp(activeMinutesRange[0], activeMinutesRange[1]);
          return BingoDataType.azm.toActivity(activeMinutes);

        case 3:
          final calories =
              (random.nextInt(caloriesRange[1] - caloriesRange[0] + 1) +
                      caloriesRange[0])
                  .roundToNearest(10)
                  .clamp(caloriesRange[0], caloriesRange[1]);
          return BingoDataType.calories.toActivity(calories);

        case 4:
          // Only include water intake if the user is comfortable with it
          final water = (random.nextInt(waterRange[1] - waterRange[0] + 1) +
                  waterRange[0])
              .roundToNearest(250)
              .clamp(waterRange[0], waterRange[1]);
          return BingoDataType.water.toActivity(water);

        default:
          return BingoDataType.steps.toActivity(stepsRange[0]);
      }
    });

    activities.shuffle();
    return activities;
  }

  List<int> _getStepsRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [500, 3000];
      case Difficulty.medium:
        return [3000, 8000];
      case Difficulty.hard:
        return [8000, 15000];
      default:
        return [500, 3000];
    }
  }

  List<double> _getDistanceRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [0.5, 3.0];
      case Difficulty.medium:
        return [3.0, 8.0];
      case Difficulty.hard:
        return [8.0, 12.0];
      default:
        return [0.5, 3.0];
    }
  }

  List<int> _getActiveMinutesRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [10, 30];
      case Difficulty.medium:
        return [30, 60];
      case Difficulty.hard:
        return [60, 90];
      default:
        return [10, 30];
    }
  }

  List<int> _getCaloriesRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [50, 150];
      case Difficulty.medium:
        return [150, 300];
      case Difficulty.hard:
        return [300, 600];
      default:
        return [50, 150];
    }
  }

  List<int> _getWaterRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return [500, 1000];
      case Difficulty.medium:
        return [1000, 1500];
      case Difficulty.hard:
        return [1500, 2000];
      default:
        return [500, 1000];
    }
  }
}

extension on num {
  int roundToNearest(int n) {
    return (this / n).round() * n;
  }

  double roundToNearestNum(num n) {
    // Return a double to preserve precision
    return (this / n).roundToDouble() *
        n; // Use roundToDouble() to avoid potential errors
  }
}
