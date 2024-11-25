import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LoadingDialog extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? description;
  final void Function()? onConfirm;
  final bool isDestructive;

  const LoadingDialog(
      {super.key, required this.icon, required this.title, this.onConfirm, this.description, this.isDestructive = false});

  @override
  _LoadingDialogState createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Dialog(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10).add(
                EdgeInsets.all(15)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      //Icon(widget.icon, size: 40,),
                      const CircularProgressIndicator(strokeCap: StrokeCap.round),
                      const SizedBox(height: 15,),
                      Text(
                        widget.title,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  if (widget.description != null)
                    const SizedBox(height: 3,),
                  if (widget.description != null)
                    MarkdownBody(
                      data: widget.description!,
                      styleSheet: MarkdownStyleSheet(
                        p: theme.textTheme.bodyLarge,
                        textAlign: WrapAlignment.center,
                      ),
                      // style: theme.textTheme.bodyLarge,
                      // textAlign: TextAlign.center,
                    ),
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
