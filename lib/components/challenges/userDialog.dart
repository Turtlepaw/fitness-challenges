import 'package:fitness_challenges/components/loader.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../manager.dart';
import '../../utils/manager.dart';
class UserDialog extends StatefulWidget {
  final PocketBase pb;
  final RecordModel challenge;

  const UserDialog({super.key, required this.pb, required this.challenge});

  @override
  _UserDialogState createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    var theme = Theme.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Users",
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: ListView(
                shrinkWrap: true, // Ensures the ListView takes only the necessary space
                children: [
                  ...challenge.expand["users"]!.map((user) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          user.getStringValue("username") ?? "",
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      TextButton(onPressed: user.id == challenge.getDataValue("host") ? null : () async {
                        final id = user.id;
                        final data = Manager.fromChallenge(challenge)
                            .removeUser(id)
                            .toJson();
                        await widget.pb
                            .collection(Collection.challenges)
                            .update(challenge.id,
                            body: {"users-": id, "data": data});

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kicked ${user.getStringValue("username")}'),
                            ),
                          );
                        }
                      }, child: Text(user.id == challenge.getDataValue("host") ? "Host" :"Kick"))
                    ],
                  ))
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: _handleClose,
                  child: const Text("Close"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleClose() {
    Navigator.of(context).pop();
  }
}
