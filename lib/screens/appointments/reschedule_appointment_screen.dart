import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  const RescheduleAppointmentScreen({Key? key, required this.appointment}) : super(key: key);

  @override
  State<RescheduleAppointmentScreen> createState() => _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState extends State<RescheduleAppointmentScreen> {
  late DateTime _selectedDate;
  String? _selectedTime;
  late String _paymentMethod;
  File? _paymentScreenshot;
  bool _isPickingScreenshot = false;
  bool _isSubmitting = false;

  final List<String> _times = const [
    '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM', '06:00 PM',
    '06:30 PM', '07:00 PM', '07:30 PM', '08:00 PM', '08:30 PM', '09:00 PM',
  ];

  /// El método de pago original con el que se creó la cita.
  String get _metodoPagoOriginal =>
      widget.appointment['metodo_pago']?.toString() ?? 'Efectivo';

  /// Si la cita ya fue pagada por Yape, no se permite cambiar el método de
  /// pago al reagendar: solo se puede mover la fecha/hora.
  bool get _yaPagadoPorYape => _metodoPagoOriginal.toLowerCase() == 'yape';

  @override
  void initState() {
    super.initState();
    final fecha = DateTime.tryParse(widget.appointment['fecha']?.toString() ?? '') ?? DateTime.now();
    _selectedDate = fecha;
    _paymentMethod = _metodoPagoOriginal;
  }

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
    final selectedDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
    return selectedDateTime.isBefore(DateTime.now());
  }

  Future<void> _pickPaymentScreenshot() async {
    if (_isPickingScreenshot) return;
    setState(() => _isPickingScreenshot = true);
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _paymentScreenshot = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar captura: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingScreenshot = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un nuevo horario'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_isTimeBeforeNow(_selectedTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un horario que no haya pasado'), backgroundColor: Colors.red),
      );
      return;
    }

    final cambioAYape = !_yaPagadoPorYape && _paymentMethod == 'Yape';
    if (cambioAYape && _paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sube la captura de tu pago por Yape para continuar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final id = widget.appointment['id_backend']?.toString() ?? widget.appointment['id']?.toString();
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar la cita'), backgroundColor: Colors.red),
      );
      return;
    }

    final fecha = '${_selectedDate.year.toString().padLeft(4, '0')}'
        '-${_selectedDate.month.toString().padLeft(2, '0')}'
        '-${_selectedDate.day.toString().padLeft(2, '0')}';

    final timeList = _selectedTime!.split(':');
    int hour = int.parse(timeList[0]);
    final minute = timeList[1].split(' ')[0];
    if (_selectedTime!.contains('PM') && hour != 12) {
      hour += 12;
    } else if (_selectedTime!.contains('AM') && hour == 12) {
      hour = 0;
    }
    final hora = '${hour.toString().padLeft(2, '0')}:$minute';

    setState(() => _isSubmitting = true);
    final provider = context.read<AppointmentProvider>();
    final success = await provider.rescheduleAppointment(
      appointmentId: id,
      fecha: fecha,
      hora: hora,
      metodoPago: _yaPagadoPorYape ? null : _paymentMethod,
      paymentProof: cambioAYape ? _paymentScreenshot : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Cita reagendada para $fecha $hora'
            : 'No se pudo conectar al servidor. El cambio se sincronizará después.'),
        backgroundColor: success ? Colors.green : Colors.orange,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    final odontologoObj = apt['odontologo'];
    final nombreDoctor = apt['nombre_odontologo']?.toString() ??
        apt['doctor']?.toString() ??
        (odontologoObj is Map
            ? '${odontologoObj['nombre'] ?? ''} ${odontologoObj['apellido'] ?? ''}'.trim()
            : null) ??
        'Odontólogo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reagendar cita'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombreDoctor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      'Cita actual: ${apt['fecha'] ?? ''} · ${apt['hora'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nueva fecha', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
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
                    child: const Text('Cambiar'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nuevo horario', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times.map((t) {
                  final selected = t == _selectedTime;
                  final disabled = _isTimeBeforeNow(t);
                  return GestureDetector(
                    onTap: disabled ? null : () => setState(() => _selectedTime = t),
                    child: Container(
                      width: 128,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: disabled ? Colors.grey.shade200 : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : disabled ? Colors.grey.shade500 : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_yaPagadoPorYape) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ya pagaste esta cita por Yape. Solo puedes cambiar la fecha y el horario.',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = 'Efectivo'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'Efectivo'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'Efectivo'
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.attach_money,
                                  color: _paymentMethod == 'Efectivo' ? Colors.white : Colors.grey.shade700),
                              const SizedBox(height: 6),
                              Text('Efectivo',
                                  style: TextStyle(
                                      color: _paymentMethod == 'Efectivo' ? Colors.white : Colors.grey.shade800,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = 'Yape'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'Yape'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'Yape'
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.qr_code,
                                  color: _paymentMethod == 'Yape' ? Colors.white : Colors.grey.shade700),
                              const SizedBox(height: 6),
                              Text('Yape',
                                  style: TextStyle(
                                      color: _paymentMethod == 'Yape' ? Colors.white : Colors.grey.shade800,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_paymentMethod == 'Yape') ...[
                  const SizedBox(height: 16),
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
                          'Cambiaste a Yape: escanea el QR y sube la captura de tu pago.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 14),
                        Image.asset('assets/qryape.png', height: 200, fit: BoxFit.contain),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _isPickingScreenshot ? null : _pickPaymentScreenshot,
                          icon: const Icon(Icons.photo_library),
                          label: Text(_paymentScreenshot == null ? 'Seleccionar captura de pago' : 'Cambiar captura'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (_paymentScreenshot != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_paymentScreenshot!, width: double.infinity, height: 150, fit: BoxFit.cover),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pagarás en efectivo el día de tu cita.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
