import 'package:flutter/material.dart';

class TutorialOverlay extends ModalRoute<void> {
  @override
  Duration get transitionDuration =>
      const Duration(milliseconds: 350); // Adjust duration

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {double horizontalPadding = constraints.maxWidth < 500 ? 20 : 0;
        double containerWidth = constraints.maxWidth - 2 * horizontalPadding;
        double verticalPadding = 20; // Adjust as needed
        double containerHeight = constraints.maxHeight - 2 * verticalPadding;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),child: Container(
              width: containerWidth,
              height: containerHeight, // Set calculated height
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This is a nice overlay',
                    style: TextStyle(color: Colors.white, fontSize: 30.0),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Dismiss'),
                  )
                ],
              ),
            ),
            ),
          ),
        );
        },
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade animation with longer duration
    Animation<double> fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    // Slide animation for entering
    Animation<Offset> slideInAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    // Slide animation for exiting (reversed and going further up)
    Animation<Offset> slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5), // Adjust -0.5 for desired upward distance
    ).animate(CurvedAnimation(
      parent: secondaryAnimation, // Use secondaryAnimation for exit
      curve: Curves.easeOut,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: animation.status == AnimationStatus.forward
            ? slideInAnimation
            : slideOutAnimation,
        child: child,
      ),
    );
  }
}
