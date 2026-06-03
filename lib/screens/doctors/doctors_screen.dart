import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'doctor_detail_screen.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odontólogos disponibles'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: auth.fetchOdontologos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar odontólogos:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.red),
                      ),
                    );
                  }
                  final odontologos = snapshot.data ?? [];
                  if (odontologos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search, size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No hay odontólogos disponibles',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: odontologos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = odontologos[index];
                      final foto = doc['foto_perfil']?.toString();
                      final nombre = doc['nombre']?.toString() ?? 'Odontólogo';
                      final email = doc['email']?.toString() ?? '';
                      final rol = doc['rol']?.toString() ?? doc['role']?.toString() ?? '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade200,
                          foregroundImage: foto != null && foto.isNotEmpty
                              ? NetworkImage(foto)
                              : null,
                          child: foto == null || foto.isEmpty
                              ? const Icon(Icons.person, color: Color(0xFF4F46E5))
                              : null,
                        ),
                        title: Text(nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            if (rol.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                rol,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doc)),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
