import 'package:fitness_challenges/components/dialog/loadingDialog.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/sharedLogger.dart';
import 'dialog/confirmDialog.dart';

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
              Symbols.bug_report_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(
                "Export Logs",
                style: theme.textTheme.bodyLarge
              //?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            onPressed: () async {
              showDialog(
                  context: context,
                  builder: (context) => const LoadingDialog(
                    isDestructive: false,
                    icon: Icons.check_rounded,
                    title: "Saving Logs",
                    description: "This will take a few moments.",
                  ),
                  useSafeArea: false);

              final logger = Provider.of<SharedLogger>(context, listen: false);
              final file = await logger.exportLogsToFile("debug_logs");
              await Future.delayed(Duration.zero, () {
                // close dialog
                if(context.mounted){
                  print("Closing dialog");
                  //return Navigator.of(context).pop();
                }
              });
              print("Dialog closed");
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
                    useSafeArea: false).then((_){
                      if(context.mounted && Navigator.canPop(context))
                      Navigator.of(context).pop();
                });
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
          ),
          MenuItemButton(
            // leadingIcon: Image.asset(
            //   "./images/github-mark.png",
            //   width: 25,
            //   height: 25,
            //   color: theme.colorScheme.onSurfaceVariant,
            // ),
            leadingIcon: Icon(
              Icons.code_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(
                "Github",
                style: theme.textTheme.bodyLarge
              //?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            onPressed: () async {
              launchUrl(Uri.parse("https://github.com/Turtlepaw/fitness-challenges"));
            },
          )
        ],
        builder: (BuildContext context, MenuController controller,
            Widget? child) {
          return Tooltip(
            message: "App Options",
            child: IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_vert),
            ),
          );
        },
      ),
    );
  }

}