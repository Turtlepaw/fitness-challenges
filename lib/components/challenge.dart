import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/utils/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';

class Challenge extends StatelessWidget {
  final RecordModel challenge;
  final PocketBase pb;

  const Challenge({super.key, required this.challenge, required this.pb});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        double width;
        if (constraints.maxWidth < 400) {
          width =
              constraints.maxWidth - 30; // Fill the width on phones with margin
        } else {
          width = 300; // Limit to ~200 on larger devices
        }

        return Card.outlined(
          clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: InkWell(
            splashColor: theme.colorScheme.primary.withAlpha(30),
            onTap: () {
              openDialog(context);
            },
            child: SizedBox(
              width: width,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(challenges
                            .elementAt(challenge.getIntValue("type"))
                            .icon),
                        const SizedBox(width: 10),
                        Text(
                          challenge.getStringValue("name"),
                          style: theme.typography.englishLike.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...challenge.expand["users"]!.map((user) {
                          return AdvancedAvatar(
                            name: user.getStringValue("username"),
                            style: theme.typography.englishLike.titleMedium
                                ?.copyWith(color: theme.colorScheme.onPrimary),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          );
                        }).toList()
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialog(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Symbols.close_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(challenge.getStringValue("name")),
        ),
        body: switch (challenge.getIntValue("type")) {
          0 => _buildBingoCard(context),
          _ => const Text("unknown challenge type")
        },
      ),
    );
  }

  Widget _buildBingoCard(BuildContext context) {
    var theme = Theme.of(context);
    Map<String, dynamic> jsonMap = challenge.getDataValue("data");
    final bingoActivities =
        BingoDataManager.fromJson(jsonMap).usersBingoData.firstWhere((value) {
      return value.userId == pb.authStore.model.id;
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 100).floor();

        return Container(
          padding: const EdgeInsets.all(10.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount > 1 ? crossAxisCount : 1,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5.0,
            ),
            itemCount: bingoActivities.activities.length,
            itemBuilder: (context, index) {
              return Card(
                  clipBehavior: Clip.hardEdge,
                  color: theme.colorScheme.primary,
                  child: InkWell(
                    splashColor: theme.colorScheme.onPrimary.withAlpha(30),
                    onTap: () {},
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            bingoActivities.activities[index].type.asIcon(),
                            size: 40,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            bingoActivities.activities[index].amount.toString(),
                            textAlign: TextAlign.center,
                            style: theme.typography.englishLike.labelLarge
                                ?.copyWith(color: theme.colorScheme.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ));
            },
          ),
        );
      },
    );
  }

  void openDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildDialog(context),
    );
  }
}
