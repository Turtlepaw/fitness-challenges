import 'package:fitness_challenges/utils/bingo/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Check if user has won diagonal", () {
    final userBingoData = UserBingoData(
      userId: 'user123',
      activities: List.generate(25, (index) {
        // Simulating a filled diagonal for testing
        if (index % 6 == 0) { // Top-left to bottom-right diagonal
          return BingoDataActivity(type: BingoDataType.filled, amount: 1);
        }
        return BingoDataActivity(type: BingoDataType.steps, amount: 1);
      }),
    );
    final manager = BingoDataManager([userBingoData]);

    List<int> winningTiles = manager.checkIfUserHasWon(5, userBingoData.userId);
    expect(winningTiles, [0, 6, 12, 18, 24]);
  });

  test("Check if user has won horizontal", () {
    final userBingoData = UserBingoData(
      userId: 'user456',
      activities: List.generate(25, (index) {
        // Simulating a filled second row
        if (index >= 5 && index < 10) { // Second row (indices 5-9)
          return BingoDataActivity(type: BingoDataType.filled, amount: 1);
        }
        return BingoDataActivity(type: BingoDataType.steps, amount: 1);
      }),
    );
    final manager = BingoDataManager([userBingoData]);

    List<int> winningTiles = manager.checkIfUserHasWon(5, userBingoData.userId);
    expect(winningTiles, [5, 6, 7, 8, 9]);
  });

  test("Check if user has won vertical", () {
    final userBingoData = UserBingoData(
      userId: 'user789',
      activities: List.generate(25, (index) {
        // Simulating a filled third column
        if (index % 5 == 2) { // Third column (indices 2, 7, 12, 17, 22)
          return BingoDataActivity(type: BingoDataType.filled, amount: 1);
        }
        return BingoDataActivity(type: BingoDataType.steps, amount: 1);
      }),
    );
    final manager = BingoDataManager([userBingoData]);

    List<int> winningTiles = manager.checkIfUserHasWon(5, userBingoData.userId);
    expect(winningTiles, [2, 7, 12, 17, 22]);
  });
}
