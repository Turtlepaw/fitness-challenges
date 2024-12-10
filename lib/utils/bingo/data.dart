import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../types/challenges.dart';
import '../manager.dart';
import 'manager.dart';

enum BingoDataType { filled, steps, distance, azm, calories, water }

extension BingoDataTypeExtension on BingoDataType {
  BingoDataActivity toActivity(num amount) {
    return BingoDataActivity(type: this, amount: amount);
  }

  IconData asIcon() {
    return switch (this) {
      BingoDataType.steps => Symbols.steps_rounded,
      BingoDataType.distance => Symbols.distance_rounded,
      BingoDataType.azm => Symbols.azm_rounded,
      BingoDataType.filled => Symbols.check_rounded,
      BingoDataType.calories => Symbols.local_fire_department_rounded,
      BingoDataType.water => Symbols.water_full_rounded,
      _ => Symbols.indeterminate_question_box_rounded
    };
  }

  String asString() {
    return switch (this) {
      BingoDataType.steps => "Steps",
      BingoDataType.distance => "Distance",
      BingoDataType.azm => "Active Minutes",
      BingoDataType.filled => "Filled",
      BingoDataType.calories => "Calories",
      BingoDataType.water => "Water",
      _ => "Unknown"
    };
  }
}

class BingoDataActivity {
  final BingoDataType type;
  final num amount;

  BingoDataActivity({required this.type, required this.amount});

  // Factory method to create a BingoDataActivity from JSON
  factory BingoDataActivity.fromJson(Map<String, dynamic> json) {
    return BingoDataActivity(
      type: BingoDataType.values[json['type'] as int],
      amount: json['amount'], // No need to cast to int here
    );
  }

  // Method to convert a BingoDataActivity to JSON
  Map<String, dynamic> toJson() {
    return {'type': type.index, 'amount': amount};
  }
}

class UserBingoData {
  final String userId;
  final List<BingoDataActivity> activities;
  List<int> winningTiles;

  UserBingoData({
    required this.userId,
    required this.activities,
    this.winningTiles = const [],
  });

  // Factory method to create a UserBingoData from JSON
  factory UserBingoData.fromJson(Map<String, dynamic> json) {
    return UserBingoData(
      userId: json['userId'] as String,
      activities: (json['activities'] as List<dynamic>)
          .map((activityJson) =>
              BingoDataActivity.fromJson(activityJson as Map<String, dynamic>))
          .toList(),
      winningTiles:
          ((json['winningTiles'] as List<dynamic>?) ?? []).cast<int>(),
    );
  }

  // Method to convert a UserBingoData to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'winningTiles': winningTiles
    };
  }

  UserBingoData setWinningTiles(List<int> winningTiles) {
    this.winningTiles =
        List.from(winningTiles); // Create a new list with the provided tiles
    return this;
  }
}

class BingoDataManager extends Manager<UserBingoData> {
  BingoDataManager(super.data);

  // Factory method to create a Challenge from JSON
  factory BingoDataManager.fromJson(Map<String, dynamic> json) {
    return BingoDataManager(
      (json['usersBingoData'] as List<dynamic>)
          .map((userJson) =>
              UserBingoData.fromJson(userJson as Map<String, dynamic>))
          .toList(),
    );
  }

  // Method to convert a Challenge to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'usersBingoData': data.map((userData) => userData.toJson()).toList(),
    };
  }

  // Method to update a user's bingo activity
  Future<BingoDataManager?> updateUserBingoActivity(
      String userId, int index, BingoDataType newType) async {
    for (var user in data) {
      if (user.userId == userId) {
        if (index >= 0 && index < user.activities.length) {
          var activity = user.activities[index];
          user.activities[index] =
              BingoDataActivity(type: newType, amount: activity.amount);
          return this;
        }
      }
    }
    return null;
  }

  @override
  BingoDataManager addUser(String userId,
      {Difficulty difficulty = Difficulty.easy}) {
    data.add(UserBingoData(
        userId: userId,
        activities: Bingo().generateBingoActivities(difficulty)));
    return this;
  }

  @override
  BingoDataManager removeUser(String userId) {
    data.removeWhere((value) => value.userId == userId);
    return this;
  }

  UserBingoData getUser(String userId) {
    return data.firstWhere((element) => element.userId == userId);
  }

  BingoDataManager setWinningTilesOf(String userId, List<int> winningTiles) {
    getUser(userId)
        .setWinningTiles(winningTiles); // Set the new winningTiles for the user
    return this;
  }

  List<int> checkIfUserHasWon(int gridSize, String userId) {
    // Extract activities for simplicity
    List<BingoDataActivity> activities = getUser(userId).activities;

    // Helper to check if all activities in a given list are filled
    bool _isLineFilled(List<int> indices) {
      return indices.every((index) =>
          index >= 0 &&
          index < activities.length &&
          activities[index].type == BingoDataType.filled);
    }

    // Check rows
    for (int row = 0; row < gridSize; row++) {
      List<int> rowIndices =
          List.generate(gridSize, (col) => row * gridSize + col);
      if (_isLineFilled(rowIndices)) {
        return rowIndices; // Return winning row indices
      }
    }

    // Check columns
    for (int col = 0; col < gridSize; col++) {
      List<int> colIndices =
          List.generate(gridSize, (row) => row * gridSize + col);
      if (_isLineFilled(colIndices)) {
        return colIndices; // Return winning column indices
      }
    }

    // Check top-left to bottom-right diagonal
    List<int> diagonal1Indices =
        List.generate(gridSize, (i) => i * gridSize + i);
    if (_isLineFilled(diagonal1Indices)) {
      return diagonal1Indices; // Return winning diagonal indices
    }

    // Check top-right to bottom-left diagonal
    List<int> diagonal2Indices =
        List.generate(gridSize, (i) => (i + 1) * gridSize - (i + 1));
    if (_isLineFilled(diagonal2Indices)) {
      return diagonal2Indices; // Return winning diagonal indices
    }

    // No win detected
    return []; // Empty list for no winners
  }
}
