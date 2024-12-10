import 'package:fitness_challenges/components/challenge.dart';
import 'package:fitness_challenges/components/userPreview.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';

class UserDialog extends StatefulWidget {
  final PocketBase pb;
  final RecordModel user;

  const UserDialog({super.key, required this.pb, required this.user});

  @override
  _UserDialogState createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    var theme = Theme.of(context);
    final badges = user.getListValue("badges").length;

    return Dialog(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: (){
                      Navigator.of(context).pop();
                    }, icon: const Icon(Icons.close))
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  // Ensures the ListView takes only the necessary space
                  children: [
                    Avatar(user: user, size: 55,),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            getUsernameFromUser(user),
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center, // Aligns text in the center horizontally
                            softWrap: true, // Ensures text wraps
                            overflow: TextOverflow.clip, // Prevents overflowing
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.award_star_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        const SizedBox(width: 5),
                        Text("${badges > 0 ? "${badges} badge${badges > 1 ? "s" : ""}" : "No badges yet"}", textAlign: TextAlign.center, style: theme.textTheme.bodyLarge)
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ])));
  }

  void _handleClose() {
    Navigator.of(context).pop();
  }
}
