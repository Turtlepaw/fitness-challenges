import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePasswordDialog> {
  bool _isLoading = false;

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
                        Symbols.mark_email_read_rounded,
                        size: 40,
                        color: color,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        "We've sent an email",
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  MarkdownBody(
                    data:
                        "We've sent an email to change your password, don't forget to check your spam folder.",
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyLarge,
                      textAlign: WrapAlignment.center,
                    ),
                    // style: theme.textTheme.bodyLarge,
                    // textAlign: TextAlign.center,
                  ),
                ],
              )),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Got it"))
            ],
          )
        ],
      ),
    ));
  }

  void _handleClose() {
    return Navigator.of(context).pop();
  }
}
