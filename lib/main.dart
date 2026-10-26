import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:video_player/video_player.dart';
import 'package:warm_alarm/warm_alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// MODELLI DATI
// ============================================================
class Person {
  final String name;
  final int day;
  final String photoBase;
  final String audio;

  const Person({
    required this.name,
    required this.day,
    required this.photoBase,
    required this.audio,
  });
}

class MonthData {
  final String name;
  final String video;
  final List<Person> people;

  const MonthData({
    required this.name,
    required this.video,
    required this.people,
  });
}

// ============================================================
// CONFIGURAZIONE MESI E COMPLEANNI
// ============================================================
final List<MonthData> monthsData = [
  const MonthData(name: 'Gennaio', video: 'assets/gennaio.mp4', people: [
    Person(name: 'Mimoza Sulo', day: 18, photoBase: 'assets/gennaio', audio: 'assets/gennaio.mp3'),
    Person(name: 'Sherif Hita', day: 1, photoBase: 'assets/gennaio2', audio: 'assets/gennaio2.mp3'),
  ]),
  const MonthData(name: 'Febbraio', video: 'assets/febbraio.mp4', people: [
    Person(name: 'Rigels Hita', day: 18, photoBase: 'assets/febbraio', audio: 'assets/febbraio.mp3'),
  ]),
  const MonthData(name: 'Marzo', video: 'assets/marzo.mp4', people: [
    Person(name: 'Lukas Hita', day: 10, photoBase: 'assets/marzo', audio: 'assets/marzo.mp3'),
  ]),
  const MonthData(name: 'Aprile', video: 'assets/aprile.mp4', people: [
    Person(name: 'Arben Rexha', day: 5, photoBase: 'assets/aprile', audio: 'assets/aprile.mp3'),
  ]),
  const MonthData(name: 'Maggio', video: 'assets/maggio.mp4', people: []),
  const MonthData(name: 'Giugno', video: 'assets/giugno.mp4', people: [
    Person(name: 'Albion Rexha', day: 16, photoBase: 'assets/giugno', audio: 'assets/giugno.mp3'),
  ]),
  const MonthData(name: 'Luglio', video: 'assets/luglio.mp4', people: [
    Person(name: 'Arben Dosti', day: 22, photoBase: 'assets/luglio', audio: 'assets/luglio.mp3'),
  ]),
  const MonthData(name: 'Agosto', video: 'assets/agosto.mp4', people: []),
  const MonthData(name: 'Settembre', video: 'assets/settembre.mp4', people: [
    Person(name: 'Albana Rexha', day: 16, photoBase: 'assets/settembre', audio: 'assets/settembre.mp3'),
  ]),
  const MonthData(name: 'Ottobre', video: 'assets/ottobre.mp4', people: [
    Person(name: 'Ayla Rexha', day: 8, photoBase: 'assets/ottobre2', audio: 'assets/ottobre2.mp3'),
    Person(name: 'Endri Dosti', day: 20, photoBase: 'assets/ottobre', audio: 'assets/ottobre.mp3'),
  ]),
  const MonthData(name: 'Novembre', video: 'assets/novembre.mp4', people: [
    Person(name: 'Vjollca Hita', day: 11, photoBase: 'assets/novembre2', audio: 'assets/novembre2.mp3'),
    Person(name: 'Claid Dosti', day: 24, photoBase: 'assets/novembre', audio: 'assets/novembre.mp3'),
  ]),
  const MonthData(name: 'Dicembre', video: 'assets/dicembre.mp4', people: [
    Person(name: 'Amanda Rexha', day: 12, photoBase: 'assets/dicembre', audio: 'assets/dicembre.mp3'),
  ]),
];

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
      title: 'kalendar',
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
  DateTime _currentMonth = DateTime.now(); 
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAlarmsAndPermissions();
    _initVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    setState(() => _isVideoInitialized = false);
    await _videoController?.dispose();
    
    final monthIndex = _currentMonth.month - 1;
    final videoPath = monthsData[monthIndex].video;
    _videoController = VideoPlayerController.asset(videoPath);
    
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0.3);
      await _videoController!.setPlaybackSpeed(0.7);
      await _videoController!.play();
      if (mounted) setState(() => _isVideoInitialized = true);
    } catch (e) {
      debugPrint("Errore nel caricamento del video: $e");
    }
  }

  Future<void> _initAlarmsAndPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final allSavedIds = prefs.getStringList('scheduled_alarm_ids') ?? [];
    final validSavedIds = allSavedIds
        .map(int.parse)
        .where((id) => (id ~/ 100000) >= now.year)
        .toSet();

    const int yearsAhead = 5;
    int newlyScheduled = 0;

    for (int yearOffset = 0; yearOffset < yearsAhead; yearOffset++) {
      final int year = now.year + yearOffset;

      for (int m = 0; m < monthsData.length; m++) {
        final month = monthsData[m];
        for (int p = 0; p < month.people.length; p++) {
          final person = month.people[p];

          final birthdayDate = DateTime(year, m + 1, person.day);
          final today = DateTime(now.year, now.month, now.day);
          if (birthdayDate.isBefore(today)) continue;

          final alarm9 = DateTime(year, m + 1, person.day, 9, 0);
          final id9 = year * 100000 + (m + 1) * 1000 + p * 10 + 1;
          
          if (!validSavedIds.contains(id9) && alarm9.isAfter(now)) {
            await WarmAlarm.scheduleAlarm(
              WarmAlarmSchedule(
                id: id9,
                scheduledAt: alarm9,
                notification: WarmAlarmNotification(
                  title: 'Buon Compleanno!',
                  body: 'Oggi è il compleanno di ${person.name} (9:00)',
                ),
                audio: WarmAlarmAudio(assetPath: person.audio, loop: false),
              ),
            );
            validSavedIds.add(id9);
            newlyScheduled++;
          }

          final alarm10 = DateTime(year, m + 1, person.day, 10, 0);
          final id10 = year * 100000 + (m + 1) * 1000 + p * 10 + 2;
          
          if (!validSavedIds.contains(id10) && alarm10.isAfter(now)) {
            await WarmAlarm.scheduleAlarm(
              WarmAlarmSchedule(
                id: id10,
                scheduledAt: alarm10,
                notification: WarmAlarmNotification(
                  title: 'Buon Compleanno!',
                  body: 'Oggi è il compleanno di ${person.name} (10:00)',
                ),
                audio: WarmAlarmAudio(assetPath: person.audio, loop: false),
              ),
            );
            validSavedIds.add(id10);
            newlyScheduled++;
          }
        }
      }
    }

    await prefs.setStringList(
      'scheduled_alarm_ids',
      validSavedIds.map((e) => e.toString()).toList(),
    );
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + increment, 1);
    });
    _initVideo();
  }

  @override
  Widget build(BuildContext context) {
    final data = monthsData[_currentMonth.month - 1];

    return Scaffold(
      body: Stack(
        children: [
          if (_isVideoInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                return isLandscape
                    ? _buildLandscapeLayout(data)
                    : _buildPortraitLayout(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(MonthData data) {
    return Column(
      children: [
        const SizedBox(height: 8),
        if (data.people.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.people.map((p) => _buildPhotoBox(p)).toList(),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 60.0),
          child: _buildCalendar(data),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(MonthData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0, top: 8.0),
      child: Row(
        children: [
          if (data.people.isNotEmpty)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: data.people.map((p) => _buildPhotoBox(p)).toList(),
              ),
            ),
          Expanded(
            flex: 3,
            child: Center(child: _buildCalendar(data)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox(Person person) {
    const double size = 120;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _SmartImage(
              key: ValueKey(person.name),
              basePath: person.photoBase,
              size: size,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            child: Text(
              person.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(MonthData data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: _buildCalendarCells(data),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final monthName = monthsData[_currentMonth.month - 1].name.toUpperCase();
    final year = _currentMonth.year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          '$monthName $year',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 8)],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  List<Widget> _buildCalendarCells(MonthData data) {
    final now = DateTime.now();
    final viewYear = _currentMonth.year;
    final viewMonth = _currentMonth.month;
    
    final firstDay = DateTime(viewYear, viewMonth, 1);
    final daysInMonth = DateTime(viewYear, viewMonth + 1, 0).day;
    final startOffset = firstDay.weekday - 1;

    final List<Widget> cells = [];
    const weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

    for (var wd in weekdays) {
      cells.add(
        Center(
          child: Text(
            wd,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
      );
    }

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final birthdaysToday = data.people.where((p) => p.day == day).toList();
      final isBirthday = birthdaysToday.isNotEmpty;
      
      final isToday = (now.year == viewYear && now.month == viewMonth && now.day == day);

      Color cellColor = Colors.white10;
      Color borderColor = Colors.white30;
      double borderWidth = 1.0;
      Color textColor = Colors.white;

      if (isBirthday) {
        cellColor = const Color(0xFFFF8C42);
        borderColor = Colors.white;
        borderWidth = 1.5;
        textColor = Colors.black87;
      } else if (isToday) {
        cellColor = Colors.blueAccent.withOpacity(0.3);
        borderColor = Colors.blueAccent;
        borderWidth = 1.5;
        textColor = Colors.white;
      }

      Widget dayContent = Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: (isBirthday || isToday) ? 16 : 13,
            fontWeight: (isBirthday || isToday) ? FontWeight.w900 : FontWeight.w500,
            color: textColor,
          ),
        ),
      );

      // --- LOGICA DI INGRANDIMENTO ---
      // Se è oggi, lo ingrandiamo del 20%. 
      // Se è anche un compleanno, lo ingrandiamo del 10% per non coprire troppo gli altri.
      if (isToday && isBirthday) {
        dayContent = Transform.scale(scale: 1.1, child: dayContent);
      } else if (isToday) {
        dayContent = Transform.scale(scale: 1.2, child: dayContent);
      }

      if (isBirthday) {
        cells.add(BlinkingCell(child: dayContent));
      } else {
        cells.add(dayContent);
      }
    }

    return cells;
  }
}

class _SmartImage extends StatefulWidget {
  final String basePath;
  final double size;

  const _SmartImage({Key? key, required this.basePath, required this.size}) : super(key: key);

  @override
  State<_SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<_SmartImage> {
  String? _resolvedPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _findImage();
  }

  Future<void> _findImage() async {
    final extensions = ['.jpeg', '.jpg', '.png', '.JPG', '.JPEG', '.PNG'];
    for (final ext in extensions) {
      final path = '${widget.basePath}$ext';
      try {
        await rootBundle.load(path);
        if (mounted) {
          setState(() {
            _resolvedPath = path;
            _isLoading = false;
          });
        }
        return;
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        color: Colors.black26,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }
    if (_resolvedPath != null) {
      return Image.asset(
        _resolvedPath!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      );
    }
    return Container(
      width: widget.size,
      height: widget.size,
      color: Colors.grey.shade800,
      child: const Icon(Icons.person, size: 50, color: Colors.white54),
    );
  }
}

class BlinkingCell extends StatefulWidget {
  final Widget child;
  const BlinkingCell({super.key, required this.child});
  @override
  State<BlinkingCell> createState() => _BlinkingCellState();
}

class _BlinkingCellState extends State<BlinkingCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
