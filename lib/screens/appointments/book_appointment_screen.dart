import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({Key? key}) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String _consultationReason = '';
  Map<String, dynamic>? _selectedDentist;
  Map<String, dynamic>? _selectedDiscount;
  Future<List<Map<String, dynamic>>>? _odontologosFuture;
  Future<List<Map<String, dynamic>>>? _discountsFuture;
  bool _odontologosFutureInitialized = false;

  final List<String> _times = [
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
    '08:30 PM',
  ];

  void _onConfirm() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un horario antes de confirmar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Aquí podrías enviar la petición al backend para crear la cita
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cita confirmada: ${_selectedDate.toLocal()} ${_selectedTime!}'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_odontologosFutureInitialized) {
      _odontologosFuture = Provider.of<AuthProvider>(context, listen: false).fetchOdontologos();
      _odontologosFutureInitialized = true;
    }
    _discountsFuture ??= Provider.of<AuthProvider>(context, listen: false).fetchDiscounts();
  }

  Widget _buildDentistCard(Map<String, dynamic> dentist, bool selected) {
    final foto = dentist['foto_perfil']?.toString();
    final nombre = dentist['nombre']?.toString() ?? 'Odontólogo';
    final especialidad = dentist['especialidad']?.toString() ?? dentist['especialidad_nombre']?.toString() ?? dentist['rol']?.toString() ?? '';

    return GestureDetector(
      onTap: () => setState(() => _selectedDentist = dentist),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade200,
              foregroundImage: foto != null && foto.isNotEmpty ? NetworkImage(foto) : null,
              child: foto == null || foto.isEmpty
                ? const Icon(Icons.person, color: Color(0xFF4F46E5))
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (especialidad.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(especialidad, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  String _formatDiscountValue(Map<String, dynamic> discount) {
    final tipo = discount['tipo']?.toString().toLowerCase() ?? '';
    final valor = double.tryParse(discount['valor']?.toString() ?? '') ?? 0.0;
    if (tipo.contains('porcentaje')) {
      return '${valor.toStringAsFixed(valor.truncateToDouble() == valor ? 0 : 1)}%';
    }
    return '\$${valor.toStringAsFixed(valor.truncateToDouble() == valor ? 0 : 2)}';
  }

  double _computeDiscountAmount(double basePrice, Map<String, dynamic> discount) {
    final tipo = discount['tipo']?.toString().toLowerCase() ?? '';
    final valor = double.tryParse(discount['valor']?.toString() ?? '') ?? 0.0;
    if (tipo.contains('porcentaje')) {
      return basePrice * valor / 100.0;
    }
    return valor;
  }

  String _formatDateRange(Map<String, dynamic> discount) {
    final start = discount['fecha_inicio']?.toString();
    final end = discount['fecha_fin']?.toString();
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      return '$start - $end';
    }
    if (start != null && start.isNotEmpty) return 'Desde $start';
    if (end != null && end.isNotEmpty) return 'Hasta $end';
    return 'Vigencia desconocida';
  }

  Widget _buildDiscountCard(Map<String, dynamic> discount, bool selected) {
    final label = _formatDiscountValue(discount);
    final range = _formatDateRange(discount);
    final titulo = discount['nombre']?.toString() ?? 'Descuento';
    final descripcion = discount['descripcion']?.toString() ?? '';

    return GestureDetector(
      onTap: () => setState(() => _selectedDiscount = discount),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (descripcion.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                descripcion,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              range,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final userName = profile?['nombre']?.toString() ?? auth.userEmail ?? 'Usuario';
    final String? profileSpecialistNameRaw = profile?['especialistaNombre']?.toString() ?? profile?['doctorNombre']?.toString();
    final String? profileSpecialistSpecialtyRaw = profile?['especialistaEspecialidad']?.toString() ?? profile?['doctorEspecialidad']?.toString();
    final selectedDentist = _selectedDentist;
    final String? selectedDentistName = selectedDentist?['nombre']?.toString() ?? profileSpecialistNameRaw;
    final String? selectedDentistSpecialty = selectedDentist?['especialidad']?.toString() ??
        selectedDentist?['rol']?.toString() ?? profileSpecialistSpecialtyRaw;
    final hasSelectedDentist = selectedDentistName != null && selectedDentistName.isNotEmpty;
    final specialistName = hasSelectedDentist
        ? selectedDentistName!
        : 'No se encuentra especialista hasta el momento';
    final String? specialistSpecialty = hasSelectedDentist ? selectedDentistSpecialty : null;
    const basePrice = 45.0;
    final selectedDiscount = _selectedDiscount;
    final discountAmount = selectedDiscount != null ? _computeDiscountAmount(basePrice, selectedDiscount) : 0.0;
    final totalPrice = (basePrice - discountAmount).clamp(0.0, double.infinity);
    final discountLabel = selectedDiscount != null ? _formatDiscountValue(selectedDiscount) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar cita'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reserva tu cita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Calendario simple
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () => _changeMonth(-1),
                              ),
                              Text(
                                '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => _changeMonth(1),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today_outlined),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 0)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => _selectedDate = d);
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 0)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateChanged: (d) => setState(() => _selectedDate = d),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text('Odontólogos disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _odontologosFuture ??= Provider.of<AuthProvider>(context, listen: false).fetchOdontologos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Error al cargar odontólogos: ${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                    );
                  }

                  final odontologos = snapshot.data ?? [];
                  if (odontologos.isEmpty) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No hay odontólogos disponibles por ahora.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: odontologos.map((doc) {
                      final selected = _selectedDentist != null && _selectedDentist!['email'] == doc['email'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildDentistCard(doc, selected),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 16),
              const Text('Descuentos disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _discountsFuture ??= Provider.of<AuthProvider>(context, listen: false).fetchDiscounts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Error al cargar descuentos: ${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                    );
                  }

                  final discounts = snapshot.data ?? [];
                  if (discounts.isEmpty) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No hay descuentos disponibles por ahora.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: discounts.map((discount) {
                      final selected = _selectedDiscount != null && _selectedDiscount!['id'] == discount['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildDiscountCard(discount, selected),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Horarios disponibles
              const Text('Horarios disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times.map((t) {
                  final selected = t == _selectedTime;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = t),
                    child: SizedBox(
                      width: 128,
                      height: 44,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            color: selected ? Theme.of(context).colorScheme.primary : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Text('Motivo de la consulta', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                onChanged: (value) => setState(() => _consultationReason = value),
                decoration: InputDecoration(
                  hintText: 'Describe brevemente el motivo de tu consulta',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 16),

              // Resumen
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen de la cita', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Procedimiento'),
                          Text('Consulta General'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fecha'),
                          Text('${_selectedDate.day} ${_monthName(_selectedDate.month)}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: Text('Motivo')),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _consultationReason.isEmpty ? 'No definido' : _consultationReason,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (selectedDiscount != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Descuento'),
                            Text(
                              '-$discountLabel',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total'),
                            Text(
                              '\$${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Inversión'),
                            const Text('\$45.00'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirmar Cita', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = ['','Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    return names[m];
  }

  void _changeMonth(int delta) {
    setState(() {
      final y = _selectedDate.year;
      final m = _selectedDate.month + delta;
      final newDate = DateTime(y, m, 1);
      final lastDay = DateTime(newDate.year, newDate.month + 1, 0).day;
      final newDay = math.min(_selectedDate.day, lastDay);
      _selectedDate = DateTime(newDate.year, newDate.month, newDay);
    });
  }
}
