import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

enum BingoDataType { filled, steps, distance, azm }

extension BingoDataTypeExtension on BingoDataType {
  BingoDataActivity toActivity(int amount) {
    return BingoDataActivity(type: this, amount: amount);
  }

  IconData asIcon() {
    return switch (this) {
      BingoDataType.steps => Symbols.steps_rounded,
      BingoDataType.distance => Symbols.distance_rounded,
      BingoDataType.azm => Symbols.azm_rounded,
    BingoDataType.filled => Symbols.check_rounded,
      _ => Symbols.indeterminate_question_box_rounded
    };
  }
}

class BingoDataActivity {
  final BingoDataType type;
  final int amount;

  BingoDataActivity({required this.type, required this.amount});

  // Factory method to create a BingoDataActivity from JSON
  factory BingoDataActivity.fromJson(Map<String, dynamic> json) {
    return BingoDataActivity(
      type: BingoDataType.values[json['type'] as int],
      amount: json['amount'] as int,
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

class BingoDataManager {
  final List<UserBingoData> usersBingoData;

  BingoDataManager({
    required this.usersBingoData,
  });

  // Factory method to create a Challenge from JSON
  factory BingoDataManager.fromJson(Map<String, dynamic> json) {
    return BingoDataManager(
      usersBingoData: (json['usersBingoData'] as List<dynamic>)
          .map((userJson) =>
              UserBingoData.fromJson(userJson as Map<String, dynamic>))
          .toList(),
    );
  }

  // Method to convert a Challenge to JSON
  Map<String, dynamic> toJson() {
    return {
      'usersBingoData':
          usersBingoData.map((userData) => userData.toJson()).toList(),
    };
  }

  // Method to update a user's bingo activity
  BingoDataManager? updateUserBingoActivity(
      String userId, int index, BingoDataType newType) {
    for (var user in usersBingoData) {
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
}
