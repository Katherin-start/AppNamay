import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';

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
  int _activeStep = 0;
  String _selectedPaymentMethod = 'Yape';
  File? _paymentScreenshot;
  bool _isPickingScreenshot = false;

  final List<String> _times = [
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
    '08:30 PM',
    '09:00 PM',
  ];

  final List<String> _reasons = [
    'Control de rutina',
    'Consulta por dolor dental',
    'Revisión preventiva',
    'Tratamiento de caries',
    'Otro',
  ];
  int _selectedReasonIndex = 0;

  bool _isSelectedDateToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool _isTimeBeforeNow(String time12h) {
    if (!_isSelectedDateToday()) return false;

    final parts = time12h.split(' ');
    final hourMinute = parts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final amPm = parts[1];

    if (amPm == 'PM' && hour != 12) {
      hour += 12;
    } else if (amPm == 'AM' && hour == 12) {
      hour = 0;
    }

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    return selectedDateTime.isBefore(now);
  }

  void _onConfirm() async {
    if (_selectedDentist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un especialista antes de confirmar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un horario antes de confirmar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Usar AppointmentProvider para crear cita
    if (!mounted) return;
    
    final appointmentProvider = Provider.of<AppointmentProvider>(
      context,
      listen: false,
    );

    final fecha = '${_selectedDate.year.toString().padLeft(4, '0')}'
        '-${_selectedDate.month.toString().padLeft(2, '0')}'
        '-${_selectedDate.day.toString().padLeft(2, '0')}';

    // Extraer hora en formato 24h (ej: "16:00")
    final timeList = _selectedTime!.split(':');
    int hour = int.parse(timeList[0]);
    final minute = timeList[1].split(' ')[0];
    
    // Si es PM, sumar 12 (excepto si es 12:00 PM)
    if (_selectedTime!.contains('PM') && hour != 12) {
      hour += 12;
    } else if (_selectedTime!.contains('AM') && hour == 12) {
      hour = 0;
    }
    
    final formattedHour = hour.toString().padLeft(2, '0');
    final hora = '$formattedHour:$minute';

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await appointmentProvider.createAppointment(
        fecha: fecha,
        hora: hora,
        idOdontologo: _selectedDentist!['id'] ?? '',
        nombreOdontologo: _selectedDentist!['nombre'] ?? 'Odontólogo',
        monto: 100.0,
        metodoPago: _selectedPaymentMethod,
        servicio: _selectedDiscount != null
            ? _selectedDiscount!['nombre']?.toString() ?? 'Cita'
            : 'Cita',
        descripcion: _consultationReason.isNotEmpty ? _consultationReason : null,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cita confirmada: $fecha $hora ✅',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(); // Volver a pantalla anterior
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cita guardada localmente. Se sincronizará cuando haya conexión. ⚠️',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showStepError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _onNextStep() {
    if (_activeStep == 0 && _selectedDentist == null) {
      _showStepError('Selecciona un especialista antes de continuar.');
      return;
    }
    if (_activeStep == 2 && _selectedTime == null) {
      _showStepError('Selecciona un horario antes de continuar.');
      return;
    }
    if (_activeStep == 2 && _selectedTime != null && _isTimeBeforeNow(_selectedTime!)) {
      _showStepError('Selecciona un horario válido que no haya pasado.');
      return;
    }
    if (_activeStep == 3 && _reasons[_selectedReasonIndex] == 'Otro' && _consultationReason.trim().isEmpty) {
      _showStepError('Escribe el motivo de tu consulta.');
      return;
    }
    if (_activeStep == 4 && _selectedPaymentMethod == 'Yape' && _paymentScreenshot == null) {
      _showStepError('Selecciona la captura de pantalla del pago para continuar.');
      return;
    }
    setState(() => _activeStep = math.min(5, _activeStep + 1));
  }

  Future<void> _pickPaymentScreenshot() async {
    if (_isPickingScreenshot) return;
    setState(() => _isPickingScreenshot = true);
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _paymentScreenshot = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar captura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingScreenshot = false);
    }
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
          color: selected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade100,
              foregroundImage: foto != null && foto.isNotEmpty ? NetworkImage(foto) : null,
              child: foto == null || foto.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF4F46E5), size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (especialidad.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(especialidad, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Disponible hoy',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Especialista', 'Fecha', 'Horario', 'Motivo', 'Pago', 'Confirmar'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final connectorIndex = index ~/ 2;
            final isCompleted = connectorIndex < _activeStep;
            return Container(
              width: 32,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isActive = stepIndex == _activeStep;
          final isCompleted = stepIndex < _activeStep;
          return GestureDetector(
            onTap: () {
              if (stepIndex > 0 && _selectedDentist == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona un especialista antes de avanzar.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              setState(() => _activeStep = stepIndex);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 78,
                    child: Text(
                      steps[stepIndex],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _dentistIsAvailable(Map<String, dynamic> dentist) {
    final possibleKeys = ['disponible', 'activo', 'status', 'estado', 'available', 'is_available', 'isActive'];
    for (final key in possibleKeys) {
      if (!dentist.containsKey(key)) continue;
      final value = dentist[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final lower = value.toString().toLowerCase();
      if (['true', '1', 'activo', 'disponible', 'available', 'sí', 'si', 'yes', 'on'].contains(lower)) {
        return true;
      }
      if (['false', '0', 'inactivo', 'no', 'unavailable', 'off', 'deshabilitado'].contains(lower)) {
        return false;
      }
    }
    return true;
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
              const SizedBox(height: 14),
              _buildStepIndicator(),
              const SizedBox(height: 18),
              if (_activeStep == 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Buscar especialista o área',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Icon(Icons.filter_list, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                    final disponibles = odontologos.where(_dentistIsAvailable).toList();
                    if (disponibles.isEmpty) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No hay especialistas disponibles cargados por ahora.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: disponibles.map((doc) {
                        final selected = _selectedDentist != null &&
                            _selectedDentist!['id'] != null &&
                            doc['id'] != null &&
                            _selectedDentist!['id'] == doc['id'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildDentistCard(doc, selected),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
                  if (_activeStep != 0) ...[
                const SizedBox(height: 18),
                const Text('Especialista seleccionado', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_selectedDentist != null)
                  _buildDentistCard(_selectedDentist!, true)
                else
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Selecciona un especialista en el paso anterior para continuar.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
              ],
              if (_activeStep == 1) ...[
                const SizedBox(height: 18),
                const Text('Selecciona fecha', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                                if (d != null) {
                                  setState(() {
                                    _selectedDate = d;
                                    if (_selectedTime != null && _isTimeBeforeNow(_selectedTime!)) {
                                      _selectedTime = null;
                                    }
                                  });
                                }
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
              ],
              if (_activeStep == 2) ...[
                const SizedBox(height: 18),
                const Text('Horarios disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _times.map((t) {
                    final selected = t == _selectedTime;
                    final disabled = _isTimeBeforeNow(t);
                    return GestureDetector(
                      onTap: disabled ? null : () => setState(() => _selectedTime = t),
                      child: SizedBox(
                        width: 128,
                        height: 44,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : disabled
                                    ? Colors.grey.shade200
                                    : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : disabled
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : disabled
                                      ? Colors.grey.shade500
                                      : null,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'La consulta dura aproximadamente 30 a 40 minutos.',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                  ),
                ),
              ],
              if (_activeStep == 3) ...[
                const SizedBox(height: 18),
                const Text('Motivo de la consulta', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_reasons.length, (index) {
                    final selected = index == _selectedReasonIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReasonIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _reasons[index],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  maxLines: 3,
                  onChanged: (value) => setState(() => _consultationReason = value),
                  decoration: InputDecoration(
                    hintText: _reasons[_selectedReasonIndex] == 'Otro'
                        ? 'Escribe el motivo de la consulta'
                        : 'Opcional: agrega detalles adicionales',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
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
              ],
              if (_activeStep == 4) ...[
                const SizedBox(height: 18),
                const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPaymentMethod = 'Yape'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedPaymentMethod == 'Yape' ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPaymentMethod == 'Yape' ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.qr_code, color: _selectedPaymentMethod == 'Yape' ? Colors.white : Colors.grey.shade700, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Yape QR',
                                style: TextStyle(
                                  color: _selectedPaymentMethod == 'Yape' ? Colors.white : Colors.grey.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPaymentMethod = 'Efectivo'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedPaymentMethod == 'Efectivo' ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPaymentMethod == 'Efectivo' ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.attach_money, color: _selectedPaymentMethod == 'Efectivo' ? Colors.white : Colors.grey.shade700, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Efectivo',
                                style: TextStyle(
                                  color: _selectedPaymentMethod == 'Efectivo' ? Colors.white : Colors.grey.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedPaymentMethod == 'Yape') ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Escanea el QR con la app de Yape y luego sube la captura de pantalla de tu pago.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Image.asset('assets/qryape.png', height: 220, fit: BoxFit.contain),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isPickingScreenshot ? null : _pickPaymentScreenshot,
                          icon: const Icon(Icons.photo_library),
                          label: Text(_paymentScreenshot == null ? 'Seleccionar captura de pago' : 'Cambiar captura de pago'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (_paymentScreenshot != null) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _paymentScreenshot!,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Vista previa de la captura de pantalla seleccionada.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Seleccionaste pago en efectivo. Lleva el monto exacto al consultorio el día de tu cita.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
              if (_activeStep == 5) ...[
                const SizedBox(height: 18),
                const Text('Resumen de la cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDentist?['nombre']?.toString() ?? 'Especialista',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDentist?['especialidad']?.toString() ?? _selectedDentist?['rol']?.toString() ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fecha'),
                            Text('${_selectedDate.day} ${_monthName(_selectedDate.month)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Horario'),
                            Text(_selectedTime ?? 'No seleccionado'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Motivo'),
                            Expanded(
                              child: Text(
                                _reasons[_selectedReasonIndex] == 'Otro'
                                    ? (_consultationReason.isEmpty ? 'Otro' : _consultationReason)
                                    : _reasons[_selectedReasonIndex],
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Método de pago'),
                            Text(_selectedPaymentMethod == 'Yape' ? 'Yape QR' : 'Efectivo'),
                          ],
                        ),
                        if (_selectedPaymentMethod == 'Yape') ...[
                          const SizedBox(height: 6),
                          Text(
                            _paymentScreenshot == null
                                ? 'Falta la captura de pago.'
                                : 'Captura cargada.',
                            style: TextStyle(
                              color: _paymentScreenshot == null ? Colors.red.shade700 : Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 12),
                        if (selectedDiscount != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Descuento'),
                              Text('-$discountLabel', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total a pagar', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('\$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  if (_activeStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _activeStep = _activeStep - 1),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (_activeStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _activeStep == 5 ? _onConfirm : _onNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_activeStep == 5 ? 'Confirmar cita' : 'Siguiente'),
                    ),
                  ),
                ],
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
