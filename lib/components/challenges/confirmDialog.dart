import 'package:flutter/material.dart';

class ConfirmDialog extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? description;
  final void Function() onConfirm;
  final bool isDestructive;

  const ConfirmDialog(
      {super.key, required this.icon, required this.title, required this.onConfirm, this.description, this.isDestructive = false});

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
                    Text(
                      widget.description!,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                ],
              )),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(
                  onPressed: _handleClose, child: const Text("Close")),
              const SizedBox(width: 12),
              FilledButton(
                  onPressed: (){
                    if(!_isLoading){
                      setState(() {
                        _isLoading = true;
                      });

                      widget.onConfirm();
                    }
                  }, child: _isLoading ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeCap: StrokeCap.round, strokeWidth: 3, color: theme.colorScheme.onPrimary,),
              ) : const Text("Confirm"))
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
