import 'package:flutter/widgets.dart';
import 'package:pocketbase/pocketbase.dart';

enum DataSource { wearOS, healthConnect, unknown }

class DataSourceEntry {
  final String userId;
  final DataSource source;

  DataSourceEntry(this.userId, this.source);

  // Convert a JSON map to a DateTimeIntPair
  factory DataSourceEntry.fromJson(Map<String, dynamic> json) {
    var source = json['source'] != null
        ? (DataSource.values[json['source'] as int])
        : DataSource.unknown;

    return DataSourceEntry(
      json['userId'] as String,
      source,
    );
  }

  // Convert a DateTimeIntPair to a JSON map
  Map<String, dynamic> toJson() {
    return {'userId': userId, 'source': source.index};
  }
}

class DataSourceManager {
  final List<DataSourceEntry> users;

  DataSourceManager(this.users);

  DataSourceManager setDataSource(String userId, DataSource dataSource) {
    users.removeWhere((entry) => entry.userId == userId);
    users.add(DataSourceEntry(userId, dataSource));

    return this;
  }

  DataSourceEntry? getUser(String userId) {
    try {
      return users.firstWhere((entry) => entry.userId == userId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((entry) => entry.toJson()).toList(),
    };
  }

  factory DataSourceManager.fromChallenge(RecordModel challenge) {
    try {
      var json =
          challenge.get<Map<String, dynamic>>("dataSources", null);
      if (json == null) return DataSourceManager(List.empty(growable: true));

      return DataSourceManager(
        (json['users'] as List<dynamic>)
            .map((activityJson) => DataSourceEntry.fromJson(activityJson))
            .toList(),
      );
    } catch (e, stackTrace) {
      debugPrint("Failed to get data normally: $e");
      debugPrint("Stack trace: $stackTrace");
      return DataSourceManager(List.empty(growable: true));
    }
  }
}
