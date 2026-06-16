import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar citas al abrir la pantalla
    Future.microtask(() {
      context.read<AppointmentProvider>().loadAppointments();
    });
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> appointment) {
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.grey.shade600),
                    tooltip: 'Eliminar cita',
                    onPressed: () async {
                      final id = appointment['id']?.toString();
                      if (id == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID de la cita no disponible')),
                        );
                        return;
                      }

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar cita'),
                          content: const Text('¿Deseas eliminar esta cita localmente?'),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Cita eliminada' : 'Error eliminando cita')),
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


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final appointments = Provider.of<AppointmentProvider>(context);
    final profile = auth.profile;
    final userName = profile?['nombre']?.toString() ?? 'Usuario';

    // Filtrar citas por estado
    final pendientes = appointments.appointments
        .where((apt) => ['pendiente', 'pendiente_sincronizacion'].contains(apt['estado']?.toString().toLowerCase()))
        .toList();
    
    final proximas = appointments.appointments
        .where((apt) => ['programada', 'confirmada', 'en_curso'].contains(apt['estado']?.toString().toLowerCase()))
        .toList();
    
    final historial = appointments.appointments
        .where((apt) => ['cancelada', 'no_asistio'].contains(apt['estado']?.toString().toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis citas'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
        child: appointments.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, $userName',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (appointments.errorMessage != null)
                      Container(
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
                    const SizedBox(height: 24),
                    
                    // === CITAS POR CONFIRMAR ===
                    Text(
                      'Citas por confirmar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (pendientes.isEmpty)
                      _buildEmptySection('No tienes citas por confirmar')
                    else
                      Column(
                        children: pendientes.map((apt) => _buildAppointmentCard(context, apt)).toList(),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // === PRÓXIMAS CITAS ===
                    Text(
                      'Próximas citas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (proximas.isEmpty)
                      _buildEmptySection(
                        'No tienes citas pendientes',
                        onAddTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
                          );
                        },
                      )
                    else
                      Column(
                        children: proximas.map((apt) => _buildAppointmentCard(context, apt)).toList(),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // === HISTORIAL DE CITAS ===
                    Text(
                      'Historial de citas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (historial.isEmpty)
                      _buildEmptySection('Sin historial de citas')
                    else
                      Column(
                        children: historial.map((apt) => _buildAppointmentCard(context, apt)).toList(),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón para agendar nueva cita (visible siempre)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('+ Agendar nueva cita'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
