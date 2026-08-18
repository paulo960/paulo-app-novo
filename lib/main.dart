import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_to_foreground/app_to_foreground.dart';

void main() => runApp(const DriverApp());

// Widget Principal
class DriverApp extends StatefulWidget {
  const DriverApp({super.key});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paulo Luna',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        primaryColor: const Color(0xFF00C853),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
      ),
      home: DriverHomePage(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// Entry point da Janela Flutuante Nativa
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
  ));
}

class Shift {
  String id;
  DateTime date;
  int duration;
  double km;
  double fuel;
  double gross;

  Shift({
    required this.id,
    required this.date,
    required this.duration,
    required this.km,
    required this.fuel,
    required this.gross,
  });

  double get net => gross - fuel;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'duration': duration,
        'km': km,
        'fuel': fuel,
        'gross': gross,
      };

  factory Shift.fromMap(Map<String, dynamic> map) => Shift(
        id: map['id'],
        date: DateTime.parse(map['date']),
        duration: map['duration'],
        km: (map['km'] as num).toDouble(),
        fuel: (map['fuel'] as num).toDouble(),
        gross: (map['gross'] as num).toDouble(),
      );
}

class DriverHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const DriverHomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabs;
  Timer? _timer;
  int _seconds = 0;
  bool _running = false;
  List<Shift> _shifts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 2, vsync: this);
    
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == "open_app") {
        await _closeNativeOverlay();
        try {
          AppToForeground.appToForeground();
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_running) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _showNativeOverlay();
      } else if (state == AppLifecycleState.resumed) {
        _closeNativeOverlay();
      }
    }
  }

  Future<void> _showNativeOverlay() async {
    try {
      if (await FlutterOverlayWindow.isActive()) return;
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Jornada",
        flag: OverlayFlag.defaultFlag,
        height: 220,
        width: 220,
      );
      FlutterOverlayWindow.shareData(_seconds.toString());
    } catch (_) {}
  }

  Future<void> _closeNativeOverlay() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _seconds++);
      FlutterOverlayWindow.shareData(_seconds.toString());
    });
    setState(() => _running = true);
  }

  String _formatTime(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paulo Luna')),
      body: Center(
        child: Column(
          children: [
             Text(_formatTime(_seconds), style: const TextStyle(fontSize: 40)),
             ElevatedButton(onPressed: _running ? () => setState(() => _running=false) : _start, child: Text(_running ? "Parar" : "Iniciar")),
          ]
        ),
      ),
    );
  }
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && mounted) {
        setState(() => _seconds = int.tryParse(data.toString()) ?? 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        await FlutterOverlayWindow.shareData("open_app");
      },
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: 76, height: 76,
            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            child: Center(child: Text("$_seconds", style: const TextStyle(color: Colors.white))),
          ),
        ),
      ),
    );
  }
}
