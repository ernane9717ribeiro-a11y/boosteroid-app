import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum GamepadLayout { standard, fps, racing, custom }

class TouchGamepad extends StatefulWidget {
  final double opacity;
  final GamepadLayout layout;
  final void Function(String button) onButtonPress;

  const TouchGamepad({
    super.key,
    this.opacity = 0.85,
    this.layout = GamepadLayout.standard,
    required this.onButtonPress,
  });

  @override
  State<TouchGamepad> createState() => _TouchGamepadState();
}

class _TouchGamepadState extends State<TouchGamepad> {
  // Joystick state
  Offset _leftStickPos = Offset.zero;
  Offset _rightStickPos = Offset.zero;
  bool _leftStickActive = false;
  bool _rightStickActive = false;

  // Pressed buttons
  final Set<String> _pressedButtons = {};

  void _onButtonDown(String btn) {
    HapticFeedback.lightImpact();
    setState(() => _pressedButtons.add(btn));
    widget.onButtonPress(btn);
  }

  void _onButtonUp(String btn) {
    setState(() => _pressedButtons.remove(btn));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Opacity(
      opacity: widget.opacity,
      child: Stack(
        children: [
          // ── LEFT SIDE ──
          // Left Joystick
          Positioned(
            left: 40,
            bottom: 60,
            child: _Joystick(
              key: const ValueKey('left_stick'),
              label: 'L',
              onMove: (offset) => setState(() => _leftStickPos = offset),
              onActiveChanged: (active) =>
                  setState(() => _leftStickActive = active),
            ),
          ),

          // D-Pad
          Positioned(
            left: 170,
            bottom: 120,
            child: _DPad(onPress: _onButtonDown, onRelease: _onButtonUp),
          ),

          // L1/L2 triggers
          Positioned(
            left: 20,
            top: 20,
            child: Column(
              children: [
                _TriggerButton(
                  label: 'L2',
                  onDown: () => _onButtonDown('L2'),
                  onUp: () => _onButtonUp('L2'),
                  pressed: _pressedButtons.contains('L2'),
                  color: AppTheme.secondary,
                ),
                const SizedBox(height: 6),
                _TriggerButton(
                  label: 'L1',
                  onDown: () => _onButtonDown('L1'),
                  onUp: () => _onButtonUp('L1'),
                  pressed: _pressedButtons.contains('L1'),
                  color: AppTheme.secondary,
                ),
              ],
            ),
          ),

          // ── RIGHT SIDE ──
          // Right Joystick
          Positioned(
            right: 160,
            bottom: 60,
            child: _Joystick(
              key: const ValueKey('right_stick'),
              label: 'R',
              onMove: (offset) => setState(() => _rightStickPos = offset),
              onActiveChanged: (active) =>
                  setState(() => _rightStickActive = active),
            ),
          ),

          // ABXY face buttons
          Positioned(
            right: 30,
            bottom: 80,
            child: _FaceButtons(
              onPress: _onButtonDown,
              onRelease: _onButtonUp,
              pressed: _pressedButtons,
            ),
          ),

          // R1/R2 triggers
          Positioned(
            right: 20,
            top: 20,
            child: Column(
              children: [
                _TriggerButton(
                  label: 'R2',
                  onDown: () => _onButtonDown('R2'),
                  onUp: () => _onButtonUp('R2'),
                  pressed: _pressedButtons.contains('R2'),
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 6),
                _TriggerButton(
                  label: 'R1',
                  onDown: () => _onButtonDown('R1'),
                  onUp: () => _onButtonUp('R1'),
                  pressed: _pressedButtons.contains('R1'),
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),

          // ── CENTER ──
          Positioned(
            left: size.width / 2 - 60,
            top: 20,
            child: Row(
              children: [
                _CenterButton(
                  label: '☰',
                  onDown: () => _onButtonDown('SELECT'),
                  onUp: () => _onButtonUp('SELECT'),
                  pressed: _pressedButtons.contains('SELECT'),
                ),
                const SizedBox(width: 12),
                _CenterButton(
                  label: '⊙',
                  onDown: () => _onButtonDown('HOME'),
                  onUp: () => _onButtonUp('HOME'),
                  pressed: _pressedButtons.contains('HOME'),
                  isHome: true,
                ),
                const SizedBox(width: 12),
                _CenterButton(
                  label: '▶',
                  onDown: () => _onButtonDown('START'),
                  onUp: () => _onButtonUp('START'),
                  pressed: _pressedButtons.contains('START'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Joystick Widget
// ──────────────────────────────────────────────
class _Joystick extends StatefulWidget {
  final String label;
  final ValueChanged<Offset> onMove;
  final ValueChanged<bool> onActiveChanged;

  const _Joystick({
    super.key,
    required this.label,
    required this.onMove,
    required this.onActiveChanged,
  });

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double _size = 100;
  static const double _knobSize = 44;
  Offset _knobOffset = Offset.zero;
  bool _active = false;
  Offset? _startPos;

  void _onPanStart(DragStartDetails d) {
    _startPos = d.localPosition;
    setState(() => _active = true);
    widget.onActiveChanged(true);
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_startPos == null) return;
    final delta = d.localPosition - _startPos!;
    final maxRadius = (_size - _knobSize) / 2;
    final dist = delta.distance.clamp(0, maxRadius);
    final angle = delta.direction;
    final clampedOffset = Offset(
      dist * cos(angle),
      dist * sin(angle),
    );
    setState(() => _knobOffset = clampedOffset);
    widget.onMove(clampedOffset / maxRadius);
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() {
      _knobOffset = Offset.zero;
      _active = false;
    });
    widget.onMove(Offset.zero);
    widget.onActiveChanged(false);
  }

  double cos(double angle) => angle != 0 ? (angle.cos() as double) : 0;
  double sin(double angle) => angle != 0 ? (angle.sin() as double) : 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base circle
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(_active ? 0.1 : 0.06),
                border: Border.all(
                  color: _active
                      ? AppTheme.primary.withOpacity(0.6)
                      : Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Knob
            Transform.translate(
              offset: _knobOffset,
              child: Container(
                width: _knobSize,
                height: _knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _active
                        ? [AppTheme.primary, AppTheme.secondary]
                        : [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)],
                  ),
                  boxShadow: _active
                      ? [BoxShadow(
                          color: AppTheme.primary.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )]
                      : [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on double {
  double cos() => _MathHelper.cos(this);
  double sin() => _MathHelper.sin(this);
}

class _MathHelper {
  static double cos(double angle) => _cos(angle);
  static double sin(double angle) => _sin(angle);

  static double _cos(double x) {
    // Taylor approximation or use dart:math
    return _dartCos(x);
  }

  static double _sin(double x) {
    return _dartSin(x);
  }

  static double _dartCos(double x) {
    // Use platform math
    double result = 0;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      result += term;
      term *= -x * x / ((2 * i - 1) * (2 * i));
    }
    return result;
  }

  static double _dartSin(double x) {
    double result = 0;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      result += term;
      term *= -x * x / ((2 * i) * (2 * i + 1));
    }
    return result;
  }
}

// ──────────────────────────────────────────────
// D-Pad Widget
// ──────────────────────────────────────────────
class _DPad extends StatelessWidget {
  final void Function(String) onPress;
  final void Function(String) onRelease;

  const _DPad({required this.onPress, required this.onRelease});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Up
          Positioned(
            top: 0,
            left: 30,
            child: _DPadArrow(
              direction: '↑',
              label: 'UP',
              onPress: onPress,
              onRelease: onRelease,
            ),
          ),
          // Down
          Positioned(
            bottom: 0,
            left: 30,
            child: _DPadArrow(
              direction: '↓',
              label: 'DOWN',
              onPress: onPress,
              onRelease: onRelease,
            ),
          ),
          // Left
          Positioned(
            left: 0,
            top: 30,
            child: _DPadArrow(
              direction: '←',
              label: 'LEFT',
              onPress: onPress,
              onRelease: onRelease,
            ),
          ),
          // Right
          Positioned(
            right: 0,
            top: 30,
            child: _DPadArrow(
              direction: '→',
              label: 'RIGHT',
              onPress: onPress,
              onRelease: onRelease,
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadArrow extends StatefulWidget {
  final String direction, label;
  final void Function(String) onPress;
  final void Function(String) onRelease;

  const _DPadArrow({
    required this.direction,
    required this.label,
    required this.onPress,
    required this.onRelease,
  });

  @override
  State<_DPadArrow> createState() => _DPadArrowState();
}

class _DPadArrowState extends State<_DPadArrow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onPress(widget.label);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onRelease(widget.label);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onRelease(widget.label);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _pressed
              ? AppTheme.primary.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _pressed ? AppTheme.primary : Colors.white24,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(widget.direction,
            style: TextStyle(
              color: _pressed ? AppTheme.primary : Colors.white70,
              fontSize: 14,
            )),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ABXY Face Buttons
// ──────────────────────────────────────────────
class _FaceButtons extends StatelessWidget {
  final void Function(String) onPress;
  final void Function(String) onRelease;
  final Set<String> pressed;

  const _FaceButtons({
    required this.onPress,
    required this.onRelease,
    required this.pressed,
  });

  static const _buttons = [
    {'label': 'Y', 'color': 0xFFFFD700, 'pos': 'top'},
    {'label': 'A', 'color': 0xFF00C853, 'pos': 'bottom'},
    {'label': 'X', 'color': 0xFF2196F3, 'pos': 'left'},
    {'label': 'B', 'color': 0xFFF44336, 'pos': 'right'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: _buttons.map((btn) {
          final label = btn['label'] as String;
          final color = Color(btn['color'] as int);
          final pos = btn['pos'] as String;

          Offset offset;
          switch (pos) {
            case 'top': offset = const Offset(0, -38); break;
            case 'bottom': offset = const Offset(0, 38); break;
            case 'left': offset = const Offset(-38, 0); break;
            default: offset = const Offset(38, 0);
          }

          return Transform.translate(
            offset: offset,
            child: _FaceButton(
              label: label,
              color: color,
              pressed: pressed.contains(label),
              onDown: () => onPress(label),
              onUp: () => onRelease(label),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FaceButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool pressed;
  final VoidCallback onDown, onUp;

  const _FaceButton({
    required this.label,
    required this.color,
    required this.pressed,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed ? color : color.withOpacity(0.25),
          border: Border.all(color: color.withOpacity(0.7), width: 1.5),
          boxShadow: pressed
              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: pressed ? Colors.black : color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Trigger Buttons
// ──────────────────────────────────────────────
class _TriggerButton extends StatelessWidget {
  final String label;
  final VoidCallback onDown, onUp;
  final bool pressed;
  final Color color;

  const _TriggerButton({
    required this.label,
    required this.onDown,
    required this.onUp,
    required this.pressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: pressed ? color : color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.6), width: 1),
          boxShadow: pressed
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: pressed ? Colors.black : color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Center Buttons (Start/Select/Home)
// ──────────────────────────────────────────────
class _CenterButton extends StatelessWidget {
  final String label;
  final VoidCallback onDown, onUp;
  final bool pressed;
  final bool isHome;

  const _CenterButton({
    required this.label,
    required this.onDown,
    required this.onUp,
    required this.pressed,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: isHome ? 40 : 32,
        height: isHome ? 40 : 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed
              ? (isHome ? AppTheme.primary : Colors.white24)
              : (isHome ? AppTheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.08)),
          border: Border.all(
            color: isHome ? AppTheme.primary : Colors.white30,
            width: 1.5,
          ),
          boxShadow: pressed && isHome
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 12)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: pressed ? (isHome ? Colors.black : Colors.white) : Colors.white60,
            fontSize: isHome ? 16 : 13,
          ),
        ),
      ),
    );
  }
}
