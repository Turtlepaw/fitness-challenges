import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

class Challenge extends StatefulWidget {
  final RecordModel challenge;

  const Challenge({super.key, required this.challenge});

  @override
  State<Challenge> createState() => _ChallengeState();
}

class _ChallengeState extends State<Challenge> {
  @override
  Widget build(BuildContext context) {
    RecordModel challenge = widget.challenge;
    final theme = Theme.of(context);
    final width = 400.toDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              challenge.getStringValue("name")
            )
          ],
        ),
      ),
    );
  }
}
