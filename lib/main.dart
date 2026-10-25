import 'dart:async';
import 'package:flutter/material.dart';
import 'package:background/background.dart';
import 'package:warm_alarm/warm_alarm.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

// ============================================================
// CONFIGURAZIONE MESI
// ============================================================
final List<Map<String, dynamic>> monthsData = [
  {'name': 'Gennaio', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Febbraio', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Marzo', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Aprile', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Maggio', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Giugno', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Luglio', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Agosto', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Settembre', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Ottobre', 'person': 'Endri', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Novembre', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
  {'name': 'Dicembre', 'person': 'Nome Persona', 'birthday': 20, 'photo': 'assets/ottobre.jpeg', 'video': 'assets/ottobre.mp4'},
];

// Gli ID ora sono numeri interi, come richiesto dalla libreria
const int TEST_ALARM_ID = 1;
const int REAL_ALARM_ID = 2;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WarmAlarm.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendario Compleanni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _currentMonthIndex = 9;
  final FlutterTts _tts = FlutterTts();
  bool _alarmModalVisible = false;
  String _alarmPerson = '';

  @override
  void initState() {
    super.initState();
    _initAlarmsAndPermissions();
    _listenToAlarms();
  }

  Future<void> _initAlarmsAndPermissions() async {
    await Permission.notification.request();
    
    // Sveglia di prova: 10 secondi da adesso
    final testTime = DateTime.now().add(const Duration(seconds: 10));
    await _scheduleAlarm(
      id: TEST_ALARM_ID,
      time: testTime,
      title: 'Sveglia di prova',
      body: 'Compleanno di Endri',
    );
    
    // Sveglia reale: prossimo compleanno alle 09:00
    final now = DateTime.now();
    final currentMonth = monthsData[now.month - 1];
    DateTime targetDate = DateTime(now.year, now.month, currentMonth['birthday'], 9, 0);
    if (targetDate.isBefore(now)) {
      targetDate = DateTime(now.year + 1, now.month, currentMonth['birthday'], 9, 0);
    }
    await _scheduleAlarm(
      id: REAL_ALARM_ID,
      time: targetDate,
      title: 'Compleanno!',
      body: 'Oggi è il compleanno di ${currentMonth['person']}',
    );
  }

  Future<void> _scheduleAlarm({
    required int id, // Ora è un intero
    required DateTime time,
    required String title,
    required String body,
  }) async {
    await WarmAlarm.scheduleAlarm(
      WarmAlarmSchedule(
        id: id,
        scheduledAt: time,
        notification: WarmAlarmNotification(title: title, body: body),
        audio: const WarmAlarmAudio(loop: true),
      ),
    );
  }

  void _listenToAlarms() {
    WarmAlarm.events.listen((event) async {
      // La classe corretta è WarmAlarmFired
      if (event is WarmAlarmFired) {
        // La proprietà dell'ID è alarmId
        String person = event.alarmId == TEST_ALARM_ID
            ? 'Endri'
            : monthsData[DateTime.now().month - 1]['person'];
        setState(() {
          _alarmPerson = person;
          _alarmModalVisible = true;
        });
        await _tts.setLanguage('it-IT');
        await _tts.speak('Oggi è il compleanno di $person');
      }
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonthIndex = (_currentMonthIndex - 1 + 12) % 12;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonthIndex = (_currentMonthIndex + 1) % 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = monthsData[_currentMonthIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      body: Stack(
        children: [
          Background(path: data['video'], child: Container()),
          Positioned(
            top: isLandscape ? screenHeight * 0.2 : 30,
            left: 30,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      data['photo'],
                      width: isLandscape ? 140 : 220,
                      height: isLandscape ? 140 : 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['person'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: isLandscape ? null : 30,
            top: isLandscape ? screenHeight * 0.2 : null,
            right: 30,
            width: isLandscape ? screenWidth * 0.5 : screenWidth * 0.92,
            child: _buildCalendar(data, isLandscape),
          ),
          if (_alarmModalVisible)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD166), Color(0xFFFF8C42)]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⏰', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'Oggi è il compleanno di $_alarmPerson!',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: const Color(0xFFFFD166)),
                          onPressed: () => setState(() => _alarmModalVisible = false),
                          child: const Text('Ferma sveglia'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar(Map<String, dynamic> data, bool isLandscape) {
    final now = DateTime.now();
    final year = now.year;
    final month = _currentMonthIndex + 1;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int startOffset = firstDay.weekday - 1;

    final List<Widget> cells = [];
    const weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    for (var wd in weekdays) {
      cells.add(Container(
        alignment: Alignment.center,
        child: Text(wd, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
      ));
    }
    for (int i = 0; i < startOffset; i++) {
      cells.add(Container());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      bool isBirthday = day == data['birthday'];
      cells.add(Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBirthday ? const Color(0xFFFF8C42) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: isBirthday ? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.white30),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: isBirthday ? 18 : 16,
            fontWeight: isBirthday ? FontWeight.w800 : FontWeight.w500,
            color: isBirthday ? Colors.black87 : Colors.white,
          ),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left, color: Colors.white)),
              Text(
                '${data['name']} $year',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: cells,
          ),
        ],
      ),
    );
  }
}