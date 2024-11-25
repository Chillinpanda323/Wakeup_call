import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/audio_service.dart';

class OverlayScreen extends StatelessWidget {
  final String message;
  
  const OverlayScreen({
    Key? key, 
    this.message = 'Time\'s Up!',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AudioService.stopAlarmSound();
                await FlutterOverlayWindow.closeOverlay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
              ),
              child: const Text(
                'DISMISS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 