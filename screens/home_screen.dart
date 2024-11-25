import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import 'times_up_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Alarm> _alarmsBox;
  List<Alarm> _alarms = [];
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    _alarmsBox = await Hive.openBox<Alarm>('alarms');
    setState(() {
      _alarms = _alarmsBox.values.toList();
      _nextId = _alarms.isEmpty ? 0 : _alarms.map((e) => e.id).reduce(max) + 1;
    });

    // Reschedule enabled alarms
    for (var alarm in _alarms) {
      if (alarm.isEnabled) {
        await AlarmService.scheduleAlarm(alarm);
      }
    }
  }

  Future<(TimeOfDay?, String?)?> _showTimeAndMessageDialog({
    TimeOfDay? initialTime,
    String initialMessage = 'Time\'s Up!'
  }) async {
    final TextEditingController messageController = TextEditingController(text: initialMessage);
    TimeOfDay? selectedTime = initialTime ?? TimeOfDay.now();

    final result = await showDialog<(TimeOfDay?, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Alarm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time Picker Button
            ListTile(
              title: Text(
                'Time: ${selectedTime?.format(context)}',
                style: const TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  selectedTime = picked;
                  // Rebuild the dialog
                  Navigator.of(context).pop((picked, messageController.text));
                  _showTimeAndMessageDialog(
                    initialTime: picked,
                    initialMessage: messageController.text,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            // Message Input
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Alarm Message',
                hintText: 'Enter alarm message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              (selectedTime, messageController.text),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return result;
  }

  Future<void> _addAlarm() async {
    final result = await _showTimeAndMessageDialog();
    
    if (result != null) {
      final (selectedTime, message) = result;
      
      if (selectedTime != null) {
        final now = DateTime.now();
        final alarmTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        final newAlarm = Alarm(
          id: _nextId++,
          time: alarmTime,
          message: message ?? 'Time\'s Up!',
        );
        
        await AlarmService.scheduleAlarm(newAlarm);

        // Save to Hive
        await _alarmsBox.add(newAlarm);

        setState(() {
          _alarms.add(newAlarm);
        });
      }
    }
  }

  Future<void> _editAlarm(Alarm alarm) async {
    final result = await _showTimeAndMessageDialog(
      initialTime: TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute),
      initialMessage: alarm.message,
    );
    
    if (result != null) {
      final (selectedTime, newMessage) = result;
      
      if (selectedTime != null) {
        await AlarmService.cancelAlarm(alarm.id);
        
        final now = DateTime.now();
        final newTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          alarm.time = newTime;
          alarm.message = newMessage ?? 'Time\'s Up!';
        });

        // Update in Hive
        final index = _alarmsBox.values.toList().indexWhere((a) => a.id == alarm.id);
        await _alarmsBox.putAt(index, alarm);

        if (alarm.isEnabled) {
          await AlarmService.scheduleAlarm(alarm);
        }
      }
    }
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    await AlarmService.cancelAlarm(alarm.id);
    
    // Delete from Hive
    final index = _alarmsBox.values.toList().indexWhere((a) => a.id == alarm.id);
    await _alarmsBox.deleteAt(index);

    setState(() {
      _alarms.removeWhere((a) => a.id == alarm.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm App'),
      ),
      body: ListView.builder(
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return Dismissible(
            key: Key(alarm.id.toString()),
            onDismissed: (direction) => _deleteAlarm(alarm),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                onTap: () => _editAlarm(alarm),
                title: Text(
                  '${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 24),
                ),
                trailing: Switch(
                  value: alarm.isEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      alarm.isEnabled = value;
                    });

                    // Update in Hive
                    final index = _alarmsBox.values.toList().indexWhere((a) => a.id == alarm.id);
                    await _alarmsBox.putAt(index, alarm);

                    if (value) {
                      await AlarmService.scheduleAlarm(alarm);
                    } else {
                      await AlarmService.cancelAlarm(alarm.id);
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add),
      ),
    );
  }
} 