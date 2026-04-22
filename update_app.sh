#!/bin/bash
# ============================================================
# update_app.sh  –  WebView + controles touch modernos (FPS fix)
# Execute: bash update_app.sh
# ============================================================
set -e
cd ~/boosteroid_app || { echo "❌ Pasta ~/boosteroid_app não encontrada"; exit 1; }

echo "📝 Atualizando pubspec.yaml..."
cat > pubspec.yaml << 'YAML'
name: boosteroid_app
description: Boosteroid Cloud Gaming with Touch Controls
version: 1.0.0+2

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.7.0
  webview_flutter_android: ^3.16.0
  vibration: ^1.9.0
  wakelock_plus: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
YAML

echo "📝 Atualizando AndroidManifest.xml..."
mkdir -p android/app/src/main
cat > android/app/src/main/AndroidManifest.xml << 'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.boosteroid_app">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <application
        android:label="Boosteroid"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:allowBackup="false"
        android:hardwareAccelerated="true"
        android:usesCleartextTraffic="true"
        android:theme="@style/LaunchTheme">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2"/>
    </application>
</manifest>
XML

echo "📝 Atualizando lib/main.dart..."
mkdir -p lib

cat > lib/main.dart << 'DARTEOF'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  WakelockPlus.enable();
  runApp(const BoosteroidApp());
}

class BoosteroidApp extends StatelessWidget {
  const BoosteroidApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boosteroid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Color(0xFF7C4DFF)),
      ),
      home: const StreamScreen(),
    );
  }
}

class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});
  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  late final WebViewController _controller;
  bool _showControls = true;
  bool _loading = true;
  bool _showHUD = true;
  double _controlOpacity = 0.80;
  final Set<String> _pressed = {};
  Offset _leftStick = Offset.zero;
  Offset _rightStick = Offset.zero;

  // JS que injeta o handler global de input no WebView
  static const String _inputBridgeJS = r"""
  (function() {
    if (window.__boosteroidBridge) return;
    window.__boosteroidBridge = true;

    // Encontra o elemento alvo: canvas, video ou body
    function getTarget() {
      return document.querySelector('canvas') ||
             document.querySelector('video') ||
             document.querySelector('[class*="stream"]') ||
             document.querySelector('[id*="stream"]') ||
             document.body;
    }

    window.__sendKey = function(key, type) {
      var t = getTarget();
      var opts = {key: key, code: key, keyCode: 0, which: 0, bubbles: true, cancelable: true, composed: true};
      var keyMap = {
        'w':87,'a':65,'s':83,'d':68,
        'ArrowUp':38,'ArrowDown':40,'ArrowLeft':37,'ArrowRight':39,
        ' ':32,'Enter':13,'Escape':27,'Tab':9,
        'Shift':16,'Control':17,'Alt':18,
        'q':81,'e':69,'r':82,'f':70,'g':71,
        'x':88,'y':89,'z':90,'c':67,'v':86
      };
      opts.keyCode = keyMap[key] || 0;
      opts.which = opts.keyCode;
      [document, t].forEach(function(el) {
        try { el.dispatchEvent(new KeyboardEvent(type, opts)); } catch(e){}
      });
    };

    window.__sendMouse = function(dx, dy) {
      var t = getTarget();
      var opts = {
        movementX: dx, movementY: dy,
        clientX: window.innerWidth/2, clientY: window.innerHeight/2,
        bubbles: true, cancelable: true, composed: true
      };
      [document, t].forEach(function(el) {
        try { el.dispatchEvent(new MouseEvent('mousemove', opts)); } catch(e){}
      });
    };

    window.__sendMouseBtn = function(type) {
      var t = getTarget();
      var opts = {button:0, buttons:1, clientX: window.innerWidth/2, clientY: window.innerHeight/2, bubbles:true, cancelable:true, composed:true};
      [document, t].forEach(function(el) {
        try { el.dispatchEvent(new MouseEvent(type, opts)); } catch(e){}
      });
    };

    // Tenta pointer lock no canvas/video para FPS
    window.__requestPointerLock = function() {
      var t = getTarget();
      if (t && t.requestPointerLock) {
        try { t.requestPointerLock(); } catch(e){}
      }
    };

    console.log('[Boosteroid Bridge] Iniciado no elemento:', getTarget()?.tagName);
  })();
  """;

  static const String _cssJS = r"""
  (function() {
    var s = document.createElement('style');
    s.textContent = "header,footer,nav,[class*='banner'],[class*='cookie'],[class*='popup'],[class*='notification']{display:none!important}body{overflow:hidden!important;margin:0!important}canvas,video{width:100vw!important;height:100vh!important;object-fit:contain!important;display:block!important}";
    document.head.appendChild(s);
    setTimeout(function(){
      var f = document.querySelector('[class*="fullscreen"],[aria-label*="full"],[title*="full"]');
      if(f) f.click();
    }, 3000);
  })();
  """;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Poco X7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) async {
          setState(() => _loading = false);
          await Future.delayed(const Duration(milliseconds: 800));
          _controller.runJavaScript(_cssJS);
          await Future.delayed(const Duration(milliseconds: 500));
          _controller.runJavaScript(_inputBridgeJS);
        },
      ))
      ..loadRequest(Uri.parse('https://boosteroid.com'));
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 20, amplitude: 100);
    }
  }

  void _sendKey(String key, bool down) {
    final type = down ? 'keydown' : 'keyup';
    _controller.runJavaScript('window.__sendKey && window.__sendKey("$key","$type");');
  }

  void _sendMouseMove(double dx, double dy) {
    if (dx.abs() < 0.06 && dy.abs() < 0.06) return;
    final mx = (dx * 22).toInt();
    final my = (dy * 22).toInt();
    _controller.runJavaScript('window.__sendMouse && window.__sendMouse($mx,$my);');
  }

  void _sendMouseBtn(bool down) {
    final t = down ? 'mousedown' : 'mouseup';
    _controller.runJavaScript('window.__sendMouseBtn && window.__sendMouseBtn("$t");');
  }

  void _requestPointerLock() {
    _controller.runJavaScript('window.__requestPointerLock && window.__requestPointerLock();');
  }

  static const _keyMap = {
    'A': 'Enter',
    'B': 'Escape',
    'X': 'r',
    'Y': 'g',
    'L1': 'q',
    'R1': 'e',
    'L2': 'Shift',
    'R2': 'FIRE',
    'START': 'Escape',
    'SELECT': 'Tab',
    'UP': 'ArrowUp',
    'DOWN': 'ArrowDown',
    'LEFT': 'ArrowLeft',
    'RIGHT': 'ArrowRight',
  };

  void _handleDown(String b) {
    if (b == 'R2') {
      _sendMouseBtn(true);
      return;
    }
    final k = _keyMap[b];
    if (k != null) _sendKey(k, true);
  }

  void _handleUp(String b) {
    if (b == 'R2') {
      _sendMouseBtn(false);
      return;
    }
    final k = _keyMap[b];
    if (k != null) _sendKey(k, false);
  }

  void _handleLeft(Offset o) {
    _sendKey('d', o.dx > 0.4);
    _sendKey('a', o.dx < -0.4);
    _sendKey('s', o.dy > 0.4);
    _sendKey('w', o.dy < -0.4);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: GestureDetector(
          onTap: _requestPointerLock,
          child: WebViewWidget(controller: _controller),
        )),
        if (_loading)
          Container(
              color: Colors.black,
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                        color: const Color(0xFF7C4DFF), strokeWidth: 3)),
                const SizedBox(height: 20),
                const Text('Conectando ao Boosteroid...',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1)),
              ]))),
        if (_showControls && !_loading)
          Positioned.fill(
              child: AnimatedOpacity(
            opacity: _controlOpacity,
            duration: const Duration(milliseconds: 300),
            child: _GamepadOverlay(
              pressed: _pressed,
              leftStick: _leftStick,
              rightStick: _rightStick,
              onButtonDown: (b) {
                setState(() => _pressed.add(b));
                _vibrate();
                _handleDown(b);
              },
              onButtonUp: (b) {
                setState(() => _pressed.remove(b));
                _handleUp(b);
              },
              onLeftStick: (o) {
                setState(() => _leftStick = o);
                _handleLeft(o);
              },
              onRightStick: (o) {
                setState(() => _rightStick = o);
                _sendMouseMove(o.dx, o.dy);
              },
            ),
          )),
        if (_showHUD)
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _HUDBar(
                showControls: _showControls,
                opacity: _controlOpacity,
                onToggleControls: () =>
                    setState(() => _showControls = !_showControls),
                onBack: () => _controller.goBack(),
                onRefresh: () {
                  setState(() => _loading = true);
                  _controller.reload();
                },
                onOpacity: (v) => setState(() => _controlOpacity = v),
                onHide: () => setState(() => _showHUD = false),
                onPointerLock: _requestPointerLock,
              )),
        if (!_showHUD)
          Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                  onTap: () => setState(() => _showHUD = true),
                  child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: const Color(0xAA000000),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                              color: const Color(0xFF7C4DFF), width: 1)),
                      child: const Icon(Icons.menu,
                          color: Colors.white70, size: 18)))),
      ]),
    );
  }
}

// ─── HUD Bar ────────────────────────────────────────────────
class _HUDBar extends StatelessWidget {
  final bool showControls;
  final double opacity;
  final VoidCallback onToggleControls, onBack, onRefresh, onHide, onPointerLock;
  final ValueChanged<double> onOpacity;
  const _HUDBar(
      {required this.showControls,
      required this.opacity,
      required this.onToggleControls,
      required this.onBack,
      required this.onRefresh,
      required this.onOpacity,
      required this.onHide,
      required this.onPointerLock});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xDD000000), Colors.transparent])),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        _HBtn(Icons.arrow_back_ios_new, onBack),
        _HBtn(Icons.refresh, onRefresh),
        _HBtn(Icons.mouse, onPointerLock, color: const Color(0xFF7C4DFF)),
        const Spacer(),
        const Icon(Icons.sports_esports, color: Color(0xFF7C4DFF), size: 14),
        const SizedBox(width: 4),
        const Text('Boosteroid',
            style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const Spacer(),
        SizedBox(
            width: 70,
            height: 28,
            child: Slider(
                value: opacity,
                min: 0.2,
                max: 1.0,
                activeColor: const Color(0xFF7C4DFF),
                inactiveColor: Colors.white12,
                onChanged: onOpacity)),
        _HBtn(
            showControls ? Icons.gamepad : Icons.gamepad_outlined,
            onToggleControls,
            color: showControls ? const Color(0xFF7C4DFF) : Colors.white38),
        _HBtn(Icons.keyboard_arrow_up, onHide),
      ]),
    );
  }
}

class _HBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _HBtn(this.icon, this.onTap, {this.color = Colors.white60});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(icon, color: color, size: 19)));
}

// ─── Gamepad Overlay ────────────────────────────────────────
class _GamepadOverlay extends StatelessWidget {
  final Set<String> pressed;
  final Offset leftStick, rightStick;
  final void Function(String) onButtonDown, onButtonUp;
  final void Function(Offset) onLeftStick, onRightStick;
  const _GamepadOverlay(
      {required this.pressed,
      required this.leftStick,
      required this.rightStick,
      required this.onButtonDown,
      required this.onButtonUp,
      required this.onLeftStick,
      required this.onRightStick});

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    return Stack(children: [
      // Left joystick (WASD)
      Positioned(
          left: 24,
          bottom: 36,
          child: _Joystick(size: 120, label: 'L', onMove: onLeftStick)),
      // D-Pad
      Positioned(
          left: 168,
          bottom: 48,
          child:
              _DPad(pressed: pressed, onDown: onButtonDown, onUp: onButtonUp)),
      // Right joystick (mouse/aim)
      Positioned(
          right: 168,
          bottom: 36,
          child: _Joystick(size: 120, label: 'R', onMove: onRightStick)),
      // ABXY
      Positioned(
          right: 24,
          bottom: 48,
          child: _ABXYPad(
              pressed: pressed, onDown: onButtonDown, onUp: onButtonUp)),
      // Shoulder L
      Positioned(
          left: 16,
          top: 50,
          child: Column(children: [
            _ShoulderBtn('L2', pressed, onButtonDown, onButtonUp),
            const SizedBox(height: 6),
            _ShoulderBtn('L1', pressed, onButtonDown, onButtonUp),
          ])),
      // Shoulder R
      Positioned(
          right: 16,
          top: 50,
          child: Column(children: [
            _ShoulderBtn('R2', pressed, onButtonDown, onButtonUp,
                highlight: true),
            const SizedBox(height: 6),
            _ShoulderBtn('R1', pressed, onButtonDown, onButtonUp),
          ])),
      // START / SELECT
      Positioned(
          left: s.width / 2 - 58,
          bottom: 14,
          child: Row(children: [
            _MenuBtn('SELECT', pressed, onButtonDown, onButtonUp),
            const SizedBox(width: 20),
            _MenuBtn('START', pressed, onButtonDown, onButtonUp),
          ])),
    ]);
  }
}

// ─── Joystick ───────────────────────────────────────────────
class _Joystick extends StatefulWidget {
  final double size;
  final String label;
  final void Function(Offset) onMove;
  const _Joystick(
      {required this.size, required this.label, required this.onMove});
  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  Offset _pos = Offset.zero;
  Offset? _origin;
  @override
  Widget build(BuildContext context) {
    final r = widget.size / 2;
    final kr = r * 0.36;
    return GestureDetector(
      onPanStart: (d) => _origin = d.localPosition,
      onPanUpdate: (d) {
        if (_origin == null) return;
        var delta = d.localPosition - _origin!;
        final dist = delta.distance;
        final maxR = r * 0.65;
        if (dist > maxR) delta = delta / dist * maxR;
        setState(() => _pos = delta);
        widget.onMove(Offset(delta.dx / maxR, delta.dy / maxR));
      },
      onPanEnd: (_) {
        setState(() => _pos = Offset.zero);
        _origin = null;
        widget.onMove(Offset.zero);
      },
      child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
              painter: _JoystickPainter(_pos, r, kr, widget.label))),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset pos;
  final double r, kr;
  final String label;
  _JoystickPainter(this.pos, this.r, this.kr, this.label);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(r, r);
    // Outer ring glow
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFF7C4DFF).withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Outer ring
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFF7C4DFF).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Inner base
    canvas.drawCircle(
        c,
        r * 0.55,
        Paint()..color = Colors.white.withOpacity(0.04));
    // Knob shadow
    final kc = c + pos;
    canvas.drawCircle(
        kc + const Offset(2, 3),
        kr,
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Knob
    final knobPaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF9E6FFF),
        const Color(0xFF5B2FCC),
      ]).createShader(Rect.fromCircle(center: kc, radius: kr));
    canvas.drawCircle(kc, kr, knobPaint);
    canvas.drawCircle(
        kc,
        kr,
        Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // Label
    final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_JoystickPainter o) => o.pos != pos;
}

// ─── D-Pad ──────────────────────────────────────────────────
class _DPad extends StatelessWidget {
  final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _DPad(
      {required this.pressed, required this.onDown, required this.onUp});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 96, height: 96, child: Stack(children: [
    Positioned(top: 0, left: 30, child: _DBtn('UP', Icons.keyboard_arrow_up, pressed, onDown, onUp)),
    Positioned(bottom: 0, left: 30, child: _DBtn('DOWN', Icons.keyboard_arrow_down, pressed, onDown, onUp)),
    Positioned(left: 0, top: 30, child: _DBtn('LEFT', Icons.keyboard_arrow_left, pressed, onDown, onUp)),
    Positioned(right: 0, top: 30, child: _DBtn('RIGHT', Icons.keyboard_arrow_right, pressed, onDown, onUp)),
    Positioned(left: 30, top: 30, child: Container(width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4)))),
  ]));
}

class _DBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _DBtn(this.label, this.icon, this.pressed, this.onDown, this.onUp);

  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    return GestureDetector(
        onTapDown: (_) => onDown(label),
        onTapUp: (_) => onUp(label),
        onTapCancel: () => onUp(label),
        child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF7C4DFF).withOpacity(0.6)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: active
                        ? const Color(0xFF7C4DFF)
                        : Colors.white.withOpacity(0.15),
                    width: 1)),
            child: Icon(icon,
                color: active ? Colors.white : Colors.white54, size: 20)));
  }
}

// ─── ABXY ───────────────────────────────────────────────────
class _ABXYPad extends StatelessWidget {
  final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _ABXYPad(
      {required this.pressed, required this.onDown, required this.onUp});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 116, height: 116, child: Stack(children: [
    Positioned(top: 0, left: 37, child: _FaceBtn('Y', const Color(0xFFFFD600), pressed, onDown, onUp)),
    Positioned(bottom: 0, left: 37, child: _FaceBtn('A', const Color(0xFF00E676), pressed, onDown, onUp)),
    Positioned(left: 0, top: 37, child: _FaceBtn('X', const Color(0xFF2979FF), pressed, onDown, onUp)),
    Positioned(right: 0, top: 37, child: _FaceBtn('B', const Color(0xFFFF1744), pressed, onDown, onUp)),
  ]));
}

class _FaceBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _FaceBtn(this.label, this.color, this.pressed, this.onDown, this.onUp);

  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    return GestureDetector(
        onTapDown: (_) => onDown(label),
        onTapUp: (_) => onUp(label),
        onTapCancel: () => onUp(label),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    active ? color.withOpacity(0.85) : color.withOpacity(0.15),
                border:
                    Border.all(color: color.withOpacity(0.7), width: 1.5),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2)
                      ]
                    : null),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        color: active ? Colors.white : color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)))));
  }
}

// ─── Shoulder Buttons ───────────────────────────────────────
class _ShoulderBtn extends StatelessWidget {
  final String label;
  final Set<String> pressed;
  final void Function(String) onDown, onUp;
  final bool highlight;
  const _ShoulderBtn(this.label, this.pressed, this.onDown, this.onUp,
      {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    final baseColor =
        highlight ? const Color(0xFFFF1744) : const Color(0xFF7C4DFF);
    return GestureDetector(
        onTapDown: (_) => onDown(label),
        onTapUp: (_) => onUp(label),
        onTapCancel: () => onUp(label),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 58,
            height: 34,
            decoration: BoxDecoration(
                color: active ? baseColor : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: active ? baseColor : Colors.white.withOpacity(0.2),
                    width: 1.2),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: baseColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1)
                      ]
                    : null),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)))));
  }
}

// ─── Menu Buttons ───────────────────────────────────────────
class _MenuBtn extends StatelessWidget {
  final String label;
  final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _MenuBtn(this.label, this.pressed, this.onDown, this.onUp);

  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    return GestureDetector(
        onTapDown: (_) => onDown(label),
        onTapUp: (_) => onUp(label),
        onTapCancel: () => onUp(label),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF7C4DFF).withOpacity(0.7)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? const Color(0xFF7C4DFF)
                        : Colors.white.withOpacity(0.2),
                    width: 1)),
            child: Text(label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1))));
  }
}
DARTEOF

echo "main.dart escrito!"
echo ""
echo "📦 Fazendo git add e commit..."
git add -A
git commit -m "fix: eventos FPS corrigidos + gamepad moderno com pointer lock"
git push
echo ""
echo "✅ PUSH FEITO! Aguarde o GitHub Actions compilar (~5 min)"
echo "   https://github.com/ernane9717ribeiro-a11y/boosteroid-app/actions"
