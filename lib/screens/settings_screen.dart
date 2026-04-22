import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _quality = 'Auto';
  bool _haptics = true;
  bool _showFps = true;
  bool _showPing = true;
  double _controlSize = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Streaming', [
            _dropdownTile('Qualidade de Vídeo', _quality,
                ['Auto', '720p 30fps', '1080p 60fps', '4K 60fps'],
                (v) => setState(() => _quality = v!)),
          ]),
          _section('Controles Touch', [
            _switchTile('Vibração Háptica', _haptics,
                (v) => setState(() => _haptics = v)),
            _sliderTile('Tamanho dos Controles', _controlSize, 0.6, 1.4,
                (v) => setState(() => _controlSize = v)),
          ]),
          _section('HUD', [
            _switchTile('Mostrar FPS', _showFps,
                (v) => setState(() => _showFps = v)),
            _switchTile('Mostrar Ping', _showPing,
                (v) => setState(() => _showPing = v)),
          ]),
          _section('Conta Boosteroid', [
            _infoTile('Email', 'usuario@email.com'),
            _infoTile('Plano', 'Premium'),
            ListTile(
              title: const Text('Sair da Conta',
                  style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.logout, color: Colors.red),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(title,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _switchTile(String label, bool val, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: Switch(
        value: val,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
      ),
    );
  }

  Widget _dropdownTile(String label, String val, List<String> options,
      ValueChanged<String?> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<String>(
        value: val,
        dropdownColor: AppTheme.surfaceVariant,
        style: const TextStyle(color: Colors.white),
        underline: const SizedBox(),
        onChanged: onChanged,
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
      ),
    );
  }

  Widget _sliderTile(String label, double val, double min, double max,
      ValueChanged<double> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Slider(
        value: val,
        min: min,
        max: max,
        activeColor: AppTheme.primary,
        inactiveColor: Colors.white12,
        onChanged: onChanged,
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
      trailing: Text(value, style: const TextStyle(color: Colors.white)),
    );
  }
}
