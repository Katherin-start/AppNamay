import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../config/backend_config.dart';
import '../../services/storage_service.dart';

class MedicalHistoryTab extends StatefulWidget {
  const MedicalHistoryTab({Key? key}) : super(key: key);

  @override
  State<MedicalHistoryTab> createState() => _MedicalHistoryTabState();
}

class _MedicalHistoryTabState extends State<MedicalHistoryTab> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await StorageService().getAuthToken();
      if (token == null) {
        setState(() { _error = 'Sesión expirada'; _loading = false; });
        return;
      }
      final res = await http.get(
        Uri.parse(BackendConfig.mobileClinicalHistoryUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['history'] ?? []) as List;
        setState(() {
          _records = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Error al cargar el historial (${res.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final userName  = auth.profile?['nombre']?.toString() ?? 'Paciente';
    final primary   = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Historial clínico', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _records.isEmpty
                  ? _EmptyState(onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_outlined, color: primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: primary)),
                                      Text(
                                        '${_records.length} registro${_records.length != 1 ? "s" : ""} clínico${_records.length != 1 ? "s" : ""}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._records.map((r) => _RecordCard(record: r, primaryColor: primary)).toList(),
                        ],
                      ),
                    ),
    );
  }
}

class _RecordCard extends StatefulWidget {
  final Map<String, dynamic> record;
  final Color primaryColor;
  const _RecordCard({required this.record, required this.primaryColor});

  @override
  State<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard> {
  bool _expanded = false;

  String _fmtDate(dynamic raw) {
    if (raw == null) return 'Sin fecha';
    try {
      final d = DateTime.parse(raw.toString());
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  String _doctorName(dynamic odontologo) {
    if (odontologo is Map) {
      final n = odontologo['nombre']?.toString() ?? '';
      final a = odontologo['apellido']?.toString() ?? '';
      return [n, a].where((s) => s.isNotEmpty).join(' ');
    }
    return 'Dental Namay';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final tipo = r['tipo']?.toString() ?? 'Consulta';
    final fecha = _fmtDate(r['fecha']);
    final doctor = _doctorName(r['odontologo']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconForTipo(tipo), color: widget.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tipo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('$fecha  ·  $doctor',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_notEmpty(r['descripcion']))
                    _Field(label: 'Descripción', value: r['descripcion']),
                  if (_notEmpty(r['diagnostico']))
                    _Field(label: 'Diagnóstico', value: r['diagnostico']),
                  if (_notEmpty(r['tratamiento']))
                    _Field(label: 'Tratamiento', value: r['tratamiento']),
                  if (_notEmpty(r['medicamentos']))
                    _Field(label: 'Medicamentos', value: r['medicamentos']),
                  if (_notEmpty(r['notas']))
                    _Field(label: 'Notas', value: r['notas'], isLast: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _notEmpty(dynamic v) =>
      v != null && v.toString().trim().isNotEmpty;

  IconData _iconForTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('diagnos')) return Icons.medical_information;
    if (t.contains('tratam')) return Icons.medical_services;
    if (t.contains('medica')) return Icons.medication;
    if (t.contains('alerg')) return Icons.warning_amber;
    if (t.contains('cirugía') || t.contains('cirugia')) return Icons.content_cut;
    return Icons.description_outlined;
  }
}

class _Field extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool isLast;
  const _Field({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value?.toString() ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Sin registros clínicos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tu odontóloga aún no ha registrado\ninformación en tu historial',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
