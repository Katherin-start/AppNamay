import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MedicalHistoryTab extends StatelessWidget {
  const MedicalHistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final userName = profile?['nombre']?.toString() ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial clínico'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi historial clínico',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Usuario: $userName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _HistorySection(
                title: 'Tratamientos realizados',
                icon: Icons.medical_services,
                isEmpty: true,
                context: context,
              ),
              const SizedBox(height: 16),
              _HistorySection(
                title: 'Diagnósticos',
                icon: Icons.description,
                isEmpty: true,
                context: context,
              ),
              const SizedBox(height: 16),
              _HistorySection(
                title: 'Medicamentos',
                icon: Icons.medication,
                isEmpty: true,
                context: context,
              ),
              const SizedBox(height: 16),
              _HistorySection(
                title: 'Alergias y sensibilidades',
                icon: Icons.warning,
                isEmpty: true,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isEmpty;
  final BuildContext context;

  const _HistorySection({
    required this.title,
    required this.icon,
    required this.isEmpty,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEmpty)
            Center(
              child: Text(
                'Sin registros',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            )
          else
            Text(
              'Contenido aquí',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}
