import 'package:fitness_challenges/constants.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class GetHelpDialog extends StatefulWidget {
  const GetHelpDialog({super.key});

  @override
  _GetHelpState createState() => _GetHelpState();
}

class _GetHelpState extends State<GetHelpDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    final destructiveButtonStyle = ButtonStyle(
        backgroundColor: WidgetStateProperty.all(theme.colorScheme.error));

    return Dialog(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Icon(
                        Symbols.help_rounded,
                        size: 40,
                        color: color,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Pick a method of contact",
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min, // Prevents extra space
                    children: [
                      SizedBox(
                        width: double.infinity, // Ensures full width
                        height: 45,
                        child: FilledButton(
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(EdgeInsets.zero), // Removes default padding
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                  bottom: Radius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          onPressed: () {
                            launchUrl(Uri.parse(githubUrl));
                          },
                          child: Center( // Ensures text is centered
                            child: Text(
                              'Create a GitHub issue',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: FilledButton(
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8),
                                  bottom: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          onPressed: () {
                            launchUrl(Uri.parse(discordInviteUrl));
                          },
                          child: Center(
                            child: Text(
                              'Join our Discord',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              )),
        ],
      ),
    ));
  }

  void _handleClose() {
    return Navigator.of(context).pop();
  }
}
