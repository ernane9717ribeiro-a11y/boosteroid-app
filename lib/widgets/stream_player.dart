import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../theme/app_theme.dart';

/// StreamPlayer handles the actual game stream rendering.
/// In production, this would use:
/// - webview_flutter for WebRTC-based stream (Boosteroid uses browser-based streaming)
/// - flutter_vlc_player for direct video stream
/// - webrtc_interface for custom WebRTC implementation
class StreamPlayer extends StatefulWidget {
  final GameModel game;
  const StreamPlayer({super.key, required this.game});

  @override
  State<StreamPlayer> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Stream stats (simulated)
  String _resolution = '1080p';
  int _fps = 60;
  int _bitrate = 35;
  int _ping = 18;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In production: replace this Container with WebView pointing to
    // https://boosteroid.com/game/stream or a custom WebRTC view
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated game screen background
          _buildFakeGameScreen(),

          // Stream quality HUD (bottom-left)
          Positioned(
            left: 8,
            bottom: 8,
            child: _buildQualityBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildFakeGameScreen() {
    // This would be replaced by WebView or VideoPlayer in production
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            AppTheme.secondary.withOpacity(0.3),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Opacity(
                opacity: _pulseAnim.value,
                child: child,
              ),
              child: Icon(
                Icons.videogame_asset,
                color: Colors.white.withOpacity(0.15),
                size: 80,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.game.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Integre WebView ou WebRTC aqui',
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statChip('$_resolution', AppTheme.primary),
          const SizedBox(width: 6),
          _statChip('${_fps}fps', Colors.greenAccent),
          const SizedBox(width: 6),
          _statChip('${_bitrate}Mbps', Colors.orangeAccent),
          const SizedBox(width: 6),
          _statChip('${_ping}ms', _ping < 30 ? Colors.greenAccent : Colors.red),
        ],
      ),
    );
  }

  Widget _statChip(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
