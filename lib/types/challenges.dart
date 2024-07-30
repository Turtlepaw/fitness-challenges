import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

enum Difficulty { easy, medium, hard }

class Challenge {
  final IconData icon;
  final String name;
  final String description;

  const Challenge(this.icon, this.name, this.description);
}

const List<Challenge> challenges = [
  Challenge(Symbols.casino_rounded, "Bingo", "Dynamic"),
  Challenge(Symbols.steps_rounded, "Steps", "Most steps"),
  Challenge(Icons.bedtime_rounded, "Sleep", "Best sleep"),
];

extension DifficultyExtension on Difficulty {
  static Difficulty of(int value) {
    switch (value) {
      case 0:
        return Difficulty.easy;
      case 1:
        return Difficulty.medium;
      case 2:
        return Difficulty.hard;
      default:
        throw ArgumentError('Invalid difficulty value: $value');
    }
  }
}

enum Types { bingo, steps, sleep }
extension TypesExtension on Types {
  static Types of(int value) {
    switch (value) {
      case 0:
        return Types.bingo;
      case 1:
        return Types.steps;
      case 2:
        return Types.sleep;
      default:
        throw ArgumentError('Invalid type value: $value');
    }
  }
}