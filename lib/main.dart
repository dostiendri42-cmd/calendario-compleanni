import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:video_player/video_player.dart';
import 'package:warm_alarm/warm_alarm.dart';
import 'package:permission_handler/permission_handler.dart';

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
  int _currentMonthIndex = 9; // Inizia da Ottobre
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
    
    final videoPath = monthsData[_currentMonthIndex].video;
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

    final now = DateTime.now();

    for (int m = 0; m < monthsData.length; m++) {
      final month = monthsData[m];
      for (int p = 0; p < month.people.length; p++) {
        final person = month.people[p];
        
        DateTime targetDate = DateTime(now.year, m + 1, person.day);
        
        if (targetDate.isBefore(DateTime(now.year, now.month, now.day))) {
          targetDate = DateTime(now.year + 1, m + 1, person.day);
        }

        // Sveglia alle 9:00
        final alarm9 = DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0);
        await WarmAlarm.scheduleAlarm(
          WarmAlarmSchedule(
            id: (m + 1) * 1000 + p * 10 + 1,
            scheduledAt: alarm9,
            notification: WarmAlarmNotification(
              title: 'Buon Compleanno!',
              body: 'Oggi è il compleanno di ${person.name} (9:00)',
            ),
            audio: WarmAlarmAudio(
              assetPath: person.audio,
              loop: false,
            ),
          ),
        );

        // Sveglia alle 10:00
        final alarm10 = DateTime(targetDate.year, targetDate.month, targetDate.day, 10, 0);
        await WarmAlarm.scheduleAlarm(
          WarmAlarmSchedule(
            id: (m + 1) * 1000 + p * 10 + 2,
            scheduledAt: alarm10,
            notification: WarmAlarmNotification(
              title: 'Buon Compleanno!',
              body: 'Oggi è il compleanno di ${person.name} (10:00)',
            ),
            audio: WarmAlarmAudio(
              assetPath: person.audio,
              loop: false,
            ),
          ),
        );
      }
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonthIndex = (_currentMonthIndex + increment + 12) % 12;
    });
    _initVideo();
  }

  @override
  Widget build(BuildContext context) {
    final data = monthsData[_currentMonthIndex];

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

  // ============================================================
  // LAYOUT PORTRAIT (Verticale)
  // ============================================================
  Widget _buildPortraitLayout(MonthData data) {
    return Column(
      children: [
        const SizedBox(height: 8),
        if (data.people.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.people
                .map((p) => _buildPhotoBox(p))
                .toList(),
          ),
        
        const Spacer(), 
        
        Padding(
          padding: const EdgeInsets.only(bottom: 60.0),
          child: _buildCalendar(data),
        ),
      ],
    );
  }

  // ============================================================
  // LAYOUT LANDSCAPE (Orizzontale)
  // ============================================================
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
    // Foto ingrandite: 120 invece di 90
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
            // Sfondo del calendario quasi trasparente (prima era 0.3)
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          monthsData[_currentMonthIndex].name.toUpperCase(),
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
    final year = now.year;
    final month = _currentMonthIndex + 1;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
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

      Widget dayContent = Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBirthday ? const Color(0xFFFF8C42) : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isBirthday ? Colors.white : Colors.white30,
            width: isBirthday ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: isBirthday ? 16 : 13,
            fontWeight: isBirthday ? FontWeight.w900 : FontWeight.w500,
            color: isBirthday ? Colors.black87 : Colors.white,
          ),
        ),
      );

      if (isBirthday) {
        cells.add(BlinkingCell(child: dayContent));
      } else {
        cells.add(dayContent);
      }
    }

    return cells;
  }
}

// ============================================================
// WIDGET INTELLIGENTE PER CARICARE LE IMMAGINI (ASINCRONO)
// ============================================================
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
      } catch (_) {
        // Non trovato, passa alla prossima
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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

// ============================================================
// WIDGET PER L'ANIMAZIONE DI LAMPEGGIO
// ============================================================
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
