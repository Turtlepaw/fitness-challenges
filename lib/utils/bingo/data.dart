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
    return {
      'type': type.index,
      'amount': amount
    };
  }
}

class UserBingoData {
  final String userId;
  final List<BingoDataActivity> activities;

  UserBingoData({
    required this.userId,
    required this.activities,
  });

  // Factory method to create a UserBingoData from JSON
  factory UserBingoData.fromJson(Map<String, dynamic> json) {
    return UserBingoData(
      userId: json['userId'] as String,
      activities: (json['activities'] as List<dynamic>)
          .map((activityJson) =>
              BingoDataActivity.fromJson(activityJson as Map<String, dynamic>))
          .toList(),
    );
  }

  // Method to convert a UserBingoData to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
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
      'usersBingoData':
          data.map((userData) => userData.toJson()).toList(),
    };
  }

  // Method to update a user's bingo activity
  BingoDataManager? updateUserBingoActivity(
      String userId, int index, BingoDataType newType) {
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
  BingoDataManager addUser(String userId, { Difficulty difficulty = Difficulty.easy }) {
    data.add(UserBingoData(userId: userId, activities: Bingo().generateBingoActivities(difficulty)));
    return this;
  }

  @override
  BingoDataManager removeUser(String userId) {
    data.removeWhere((value) => value.userId == userId);
    return this;
  }
}
