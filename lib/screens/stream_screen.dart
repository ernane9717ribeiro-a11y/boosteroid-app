import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_model.dart';
import '../theme/app_theme.dart';
import '../widgets/touch_gamepad.dart';
import '../widgets/stream_player.dart';

class StreamScreen extends StatefulWidget {
  final GameModel game;
  const StreamScreen({super.key, required this.game});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  bool _showGamepad = true;
  bool _isLandscape = true;
  bool _isStreaming = false;
  bool _isConnecting = true;
  double _gamepadOpacity = 0.85;
  GamepadLayout _currentLayout = GamepadLayout.standard;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _forceLandscape();
    _simulateConnect();
  }

  void _forceLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _simulateConnect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isStreaming = true;
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Stream area
            Positioned.fill(
              child: _isConnecting
                  ? _buildConnectingScreen()
                  : StreamPlayer(game: widget.game),
            ),

            // Touch gamepad overlay
            if (_isStreaming && _showGamepad)
              FadeTransition(
                opacity: _fadeAnim,
                child: TouchGamepad(
                  opacity: _gamepadOpacity,
                  layout: _currentLayout,
                  onButtonPress: _onGamepadButtonPress,
                ),
              ),

            // Top HUD
            if (_showControls || !_isStreaming) _buildTopHUD(),

            // Gamepad settings panel (slide-in)
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.secondary, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.cloud_download, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              widget.game.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Conectando ao servidor Boosteroid...',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '🔒  Conexão segura • Baixa latência',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            _hudButton(
              icon: Icons.arrow_back,
              onTap: () => _onWillPop(),
            ),
            const SizedBox(width: 8),
            Text(
              widget.game.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (_isStreaming) ...[
              const SizedBox(width: 8),
              _buildStreamBadge(),
            ],
            const Spacer(),
            _buildLatencyIndicator(),
            const SizedBox(width: 8),
            _hudButton(
              icon: _showGamepad ? Icons.gamepad : Icons.gamepad_outlined,
              onTap: () => setState(() => _showGamepad = !_showGamepad),
              active: _showGamepad,
            ),
            const SizedBox(width: 4),
            _hudButton(
              icon: Icons.tune,
              onTap: _showGamepadSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 6),
          SizedBox(width: 3),
          Text('LIVE', style: TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800,
          )),
        ],
      ),
    );
  }

  Widget _buildLatencyIndicator() {
    return Row(
      children: [
        Icon(Icons.wifi, color: AppTheme.primary, size: 14),
        const SizedBox(width: 3),
        const Text('18ms', style: TextStyle(
          color: Colors.white70, fontSize: 11,
        )),
      ],
    );
  }

  Widget _hudButton(
      {required IconData icon, required VoidCallback onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withOpacity(0.25)
              : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppTheme.primary : Colors.white24,
            width: 0.5,
          ),
        ),
        child: Icon(icon,
            color: active ? AppTheme.primary : Colors.white70, size: 18),
      ),
    );
  }

  void _onGamepadButtonPress(String button) {
    // Haptic feedback on button press
    HapticFeedback.lightImpact();
    debugPrint('Gamepad button: $button');
    // Here you'd send the input to the stream server via WebSocket/WebRTC
  }

  void _showGamepadSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GamepadSettingsSheet(
        opacity: _gamepadOpacity,
        layout: _currentLayout,
        onOpacityChanged: (v) => setState(() => _gamepadOpacity = v),
        onLayoutChanged: (l) => setState(() => _currentLayout = l),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sair do jogo?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Seu progresso na sessão atual será perdido.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Continuar', style: TextStyle(color: AppTheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) Navigator.pop(context);
    return false;
  }
}

// ──────────────────────────────────────────────
// Gamepad Settings Sheet
// ──────────────────────────────────────────────
class _GamepadSettingsSheet extends StatelessWidget {
  final double opacity;
  final GamepadLayout layout;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<GamepadLayout> onLayoutChanged;

  const _GamepadSettingsSheet({
    required this.opacity,
    required this.layout,
    required this.onOpacityChanged,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Configurações do Controle',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          const Text('Opacidade', style: TextStyle(color: Colors.white60, fontSize: 13)),
          Slider(
            value: opacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            activeColor: AppTheme.primary,
            inactiveColor: Colors.white12,
            onChanged: onOpacityChanged,
          ),
          const SizedBox(height: 8),
          const Text('Layout', style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: GamepadLayout.values.map((l) {
              final isSelected = l == layout;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onLayoutChanged(l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      l.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? AppTheme.primary : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
