import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

const String kPrefChatSound = 'pref_chat_sound';
const String kPrefChatVibration = 'pref_chat_vibration';
const String kPrefAppointmentAlerts = 'pref_appointment_alerts';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _storage = StorageService();
  bool _loading = true;
  bool _chatSound = true;
  bool _chatVibration = true;
  bool _appointmentAlerts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chatSound = await _storage.getBoolPref(kPrefChatSound);
    final chatVibration = await _storage.getBoolPref(kPrefChatVibration);
    final appointmentAlerts = await _storage.getBoolPref(kPrefAppointmentAlerts);
    if (!mounted) return;
    setState(() {
      _chatSound = chatSound;
      _chatVibration = chatVibration;
      _appointmentAlerts = appointmentAlerts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Controla qué alertas quieres recibir dentro de la app.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Sonido de chat',
                    subtitle: 'Reproducir un sonido al recibir mensajes nuevos',
                    value: _chatSound,
                    onChanged: (v) async {
                      setState(() => _chatSound = v);
                      await _storage.setBoolPref(kPrefChatSound, v);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    icon: Icons.vibration,
                    title: 'Vibración',
                    subtitle: 'Vibrar al recibir mensajes nuevos',
                    value: _chatVibration,
                    onChanged: (v) async {
                      setState(() => _chatVibration = v);
                      await _storage.setBoolPref(kPrefChatVibration, v);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    icon: Icons.event_available_outlined,
                    title: 'Alertas de citas',
                    subtitle: 'Avisos sobre confirmaciones y cambios de tus citas',
                    value: _appointmentAlerts,
                    onChanged: (v) async {
                      setState(() => _appointmentAlerts = v);
                      await _storage.setBoolPref(kPrefAppointmentAlerts, v);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 19, color: primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: primary,
    );
  }
}
