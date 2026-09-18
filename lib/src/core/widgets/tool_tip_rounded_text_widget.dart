import 'package:flutter/material.dart';

class ToolTipRoundedText extends StatelessWidget {
  final String text;
  final String tip;
  final Color? colour;

  const ToolTipRoundedText({
    super.key,
    required this.text,
    required this.tip,
    this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55.0,
      height: 70.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Material(
          elevation: 5.0,
          color: colour ?? Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.all(Radius.circular(100.0)),
          child: Tooltip(
            message: tip,
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
