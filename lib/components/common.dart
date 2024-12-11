import 'package:flutter/material.dart';

class NewTag extends StatelessWidget {
  const NewTag({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 4, vertical: 1),
        margin: const EdgeInsets.only(left: 7),
        decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.onPrimary, size: 15),
          const SizedBox(width: 4),
          Text("NEW",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                  color:
                  theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 2),
        ]));
  }
}