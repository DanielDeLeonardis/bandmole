import 'package:flutter/material.dart';

class ToolTipRaisedButton extends StatelessWidget {
  final String tip;
  final Function? onPressed;
  final Icon icon;
  final Color? colour;

  const ToolTipRaisedButton({
    super.key,
    required this.tip,
    required this.onPressed,
    required this.icon,
    this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colour ?? Theme.of(context).primaryColor,
        ),
        onPressed: onPressed == null ? null : () => onPressed!(),
        child: icon,
      ),
    );
  }
}
