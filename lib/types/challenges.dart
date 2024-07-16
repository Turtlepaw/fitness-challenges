import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

// Define a class to represent a challenge
class Challenge {
  final IconData icon;
  final String name;
  final String description;

  const Challenge(this.icon, this.name, this.description);
}

// Create a constant listof challenges
const List<Challenge> challenges = [
  Challenge(Symbols.casino_rounded, "Bingo", "Dynamic"),
  Challenge(Symbols.steps_rounded, "Steps", "Most steps"),
  Challenge(Icons.bedtime_rounded, "Sleep", "Best sleep"),
  // Add more challenges as needed
];