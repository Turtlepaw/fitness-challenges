import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ConfirmDialog extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? description;
  final void Function()? onConfirm;
  final bool isDestructive;

  const ConfirmDialog(
      {super.key, required this.icon, required this.title, this.onConfirm, this.description, this.isDestructive = false});

  @override
  _ConfirmDialogState createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final color = switch(widget.isDestructive){
      false => theme.colorScheme.onSurface,
      true => theme.colorScheme.error,
    };
    final destructiveButtonStyle = ButtonStyle(
        backgroundColor: WidgetStateProperty.all(theme.colorScheme.error)
    );

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
                      Icon(widget.icon, size: 40, color: color,),
                      const SizedBox(height: 10,),
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
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(
                  style: widget.isDestructive ? destructiveButtonStyle : null,
                  onPressed: _handleClose, child: Text("Close", style: theme.textTheme.labelLarge?.copyWith(color: widget.isDestructive ? theme.colorScheme.onError : theme.colorScheme.onSecondaryContainer),)),
              if(widget.onConfirm != null)
                const SizedBox(width: 12),
              if(widget.onConfirm != null) FilledButton(
                style: widget.isDestructive ? destructiveButtonStyle : null,
                  onPressed: (){
                    if(!_isLoading){
                      setState(() {
                        _isLoading = true;
                      });

                      if(widget.onConfirm != null) widget.onConfirm!();
                    }
                  }, child: _isLoading ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeCap: StrokeCap.round, strokeWidth: 3, color: theme.colorScheme.onPrimary,),
              ) : Text("Confirm", style: theme.textTheme.labelLarge?.copyWith(color: widget.isDestructive ? theme.colorScheme.onError : theme.colorScheme.onPrimary),))
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
