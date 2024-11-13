import 'package:fitness_challenges/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

String getUsernameFromUser(RecordModel user){
  final hideUsername = user.getBoolValue("hideUsernameInCommunity", false);
  if(hideUsername){
    return "User ${user.id}";
  } else {
    return user.getStringValue("username", "User ${user.id}");
  }
}

class UserPreview extends StatelessWidget {
  final bool forceRandomUsername;

  const UserPreview({super.key, this.forceRandomUsername = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pb = Provider.of<PocketBase>(context, listen: false);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AdvancedAvatar(
                  name: getUsernameFromUser(pb.authStore.model!),
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
                      trimString(getUsernameFromUser(pb.authStore.model!), 15),
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
    );
  }
}