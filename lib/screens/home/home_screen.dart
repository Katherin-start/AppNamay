import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../appointments/appointments_screen.dart';
import '../doctors/doctor_detail_screen.dart';
import '../doctors/doctors_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = List<Widget>.filled(5, const SizedBox(), growable: false);
    _screens[0] = const _HomeTab();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _ensureScreenInitialized(index);
    });
  }

  void _ensureScreenInitialized(int index) {
    if (_screens[index] is SizedBox) {
      switch (index) {
        case 0:
          _screens[index] = const _HomeTab();
          break;
        case 1:
          _screens[index] = const AppointmentsScreen();
          break;
        case 2:
          _screens[index] = const MedicalHistoryTab();
          break;
        case 3:
          _screens[index] = const ChatListScreen();
          break;
        case 4:
          _screens[index] = const ProfileScreen();
          break;
      }
    }
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: _screens,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF1D4ED8),
            unselectedItemColor: Colors.grey.shade600,
            showUnselectedLabels: true,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 24),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Citas'),
              BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Historial'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final displayName = (profile != null && profile['nombre'] != null)
        ? profile['nombre'].toString()
        : (profile != null && profile['name'] != null
            ? profile['name'].toString()
            : null);
    final profilePhoto = profile?['foto_perfil']?.toString() ??
        profile?['fotoPerfil']?.toString() ??
        profile?['foto']?.toString();
    final profileRole = profile?['rol']?.toString() ??
        profile?['role']?.toString() ??
        profile?['rol_id']?.toString();
    final showProfileRole = profileRole != null &&
        profileRole.isNotEmpty &&
        !['cliente', 'paciente'].contains(profileRole.toLowerCase());

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 3, 7, 101),
              ),
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Citas'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with drawer and notification outside the card
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (ctx) => InkWell(
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.menu, color: Color(0xFF243656), size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${displayName ?? 'Juan'}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: const Color(0xFF111827),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                auth.isNewUser
                                    ? 'Te damos la Bienvenida a la Clínica Namay'
                                    : 'Bienvenido nuevamente',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                              ),
                              if (showProfileRole) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    profileRole ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF1D4ED8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Notificaciones removidas (usuario pidió eliminar el icono)
                    Transform.translate(
                      offset: const Offset(0, -6), // subir un poco el avatar
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/profilePhoto');
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Builder(builder: (ctx) {
                          ImageProvider? imageProvider;
                          if (profilePhoto != null && profilePhoto.isNotEmpty) {
                            if (profilePhoto.startsWith('http')) {
                              imageProvider = NetworkImage(profilePhoto);
                            } else {
                              final file = File(profilePhoto);
                              if (file.existsSync()) imageProvider = FileImage(file);
                            }
                          }

                          return CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFE0E7FF),
                            foregroundImage: imageProvider,
                            child: imageProvider == null
                                ? const Icon(Icons.person, color: Color(0xFF1D4ED8), size: 24)
                                : null,
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/consultorioapp.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1D4ED8).withOpacity(0.75),
                                  const Color(0xFF2563EB).withOpacity(0.75),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Clínica Dental',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Tu sonrisa es\nnuestra prioridad',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1.15,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cuidamos tu salud dental con profesionalismo y dedicación.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AppointmentsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                                label: const Text('Reservar cita'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accesos rápidos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFF2D3748),
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _QuickAccessAllScreen(),
                          ),
                        );
                      },
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Grid de opciones - Solo 4 elementos en fila
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FeatureCard(
                        title: 'Próxima cita',
                        icon: Icons.calendar_today,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AppointmentsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _FeatureCard(
                        title: 'Historial',
                        icon: Icons.folder_open,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MedicalHistoryTab(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _FeatureCard(
                        title: 'Pagos',
                        icon: Icons.credit_card,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaymentsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _FeatureCard(
                        title: 'Chat doctor',
                        icon: Icons.chat_bubble_outline,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChatListScreen(),
                            ),
                          );
                        },
                        showBadge: true,
                      ),
                      const SizedBox(width: 12),
                      _FeatureCard(
                        title: 'Odontólogos',
                        icon: Icons.medical_services,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DoctorsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Especialistas - Modificado para mostrar "No encontramos especialistas"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nuestros especialistas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFF2D3748),
                          ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mostrar odontólogos disponibles (fetch desde AuthProvider)
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: auth.fetchOdontologos(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          final raw = snapshot.error?.toString() ?? 'Error desconocido';
                          String message = raw;
                          // Si la respuesta contiene HTML, mostrar mensaje más claro al usuario
                          if (raw.contains('<') && raw.contains('html')) {
                            message = 'No se pudo cargar especialistas: respuesta no válida del servidor.';
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Error al cargar especialistas: $message',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                            ),
                          );
                        }

                        final odontologos = snapshot.data ?? [];
                        if (odontologos.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF4F6FF),
                                  const Color(0xFFF0F3FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.person_search, size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay especialistas disponibles por ahora',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: odontologos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final doc = odontologos[index];
                              final foto = doc['foto_perfil']?.toString() ?? doc['fotoPerfil']?.toString();
                              final nombre = doc['nombre']?.toString() ?? 'Odontólogo';
                              final rol = doc['rol']?.toString() ?? doc['role']?.toString() ?? '';

                              return Container(
                                width: 220,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 34,
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundImage: foto != null && foto.isNotEmpty ? NetworkImage(foto) : null,
                                      child: foto == null || foto.isEmpty ? const Icon(Icons.person, color: Color(0xFF4F46E5)) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            nombre,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (rol.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              rol,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doc)),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4F46E5),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text('Ver'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 18),

                _DiscountsSection(auth: auth),

                const SizedBox(height: 18),

                // Próxima cita destacada
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withOpacity(0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4F46E5).withOpacity(0.14),
                                  const Color(0xFF4F46E5).withOpacity(0.06),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF4F46E5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tu próxima cita',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No hay ninguna cita agendada',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Resumen rápido
                Text(
                  'Resumen de tu salud',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF2D3748),
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF4F6FF),
                        const Color(0xFFF0F3FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          size: 40,
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay resumen disponible',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tips dentales
                Text(
                  'Consejos dentales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF2D3748),
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5B5FEF).withOpacity(0.06),
                        const Color(0xFF7B61FF).withOpacity(0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF5B5FEF).withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B5FEF).withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        child: Icon(
                          Icons.tips_and_updates_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cepillado correcto',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cepíllate 2 minutos, 2 veces al día',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscountsSection extends StatefulWidget {
  final AuthProvider auth;
  const _DiscountsSection({required this.auth});

  @override
  State<_DiscountsSection> createState() => _DiscountsSectionState();
}

class _DiscountsSectionState extends State<_DiscountsSection> {
  late Future<List<Map<String, dynamic>>> _discountsFuture;

  @override
  void initState() {
    super.initState();
    _discountsFuture = widget.auth.fetchDiscounts();
  }

  @override
  void didUpdateWidget(covariant _DiscountsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth != widget.auth) {
      _discountsFuture = widget.auth.fetchDiscounts();
    }
  }

  String _formatDiscountValue(Map<String, dynamic> discount) {
    final tipo = discount['tipo']?.toString().toLowerCase() ?? '';
    final valor = double.tryParse(discount['valor']?.toString() ?? '') ?? 0.0;
    if (tipo.contains('porcentaje')) {
      return '${valor.toStringAsFixed(valor.truncateToDouble() == valor ? 0 : 1)}%';
    }
    return '\$${valor.toStringAsFixed(valor.truncateToDouble() == valor ? 0 : 2)}';
  }

  String _formatDateRange(Map<String, dynamic> discount) {
    final start = discount['fecha_inicio']?.toString();
    final end = discount['fecha_fin']?.toString();
    if (start != null && end != null && start.isNotEmpty && end.isNotEmpty) {
      return '$start – $end';
    }
    if (start != null && start.isNotEmpty) {
      return 'Desde $start';
    }
    if (end != null && end.isNotEmpty) {
      return 'Hasta $end';
    }
    return 'Vigencia desconocida';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _discountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5B5FEF),
                  const Color(0xFF7B61FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade500,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Error al cargar descuentos: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final discounts = snapshot.data ?? [];
        if (discounts.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5B5FEF),
                  const Color(0xFF7B61FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Descuentos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aún no hay descuentos aplicados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pronto te mostraremos las mejores ofertas disponibles.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.88),
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descuentos disponibles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF1D4ED8),
                  ),
            ),
            const SizedBox(height: 12),
            ...discounts.map((discount) {
              final label = _formatDiscountValue(discount);
              final range = _formatDateRange(discount);
              final appliesTo = discount['aplica_a']?.toString() ?? 'Todos los procedimientos';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                discount['nombre']?.toString() ?? 'Descuento',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if ((discount['descripcion']?.toString() ?? '').isNotEmpty)
                          Text(
                            discount['descripcion'].toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          appliesTo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          range,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF5B5FEF).withOpacity(0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5B5FEF).withOpacity(0.1),
                          const Color(0xFF7B61FF).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: const Color(0xFF5B5FEF),
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: const Color(0xFF2D3748),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessAllScreen extends StatelessWidget {
  const _QuickAccessAllScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Accesos rápidos'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Todos tus accesos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encuentra de forma rápida las funciones más importantes de tu cuenta.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                  children: [
                    _FeatureCard(
                      title: 'Próxima cita',
                      icon: Icons.calendar_today,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppointmentsScreen(),
                          ),
                        );
                      },
                    ),
                    _FeatureCard(
                      title: 'Historial',
                      icon: Icons.folder_open,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MedicalHistoryTab(),
                          ),
                        );
                      },
                    ),
                    _FeatureCard(
                      title: 'Pagos',
                      icon: Icons.credit_card,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PaymentsScreen(),
                          ),
                        );
                      },
                    ),
                    _FeatureCard(
                      title: 'Chat doctor',
                      icon: Icons.chat_bubble_outline,
                      showBadge: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aún no hay recetas disponibles',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.credit_card, size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aquí podrás ver tus pagos y facturas',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedicalHistoryTab extends StatelessWidget {
  const MedicalHistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Médico'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
     body: const MedicalHistoryTab(),
    );
  }
}