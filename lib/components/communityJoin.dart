import 'package:fitness_challenges/routes/join.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

class CommunityJoinDialog extends StatefulWidget {
  final RecordModel challenge;

  const CommunityJoinDialog(
      {super.key, required this.challenge});

  @override
  _CommunityJoinDialogState createState() => _CommunityJoinDialogState();
}

class _CommunityJoinDialogState extends State<CommunityJoinDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    final pb = Provider.of<PocketBase>(context, listen: false);
    final joinCodeValue = widget.challenge.getStringValue("joinCode", null) as String?;

    return Dialog(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: (joinCodeValue == null || joinCodeValue.isEmpty) ? Column(
    mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Icon(Symbols.error_rounded, size: 40, color: theme.colorScheme.error,),
                      const SizedBox(height: 10,),
                      Text(
                        "Can't join challenge",
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        "The challenge is incorrectly setup or not closed",
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(theme.colorScheme.error),
                ),
                  onPressed: _handleClose, child: Text("OK", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onError),)),
            ],
          )
        ],
      ) :Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Icon(Symbols.login_rounded, size: 40, color: color,),
                      const SizedBox(height: 10,),
                      Text(
                        "Join \"${widget.challenge.getStringValue("name")}\"",
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              )),
          Text(
            "Everyone will see you as",
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 5),
          IntrinsicWidth(
            child: Card.outlined(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AdvancedAvatar(
                          name: pb.authStore.model?.getStringValue("username"),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.onPrimary),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          size: 35,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (pb.authStore.model as RecordModel)
                                  .getStringValue("username", "unknown"),
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(
                  onPressed: _handleClose, child: const Text("Close")),
                const SizedBox(width: 12),
              FilledButton(
                  onPressed: () async {
                    if(!_isLoading){
                      setState(() {
                        _isLoading = true;
                      });
                    }

                    final result = await handleJoin(joinCodeValue, pb, context);
                    if(!result){
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }, child: _isLoading ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeCap: StrokeCap.round, strokeWidth: 3, color: theme.colorScheme.onPrimary,),
              ) : const Text("Join"))
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
