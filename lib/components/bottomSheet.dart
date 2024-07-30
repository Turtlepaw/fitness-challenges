import 'dart:ui';

import 'package:flutter/material.dart';

class BottomSheetBuilder extends StatelessWidget {
  final List<Widget> children;
  final ScrollController scrollController;

  const BottomSheetBuilder({super.key, required this.children, required this.scrollController}); // Constructor with required

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          color:Theme.of(context).colorScheme.surfaceContainer
        ),
        //padding: const EdgeInsets.only(top: 20),
        child: ListView(
          controller: scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: const BorderRadius.all(Radius.circular(2.5)),
                  ),
                  child: const SizedBox(
                    height: 5,
                    width: 32,
                  ),
                ),
              ),
            ),
            ...children
          ],
        ),
      ),
    );
  }
}