import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import 'book_appointment_screen.dart';
import 'reschedule_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Cargar citas al abrir la pantalla
    Future.microtask(() {
      context.read<AppointmentProvider>().loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _aptDateTime(Map<String, dynamic> apt) {
    final fecha = apt['fecha']?.toString() ?? '';
    final hora = apt['hora']?.toString() ?? '00:00';
    return DateTime.tryParse('$fecha $hora') ??
        DateTime.tryParse(fecha) ??
        DateTime(1900);
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> appointment,
      {bool isHistorial = false}) {
    final fecha = appointment['fecha']?.toString() ?? 'Fecha pendiente';
    final hora = appointment['hora']?.toString() ?? 'Hora pendiente';
    final odontologoObj = appointment['odontologo'];
    final nombreDoctor = appointment['nombre_odontologo']?.toString() ??
                        appointment['doctor']?.toString() ??
                        (odontologoObj is Map
                            ? '${odontologoObj['nombre'] ?? ''} ${odontologoObj['apellido'] ?? ''}'.trim()
                            : null) ??
                        'Odontólogo';
    final estado = appointment['estado']?.toString() ?? 'Por confirmar';
    final monto = appointment['monto'];
    final metodoPago = appointment['metodo_pago']?.toString() ?? 'N/A';
    
    Color statusColor = Colors.orange;
    String statusText = estado;
    
    switch(estado.toLowerCase()) {
      case 'pendiente':
      case 'pendiente_sincronizacion':
        statusColor = Colors.orange;
        statusText = 'Por confirmar';
        break;
      case 'programada':
      case 'confirmada':
        statusColor = Colors.green;
        statusText = 'Confirmada';
        break;
      case 'en_curso':
        statusColor = Colors.blue;
        statusText = 'En curso';
        break;
      case 'cancelada':
        statusColor = Colors.red;
        statusText = 'Cancelada';
        break;
      case 'no_asistio':
        statusColor = Colors.red;
        statusText = 'No asistió';
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nombreDoctor,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mostrar botón de procesar solo para cajero/recepción
                  Builder(builder: (ctx) {
                    final userRole = Provider.of<AuthProvider>(context, listen: false).profile?['rol']?.toString() ??
                        Provider.of<AuthProvider>(context, listen: false).profile?['role']?.toString() ?? '';
                    final isAdminProcessor = ['cajero', 'recepcionista'].contains(userRole.toLowerCase());
                    final alreadyProcessed = appointment['procesada'] == true || appointment['procesada'] == '1';
                    if (isAdminProcessor) {
                      return IconButton(
                        icon: Icon(Icons.check_circle, size: 20, color: alreadyProcessed ? Colors.green : Colors.grey.shade600),
                        tooltip: alreadyProcessed ? 'Procesada' : 'Marcar como procesada',
                        onPressed: alreadyProcessed
                            ? null
                            : () async {
                                final provider = Provider.of<AppointmentProvider>(context, listen: false);
                                final role = userRole.isNotEmpty ? userRole : 'cajero';
                                final id = appointment['id']?.toString() ?? appointment['id_backend']?.toString();
                                if (id == null) return;
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    title: const Text('Procesar cita'),
                                    content: const Text('¿Marcar esta cita como procesada?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Procesar')),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final success = await provider.markAppointmentProcessed(id, role);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(success ? 'Cita marcada como procesada' : 'Error marcando cita')),
                                  );
                                }
                              },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (!isHistorial) ...[
                    IconButton(
                      icon: Icon(Icons.edit_calendar_outlined, size: 20, color: Colors.grey.shade600),
                      tooltip: 'Reagendar cita',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RescheduleAppointmentScreen(appointment: appointment),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.grey.shade600),
                    tooltip: isHistorial ? 'Eliminar del historial' : 'Cancelar cita',
                    onPressed: () async {
                      final id = appointment['id_backend']?.toString() ?? appointment['id']?.toString();
                      if (id == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID de la cita no disponible')),
                        );
                        return;
                      }

                      if (isHistorial) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar del historial'),
                            content: const Text('¿Deseas eliminar esta cita de tu historial local?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          final provider = Provider.of<AppointmentProvider>(context, listen: false);
                          final success = await provider.deleteAppointmentLocal(id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Cita eliminada' : 'Error eliminando cita')),
                          );
                        }
                        return;
                      }

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancelar cita'),
                          content: const Text('¿Seguro que deseas cancelar esta cita?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sí, cancelar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        final provider = Provider.of<AppointmentProvider>(context, listen: false);
                        final success = await provider.cancelAppointment(id, 'Cancelada por el paciente');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Cita cancelada'
                                : 'No se pudo cancelar la cita. Intenta nuevamente.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '$fecha • $hora',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (monto != null)
            Row(
              children: [
                Icon(Icons.monetization_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'S/ ${monto.toString()} • $metodoPago',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message, {VoidCallback? onAddTap}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            if (onAddTap != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add),
                label: const Text('Agendar nueva cita'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildTabList(List<Map<String, dynamic>> items, String emptyMessage,
      {bool offerBooking = false, bool isHistorial = false}) {
    return RefreshIndicator(
      onRefresh: () => context.read<AppointmentProvider>().loadAppointments(),
      child: items.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEmptySection(
                  emptyMessage,
                  onAddTap: offerBooking
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
                          );
                        }
                      : null,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) =>
                  _buildAppointmentCard(context, items[i], isHistorial: isHistorial),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = Provider.of<AppointmentProvider>(context);

    // Filtrar citas por estado y ordenarlas por fecha
    final pendientes = appointments.appointments
        .where((apt) => ['pendiente', 'pendiente_sincronizacion'].contains(apt['estado']?.toString().toLowerCase()))
        .toList()
      ..sort((a, b) => _aptDateTime(a).compareTo(_aptDateTime(b)));

    final proximas = appointments.appointments
        .where((apt) => ['programada', 'confirmada', 'en_curso'].contains(apt['estado']?.toString().toLowerCase()))
        .toList()
      ..sort((a, b) => _aptDateTime(a).compareTo(_aptDateTime(b)));

    final historial = appointments.appointments
        .where((apt) => ['cancelada', 'no_asistio'].contains(apt['estado']?.toString().toLowerCase()))
        .toList()
      ..sort((a, b) => _aptDateTime(b).compareTo(_aptDateTime(a)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis citas'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Próximas (${proximas.length})'),
            Tab(text: 'Por confirmar (${pendientes.length})'),
            Tab(text: 'Historial (${historial.length})'),
          ],
        ),
        actions: [
          // Botón para sincronizar citas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: appointments.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        appointments.loadAppointments();
                      },
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (appointments.errorMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointments.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: appointments.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabList(proximas, 'No tienes citas próximas', offerBooking: true),
                        _buildTabList(pendientes, 'No tienes citas por confirmar'),
                        _buildTabList(historial, 'Sin historial de citas', isHistorial: true),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Agendar cita'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
