import 'package:flutter/material.dart';

class DetectedPhone {
  final String phoneNumber;
  final String cleanNumber;
  final Rect boundingBox;

  const DetectedPhone({required this.phoneNumber, required this.cleanNumber, required this.boundingBox});
}
