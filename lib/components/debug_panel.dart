import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/sharedLogger.dart';
import 'challenges/confirmDialog.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: MenuAnchor(
        menuChildren: <Widget>[
          MenuItemButton(
            leadingIcon: Icon(
              Icons.bug_report_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(
                "Export Logs",
                style: theme.textTheme.bodyLarge
              //?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            onPressed: () async {
              final logger = Provider.of<SharedLogger>(context, listen: false);
              final file = await logger.exportLogsToFile("debug_logs");
              if(file == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Failed to export logs"),
                ));
                return;
              } else {
                print(file.absolute);
                showDialog(
                    context: context,
                    builder: (context) => const ConfirmDialog(
                      isDestructive: false,
                      icon: Icons.check_rounded,
                      title: "Logs Saved",
                      description: "File saved in **Downloads** folder",
                    ),
                    useSafeArea: false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Logs saved in Downloads"),
                ));
                return;
              }
            },
          ),
          MenuItemButton(
            leadingIcon: Icon(
              Icons.discord_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(
                "Get help",
                style: theme.textTheme.bodyLarge
              //?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            onPressed: () async {
              launchUrl(Uri.parse("https://discord.gg/3u2bWnzg3x"));
            },
          )
        ],
        builder: (BuildContext context, MenuController controller,
            Widget? child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(Icons.more_vert),
          );
        },
      ),
    );
  }

}