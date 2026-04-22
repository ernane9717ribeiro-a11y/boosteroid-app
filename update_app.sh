#!/bin/bash
# ============================================================
# update_app.sh  –  Substitui o app por WebView + controles touch
# Execute: bash update_app.sh
# ============================================================
set -e
cd ~/boosteroid_app || { echo "❌ Pasta ~/boosteroid_app não encontrada"; exit 1; }

echo "📝 Atualizando pubspec.yaml..."
cat > pubspec.yaml << 'YAML'
name: boosteroid_app
description: Boosteroid Cloud Gaming with Touch Controls
version: 1.0.0+1

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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
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
        colorScheme: const ColorScheme.dark(primary: Color(0xFF6C3FD4)),
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
  double _controlOpacity = 0.75;
  final Set<String> _pressed = {};
  Offset _leftStick = Offset.zero;
  Offset _rightStick = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Poco X7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) { setState(() => _loading = false); _injectCSS(); },
      ))
      ..loadRequest(Uri.parse('https://boosteroid.com'));
  }

  void _injectCSS() {
    _controller.runJavaScript('''
      (function() {
        var s = document.createElement('style');
        s.textContent = "header,footer,nav,[class*='banner'],[class*='cookie'],[class*='popup']{display:none!important}body{overflow:hidden!important}video{width:100vw!important;height:100vh!important;object-fit:contain!important}";
        document.head.appendChild(s);
        setTimeout(function(){
          var f=document.querySelector('[class*="fullscreen"],[aria-label*="full"],[title*="full"]');
          if(f)f.click();
        },3000);
      })();
    ''');
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 25, amplitude: 80);
    }
  }

  void _sendKey(String key, bool down) {
    _controller.runJavaScript('''
      (function(){var e=new KeyboardEvent('${down ? "keydown" : "keyup"}',{key:'$key',bubbles:true,cancelable:true});document.dispatchEvent(e);if(document.activeElement)document.activeElement.dispatchEvent(e);})();
    ''');
  }

  void _sendMouseMove(double dx, double dy) {
    if (dx.abs() < 0.08 && dy.abs() < 0.08) return;
    _controller.runJavaScript('''
      (function(){var e=new MouseEvent('mousemove',{movementX:${(dx*18).toInt()},movementY:${(dy*18).toInt()},bubbles:true});document.dispatchEvent(e);})();
    ''');
  }

  @override
  void dispose() { WakelockPlus.disable(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_loading)
          Container(color: Colors.black, child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Color(0xFF6C3FD4)),
            SizedBox(height: 16),
            Text('Conectando ao Boosteroid...', style: TextStyle(color: Colors.white70)),
          ]))),
        if (_showControls && !_loading)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _controlOpacity,
              duration: const Duration(milliseconds: 300),
              child: _GamepadOverlay(
                pressed: _pressed, leftStick: _leftStick, rightStick: _rightStick,
                onButtonDown: (b) { setState(() => _pressed.add(b)); _vibrate(); _handleDown(b); },
                onButtonUp: (b) { setState(() => _pressed.remove(b)); _handleUp(b); },
                onLeftStick: (o) { setState(() => _leftStick = o); _handleLeft(o); },
                onRightStick: (o) { setState(() => _rightStick = o); _sendMouseMove(o.dx, o.dy); },
              ),
            ),
          ),
        if (_showHUD)
          Positioned(top: 0, left: 0, right: 0,
            child: _HUDBar(
              showControls: _showControls, opacity: _controlOpacity,
              onToggleControls: () => setState(() => _showControls = !_showControls),
              onBack: () => _controller.goBack(),
              onRefresh: () { setState(() => _loading = true); _controller.reload(); },
              onOpacity: (v) => setState(() => _controlOpacity = v),
              onHide: () => setState(() => _showHUD = false),
            )),
        if (!_showHUD)
          Positioned(top: 8, right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _showHUD = true),
              child: Container(width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.menu, color: Colors.white54, size: 16)),
            )),
      ]),
    );
  }

  static const _keyMap = {
    'A':'Enter','B':'Escape','X':'x','Y':'y',
    'L1':'q','R1':'e','L2':'z','R2':'c',
    'START':'Escape','SELECT':'Tab',
    'UP':'ArrowUp','DOWN':'ArrowDown','LEFT':'ArrowLeft','RIGHT':'ArrowRight',
  };
  void _handleDown(String b) { if (_keyMap[b] != null) _sendKey(_keyMap[b]!, true); }
  void _handleUp(String b) { if (_keyMap[b] != null) _sendKey(_keyMap[b]!, false); }
  void _handleLeft(Offset o) {
    _sendKey('ArrowRight', o.dx > 0.5); _sendKey('ArrowLeft', o.dx < -0.5);
    _sendKey('ArrowDown', o.dy > 0.5); _sendKey('ArrowUp', o.dy < -0.5);
  }
}

class _HUDBar extends StatelessWidget {
  final bool showControls; final double opacity;
  final VoidCallback onToggleControls, onBack, onRefresh, onHide;
  final ValueChanged<double> onOpacity;
  const _HUDBar({required this.showControls, required this.opacity,
    required this.onToggleControls, required this.onBack,
    required this.onRefresh, required this.onOpacity, required this.onHide});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xCC000000), Colors.transparent])),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        _HBtn(Icons.arrow_back_ios, onBack),
        _HBtn(Icons.refresh, onRefresh),
        const Spacer(),
        const Icon(Icons.sports_esports, color: Color(0xFF6C3FD4), size: 16),
        const SizedBox(width: 4),
        const Text('Boosteroid', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const Spacer(),
        SizedBox(width: 80, child: Slider(value: opacity, min: 0.2, max: 1.0,
          activeColor: const Color(0xFF6C3FD4), inactiveColor: Colors.white24, onChanged: onOpacity)),
        _HBtn(showControls ? Icons.gamepad : Icons.gamepad_outlined, onToggleControls,
          color: showControls ? const Color(0xFF6C3FD4) : Colors.white54),
        _HBtn(Icons.keyboard_arrow_up, onHide),
      ]),
    );
  }
}

class _HBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final Color color;
  const _HBtn(this.icon, this.onTap, {this.color = Colors.white70});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(icon, color: color, size: 20)));
}

class _GamepadOverlay extends StatelessWidget {
  final Set<String> pressed; final Offset leftStick, rightStick;
  final void Function(String) onButtonDown, onButtonUp;
  final void Function(Offset) onLeftStick, onRightStick;
  const _GamepadOverlay({required this.pressed, required this.leftStick,
    required this.rightStick, required this.onButtonDown, required this.onButtonUp,
    required this.onLeftStick, required this.onRightStick});
  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    return Stack(children: [
      Positioned(left: 30, bottom: 40, child: _Joystick(size: 110, onMove: onLeftStick)),
      Positioned(left: 170, bottom: 50, child: _DPad(pressed: pressed, onDown: onButtonDown, onUp: onButtonUp)),
      Positioned(right: 170, bottom: 40, child: _Joystick(size: 110, onMove: onRightStick)),
      Positioned(right: 30, bottom: 50, child: _ABXYPad(pressed: pressed, onDown: onButtonDown, onUp: onButtonUp)),
      Positioned(left: 20, top: 20, child: Row(children: [
        _ShoulderBtn('L2', pressed, onButtonDown, onButtonUp),
        const SizedBox(width: 8),
        _ShoulderBtn('L1', pressed, onButtonDown, onButtonUp),
      ])),
      Positioned(right: 20, top: 20, child: Row(children: [
        _ShoulderBtn('R1', pressed, onButtonDown, onButtonUp),
        const SizedBox(width: 8),
        _ShoulderBtn('R2', pressed, onButtonDown, onButtonUp),
      ])),
      Positioned(left: s.width / 2 - 55, bottom: 18, child: Row(children: [
        _MenuBtn('SELECT', pressed, onButtonDown, onButtonUp),
        const SizedBox(width: 22),
        _MenuBtn('START', pressed, onButtonDown, onButtonUp),
      ])),
    ]);
  }
}

class _Joystick extends StatefulWidget {
  final double size; final void Function(Offset) onMove;
  const _Joystick({required this.size, required this.onMove});
  @override State<_Joystick> createState() => _JoystickState();
}
class _JoystickState extends State<_Joystick> {
  Offset _pos = Offset.zero; Offset? _origin;
  @override
  Widget build(BuildContext context) {
    final r = widget.size / 2; final kr = r * 0.38;
    return GestureDetector(
      onPanStart: (d) => _origin = d.localPosition,
      onPanUpdate: (d) {
        if (_origin == null) return;
        var delta = d.localPosition - _origin!;
        final dist = delta.distance;
        if (dist > r * 0.7) delta = delta / dist * r * 0.7;
        setState(() => _pos = delta);
        widget.onMove(Offset(delta.dx / (r * 0.7), delta.dy / (r * 0.7)));
      },
      onPanEnd: (_) { setState(() => _pos = Offset.zero); _origin = null; widget.onMove(Offset.zero); },
      child: SizedBox(width: widget.size, height: widget.size,
        child: CustomPaint(painter: _JoystickPainter(_pos, r, kr))),
    );
  }
}
class _JoystickPainter extends CustomPainter {
  final Offset pos; final double r, kr;
  _JoystickPainter(this.pos, this.r, this.kr);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withOpacity(0.08));
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final kc = c + pos;
    canvas.drawCircle(kc, kr, Paint()..color = Colors.white.withOpacity(0.35));
    canvas.drawCircle(kc, kr, Paint()..color = Colors.white.withOpacity(0.7)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }
  @override bool shouldRepaint(_JoystickPainter o) => o.pos != pos;
}

class _DPad extends StatelessWidget {
  final Set<String> pressed; final void Function(String) onDown, onUp;
  const _DPad({required this.pressed, required this.onDown, required this.onUp});
  @override
  Widget build(BuildContext context) => SizedBox(width: 90, height: 90, child: Stack(children: [
    Positioned(top: 0, left: 27, child: _DBtn('UP', Icons.keyboard_arrow_up, pressed, onDown, onUp)),
    Positioned(bottom: 0, left: 27, child: _DBtn('DOWN', Icons.keyboard_arrow_down, pressed, onDown, onUp)),
    Positioned(left: 0, top: 27, child: _DBtn('LEFT', Icons.keyboard_arrow_left, pressed, onDown, onUp)),
    Positioned(right: 0, top: 27, child: _DBtn('RIGHT', Icons.keyboard_arrow_right, pressed, onDown, onUp)),
    Positioned(left: 27, top: 27, child: Container(width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)))),
  ]));
}
class _DBtn extends StatelessWidget {
  final String label; final IconData icon; final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _DBtn(this.label, this.icon, this.pressed, this.onDown, this.onUp);
  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    return GestureDetector(
      onTapDown: (_) => onDown(label), onTapUp: (_) => onUp(label), onTapCancel: () => onUp(label),
      child: Container(width: 36, height: 36,
        decoration: BoxDecoration(color: active ? Colors.white30 : Colors.white10,
          borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, color: Colors.white70, size: 20)));
  }
}

class _ABXYPad extends StatelessWidget {
  final Set<String> pressed; final void Function(String) onDown, onUp;
  const _ABXYPad({required this.pressed, required this.onDown, required this.onUp});
  @override
  Widget build(BuildContext context) => SizedBox(width: 110, height: 110, child: Stack(children: [
    Positioned(top: 0, left: 35, child: _FaceBtn('Y', Colors.yellow, pressed, onDown, onUp)),
    Positioned(bottom: 0, left: 35, child: _FaceBtn('A', Colors.green, pressed, onDown, onUp)),
    Positioned(left: 0, top: 35, child: _FaceBtn('X', Colors.blue, pressed, onDown, onUp)),
    Positioned(right: 0, top: 35, child: _FaceBtn('B', Colors.red, pressed, onDown, onUp)),
  ]));
}
class _FaceBtn extends StatelessWidget {
  final String label; final Color color; final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _FaceBtn(this.label, this.color, this.pressed, this.onDown, this.onUp);
  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    return GestureDetector(
      onTapDown: (_) => onDown(label), onTapUp: (_) => onUp(label), onTapCancel: () => onUp(label),
      child: Container(width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: active ? color.withOpacity(0.7) : color.withOpacity(0.25),
          border: Border.all(color: color.withOpacity(0.8), width: 1.5)),
        child: Center(child: Text(label,
          style: TextStyle(color: active ? Colors.white : color, fontSize: 13, fontWeight: FontWeight.bold)))));
  }
}

class _ShoulderBtn extends StatelessWidget {
  final String label; final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _ShoulderBtn(this.label, this.pressed, this.onDown, this.onUp);
  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    return GestureDetector(
      onTapDown: (_) => onDown(label), onTapUp: (_) => onUp(label), onTapCancel: () => onUp(label),
      child: Container(width: 52, height: 32,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6C3FD4) : Colors.white12,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1)),
        child: Center(child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))));
  }
}

class _MenuBtn extends StatelessWidget {
  final String label; final Set<String> pressed;
  final void Function(String) onDown, onUp;
  const _MenuBtn(this.label, this.pressed, this.onDown, this.onUp);
  @override
  Widget build(BuildContext context) {
    final active = pressed.contains(label);
    return GestureDetector(
      onTapDown: (_) => onDown(label), onTapUp: (_) => onUp(label), onTapCancel: () => onUp(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white30 : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30, width: 1)),
        child: Text(label, style: const TextStyle(
          color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5))));
  }
}

DARTEOF
echo "main.dart escrito!"

echo ""
echo "📦 Fazendo git add e commit..."
git add -A
git commit -m "feat: WebView + native touch gamepad overlay (Opção 2)"
git push
echo ""
echo "✅ PUSH FEITO! Aguarde o GitHub Actions compilar (~5 min)"
echo "   https://github.com/ernane9717ribeiro-a11y/boosteroid-app/actions"
