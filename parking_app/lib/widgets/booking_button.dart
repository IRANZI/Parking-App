import 'package:flutter/material.dart';

class BookingButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;

  const BookingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor = const Color.fromARGB(255, 111, 90, 245),
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}