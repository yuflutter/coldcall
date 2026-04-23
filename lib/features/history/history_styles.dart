import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm ');
final timeDateFormat = DateFormat('HH:mm dd.MM.yyyy');
final onlyTimeFormat = DateFormat('HH:mm');
final onlyDateFormat = DateFormat('dd.MM.yyyy');

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutesм $secondsс';
}

class TimeDateText extends StatelessWidget {
  final DateTime date;
  final double fontSize;

  const TimeDateText({super.key, required this.date, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Text(
          onlyTimeFormat.format(date),
          style: TextStyle(fontSize: fontSize, fontWeight: .bold, color: Colors.white70),
        ),
        Gap(10),
        Text(
          onlyDateFormat.format(date),
          style: TextStyle(fontSize: fontSize, color: Colors.white70),
        ),
      ],
    );
  }
}
