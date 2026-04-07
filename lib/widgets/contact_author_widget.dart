import 'dart:async';

import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactAuthorWidget extends StatefulWidget {
  const ContactAuthorWidget({super.key});

  @override
  State<ContactAuthorWidget> createState() => _ContactAuthorWidgetState();
}

class _ContactAuthorWidgetState extends State<ContactAuthorWidget> {
  var _isAuthorPlateExpanded = false;
  Timer? _authorPlateTimer;

  @override
  void dispose() {
    _authorPlateTimer?.cancel();
    super.dispose();
  }

  void _contactTheAuthor() {
    setState(() {
      _isAuthorPlateExpanded = true;
    });

    // Clipboard.setData(const ClipboardData(text: authorPhoneClean));
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text(authorContact, textAlign: .center),
    //     duration: Duration(seconds: 2),
    //     behavior: SnackBarBehavior.floating,
    //   ),
    // );

    launchUrlString(di<AppConfig>().authorContact, mode: .externalApplication);

    // Схлопываем плашку через таймаут
    _authorPlateTimer?.cancel();
    _authorPlateTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() {
          _isAuthorPlateExpanded = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _contactTheAuthor,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isAuthorPlateExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite_border, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text('Связаться с автором', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  di<AppConfig>().authorContact,
                  style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
