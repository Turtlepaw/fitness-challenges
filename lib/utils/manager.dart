import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:pocketbase/pocketbase.dart';

abstract class Manager<T> {
  final List<T> data;

  Manager(this.data);

  Map<String, dynamic> toJson();

  Manager<T> addUser(String userId);

  Manager<T> removeUser(String userId);

  static Manager fromData(dynamic data, Types type) {
    switch (type) {
      case Types.steps:
        return StepsDataManager.fromJson(data);
      case Types.bingo:
      // Implement and return BingoDataManager here
        throw UnimplementedError();
      case Types.sleep:
      // Implement and return SleepDataManager here
        throw UnimplementedError();
      default:
        throw UnsupportedError("Unsupported type");
    }
  }

  static Manager fromChallenge(RecordModel challenge) {
    var type = challenge.getIntValue("type", -1);
    if (type == -1) throw UnsupportedError("Invalid 'type'");

    var data = challenge.getDataValue("data");
    switch (TypesExtension.of(type)) {
      case Types.steps:
        return StepsDataManager.fromJson(data);
      case Types.bingo:
      // Implement and return BingoDataManager here
        throw UnimplementedError();
      case Types.sleep:
      // Implement and return SleepDataManager here
        throw UnimplementedError();
      default:
        throw UnsupportedError("Unsupported type");
    }
  }
}
