import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/utils/manager.dart';

class StepsEntry {
  final DateTime dateTime;
  final int value;

  StepsEntry(this.dateTime, this.value);

  // Convert a JSON map to a DateTimeIntPair
  factory StepsEntry.fromJson(Map<String, dynamic> json) {
    return StepsEntry(
      DateTime.parse(json['dateTime'] as String),
      json['value'] as int,
    );
  }

  // Convert a DateTimeIntPair to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'value': value
    };
  }
}

class UserStepsData {
  final String userId;
  final List<StepsEntry> entries;

  UserStepsData({
    required this.userId,
    required this.entries,
  });

  // Factory method to create a UserBingoData from JSON
  factory UserStepsData.fromJson(Map<String, dynamic> json) {
    return UserStepsData(
      userId: json['userId'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((activityJson) => StepsEntry.fromJson(activityJson))
          .toList(),
    );
  }

  // Method to convert a UserBingoData to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'entries': entries.map((activity) => activity.toJson()).toList(),
    };
  }
}

class StepsDataManager extends Manager<UserStepsData> {
  StepsDataManager(super.data);

  // Factory method to create a StepsDataManager from JSON
  factory StepsDataManager.fromJson(Map<String, dynamic> json) {
    return StepsDataManager(
      (json['data'] as List<dynamic>)
          .map((userJson) =>
              UserStepsData.fromJson(userJson as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'data': data.map((userData) => userData.toJson()).toList(),
    };
  }

  @override
  StepsDataManager addUser(String userId, { Difficulty difficulty = Difficulty.easy }) {
    data.add(UserStepsData(userId: userId, entries: []));
    return this;
  }

  @override
  StepsDataManager removeUser(String userId) {
    data.removeWhere((value) => value.userId == userId);
    return this;
  }

  /// Method to update or add a user's activity
  StepsDataManager? updateUserActivity(String userId, int value) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    for (var user in data) {
      if (user.userId == userId) {
        // Check if an entry for today already exists
        bool updated = false;
        for (var i = 0; i < user.entries.length; i++) {
          if (user.entries[i].dateTime == today) {
            // Update existing entry
            user.entries[i] = StepsEntry(today, value);
            updated = true;
            break;
          }
        }

        if (!updated) {
          // Add new entry if none for today exists
          user.entries.add(StepsEntry(today, value));
        }

        return this; // Return updated manager
      }
    }

    // User not found, return null or handle it as needed
    return null;
  }
}
