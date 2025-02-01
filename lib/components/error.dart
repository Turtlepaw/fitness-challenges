import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

enum ErrorMessages { noHealthConnected }

final errorMessages = {
  ErrorMessages.noHealthConnected:
      "You must connect a health platform before creating or joining a challenge"
};

class ErrorMessage extends StatelessWidget {
  final String title;
  final Function(ThemeData theme)? action;
  const ErrorMessage({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Symbols.error_circle_rounded,
              color: theme.colorScheme.error,
              size: 45,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (action != null) action!(theme),
          ],
        ),
      ),
    );
  }
}
