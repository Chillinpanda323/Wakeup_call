import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../models/alarm.dart';
import 'audio_service.dart';

class AlarmService {
  // Method to schedule a new alarm
  static Future<bool> scheduleAlarm(Alarm alarm) async {
    // Check if alarm is enabled before scheduling
    if (!alarm.isEnabled) return false;
    
    // Calculate the scheduled time for the alarm
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Calculate duration until alarm should trigger
    final Duration duration = scheduledTime.difference(now);

    // Schedule the alarm using AndroidAlarmManager
    return await AndroidAlarmManager.oneShot(
      duration,
      alarm.id,
      alarmCallback,  // Function to call when alarm triggers
      exact: true,    // Ensure alarm triggers at exact time
      wakeup: true,   // Wake device if sleeping
      rescheduleOnReboot: true,  // Persist alarm after device reboot
    );
  }

  // Method to cancel an existing alarm
  static Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
    await AudioService.stopAlarmSound();
  }

  // Method to clean up resources when app is closed
  static Future<void> dispose() async {
    await AudioService.dispose();
  }
}

// Callback function that runs when alarm triggers
@pragma('vm:entry-point')  // Required for alarm manager to call this function
void alarmCallback() async {
  try {
    // Start playing the alarm sound
    await AudioService.playAlarmSound();
    
    // Handle overlay window display
    if (await FlutterOverlayWindow.isActive()) {
      // If overlay is already showing, close it and stop sound
      await FlutterOverlayWindow.closeOverlay();
      await AudioService.stopAlarmSound();
    } else {
      // Show new overlay window
      await FlutterOverlayWindow.showOverlay(
        height: 1000, 
        width: 1000,
      );
    }
  } catch (e) {
    // Error handling
    print('Error in alarm callback: $e');
    await AudioService.stopAlarmSound();
  }
} 