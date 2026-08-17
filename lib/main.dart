import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_to_foreground/app_to_foreground.dart';

void main() => runApp(const DriverApp());

@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
  ));
}

// [AS CLASSES Shift e DriverApp CONTINUAM IGUAIS, ESTOU PULARANDO PARA O OverlayWidget QUE É ONDE ESTÁ O PROBLEMA]
// Use o código abaixo no seu arquivo, mantendo o início dele exatamente como estava antes.

// ... (Mantenha Shift, DriverApp e DriverHomePage como estão) ...

// O PROBLEMA ESTÁ AQUI. Substitua todo o seu OverlayWidget por este bloco:

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  int _seconds = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && mounted) {
        final parsed = int.tryParse(data.toString());
        if (parsed != null) {
          setState(() => _seconds = parsed);
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _formatTime(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector deve envolver tudo e ter comportamento Translucent
    return GestureDetector(
      behavior: HitTestBehavior.translucent, 
      onTap: () async {
        await FlutterOverlayWindow.shareData("open_app");
        try {
          AppToForeground.appToForeground();
        } catch (_) {}
        await FlutterOverlayWindow.closeOverlay();
      },
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xF5121212),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E676), width: 2.8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "EM ROTA",
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
