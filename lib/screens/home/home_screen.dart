import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/backend_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/appointment_service.dart';
import '../../services/storage_service.dart';
import '../appointments/appointments_screen.dart';
import '../doctors/doctor_detail_screen.dart';
import '../doctors/doctors_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/medical_info_screen.dart';
import '../assistant/ai_assistant_screen.dart';

// ── Paleta de colores ────────────────────────────────────────────
const _kBluePrimary = Color(0xFF1D4ED8);
const _kBlueDeep    = Color(0xFF1E3A8A);
const _kBlueLight   = Color(0xFF3B82F6);
const _kRedPrimary  = Color(0xFFDC2626);
const _kRedLight    = Color(0xFFEF4444);

const _kLightBg     = Color(0xFFF0F4FF);
const _kDarkBg      = Color(0xFF080E1A);
const _kDarkSurface = Color(0xFF101624);
const _kDarkCard    = Color(0xFF182032);
const _kDarkBorder  = Color(0xFF2A3A55);
// ─────────────────────────────────────────────────────────────────

extension _CtxTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ════════════════════════════════════════════════════════════════
//  HomeScreen – shell con bottom nav
// ════════════════════════════════════════════════════════════════
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
      _ensureInit(index);
    });
  }

  void _ensureInit(int index) {
    if (_screens[index] is SizedBox) {
      switch (index) {
        case 0: _screens[index] = const _HomeTab(); break;
        case 1: _screens[index] = const AppointmentsScreen(); break;
        case 2: _screens[index] = const MedicalHistoryTab(); break;
        case 3: _screens[index] = const ChatListScreen(); break;
        case 4: _screens[index] = const ProfileScreen(); break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Consumer<ChatProvider>(
      builder: (context, chat, child) {
        // Mostrar notificación cuando el cajero aprueba el pago
        if (chat.lastComprobante != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showComprobanteDialog(context, chat);
          });
        }
        return child!;
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _selectedIndex, children: _screens),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          heroTag: 'ai_assistant_fab',
          backgroundColor: isDark ? _kBlueLight : _kBluePrimary,
          foregroundColor: Colors.white,
          tooltip: 'Asistente IA',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
            );
          },
          child: const Icon(Icons.smart_toy_rounded),
        ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? _kDarkSurface : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? _kDarkBorder : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 20,
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
            selectedItemColor: isDark ? _kBlueLight : _kBluePrimary,
            unselectedItemColor:
                isDark ? const Color(0xFF475569) : Colors.grey.shade500,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            selectedIconTheme: const IconThemeData(size: 26),
            unselectedIconTheme: const IconThemeData(size: 22),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded), label: 'Inicio'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_rounded), label: 'Citas'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.folder_rounded), label: 'Historial'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat_rounded), label: 'Chat'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded), label: 'Perfil'),
            ],
          ),
        ),
      ),
    ),    // closes Scaffold
    );    // closes Consumer
  }

  void _showComprobanteDialog(BuildContext context, ChatProvider chat) {
    final data = chat.lastComprobante;
    if (data == null) return;
    chat.clearComprobante();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 10),
            const Text('Pago confirmado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu pago ha sido aceptado y confirmado por la clínica.'),
            const SizedBox(height: 8),
            Text(
              data['message']?.toString() ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (data['invoice_url'] != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navegar a la pestaña de citas para ver detalles
              },
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text('Ver citas'),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  _HomeTab – contenido principal
// ════════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final displayName =
        (profile?['nombre'] ?? profile?['name'])?.toString();
    final profilePhoto =
        (profile?['foto_perfil'] ?? profile?['fotoPerfil'] ?? profile?['foto'])
            ?.toString();

    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : _kLightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                  displayName: displayName,
                  profilePhoto: profilePhoto,
                  auth: auth,
                  isDark: isDark),
              const SizedBox(height: 22),
              _HeroBanner(isDark: isDark),
              const SizedBox(height: 26),
              _SectionTitle(
                title: 'Accesos rápidos',
                isDark: isDark,
                onSeeAll: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const _QuickAccessAllScreen())),
              ),
              const SizedBox(height: 14),
              _QuickAccessRow(isDark: isDark),
              const SizedBox(height: 26),
              _SectionTitle(
                title: 'Nuestros especialistas',
                isDark: isDark,
                onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DoctorsScreen())),
              ),
              const SizedBox(height: 14),
              _SpecialistsList(auth: auth, isDark: isDark),
              const SizedBox(height: 20),
              _DiscountsSection(auth: auth),
              const SizedBox(height: 20),
              _NextAppointmentCard(isDark: isDark),
              const SizedBox(height: 26),
              _SectionTitle(title: 'Resumen de tu salud', isDark: isDark),
              const SizedBox(height: 14),
              _HealthSummaryCard(isDark: isDark),
              const SizedBox(height: 26),
              _SectionTitle(title: 'Consejos dentales', isDark: isDark),
              const SizedBox(height: 14),
              _DentalTipCard(isDark: isDark),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String? displayName;
  final String? profilePhoto;
  final AuthProvider auth;
  final bool isDark;

  const _Header({
    required this.displayName,
    required this.profilePhoto,
    required this.auth,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName != null ? 'Hola, $displayName' : 'Hola',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 23,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.isNewUser
                    ? 'Bienvenido a Clinica Namay'
                    : 'Bienvenido nuevamente',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        // Boton modo oscuro/claro
        Consumer<ThemeProvider>(
          builder: (_, tp, __) => GestureDetector(
            onTap: tp.toggleTheme,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? _kDarkCard : const Color(0xFFE0E7FF),
                border: Border.all(
                  color: isDark
                      ? _kDarkBorder
                      : const Color(0xFFC7D2FE),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isDark
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round,
                size: 19,
                color: isDark
                    ? const Color(0xFFFBBF24)
                    : _kBluePrimary,
              ),
            ),
          ),
        ),
        // Avatar
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/profilePhoto'),
          borderRadius: BorderRadius.circular(999),
          child: Builder(builder: (ctx) {
            ImageProvider? img;
            if (profilePhoto != null && profilePhoto!.isNotEmpty) {
              if (profilePhoto!.startsWith('http')) {
                img = NetworkImage(profilePhoto!);
              } else {
                final file = File(profilePhoto!);
                if (file.existsSync()) img = FileImage(file);
              }
            }
            return CircleAvatar(
              radius: 23,
              backgroundColor:
                  isDark ? _kDarkCard : const Color(0xFFE0E7FF),
              foregroundImage: img,
              child: img == null
                  ? Icon(Icons.person_rounded,
                      color: isDark ? _kBlueLight : _kBluePrimary,
                      size: 24)
                  : null,
            );
          }),
        ),
      ],
    );
  }
}

// ── Hero Banner ──────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final bool isDark;
  const _HeroBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kBluePrimary.withOpacity(isDark ? 0.4 : 0.25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Imagen de fondo
            Positioned.fill(
              child: Image.asset(
                'assets/consultorioapp.png',
                fit: BoxFit.cover,
              ),
            ),
            // Overlay gradiente azul oscuro
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kBlueDeep.withOpacity(0.92),
                      _kBluePrimary.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            // Barra roja izquierda
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kRedPrimary, _kRedLight],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                ),
              ),
            ),
            // Circulo decorativo esquina
            Positioned(
              right: -30, top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 20, bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kRedPrimary.withOpacity(0.12),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge rojo
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kRedPrimary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _kRedPrimary.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Clinica Dental',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu sonrisa es\nnuestra prioridad',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cuidamos tu salud dental con\nprofesionalismo y dedicacion.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AppointmentsScreen()),
                    ),
                    icon: const Icon(Icons.calendar_today_outlined,
                        size: 18),
                    label: const Text(
                      'Reservar cita',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kBluePrimary,
                      elevation: 6,
                      shadowColor: Colors.black38,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Title ────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback? onSeeAll;

  const _SectionTitle({
    required this.title,
    required this.isDark,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? _kBlueLight : _kBluePrimary,
              padding: EdgeInsets.zero,
            ),
            child: const Text('Ver todos',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ── Quick Access Row ─────────────────────────────────────────────
class _QuickAccessRow extends StatelessWidget {
  final bool isDark;
  const _QuickAccessRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FeatureCard(
            title: 'Proxima cita',
            icon: Icons.calendar_today_rounded,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AppointmentsScreen())),
          ),
          const SizedBox(width: 12),
          _FeatureCard(
            title: 'Historial',
            icon: Icons.folder_open_rounded,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const MedicalHistoryTab())),
          ),
          const SizedBox(width: 12),
          _FeatureCard(
            title: 'Pagos',
            icon: Icons.credit_card_rounded,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PaymentsScreen())),
          ),
          const SizedBox(width: 12),
          _FeatureCard(
            title: 'Chat doctor',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ChatListScreen())),
            showBadge: true,
          ),
          const SizedBox(width: 12),
          _FeatureCard(
            title: 'Odontologos',
            icon: Icons.medical_services_rounded,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DoctorsScreen())),
          ),
        ],
      ),
    );
  }
}

// ── Specialists List ─────────────────────────────────────────────
class _SpecialistsList extends StatelessWidget {
  final AuthProvider auth;
  final bool isDark;

  const _SpecialistsList({required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: auth.fetchOdontologos(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(
                    color: isDark ? _kBlueLight : _kBluePrimary,
                  ),
                ),
              );
            }
            if (snap.hasError) {
              return _EmptyState(
                isDark: isDark,
                icon: Icons.error_outline_rounded,
                message: 'No se pudo cargar especialistas',
                iconColor: _kRedLight,
              );
            }
            final docs = snap.data ?? [];
            if (docs.isEmpty) {
              return _EmptyState(
                isDark: isDark,
                icon: Icons.person_search_rounded,
                message: 'No hay especialistas disponibles',
              );
            }
            return SizedBox(
              height: 162,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final foto =
                      (doc['foto_perfil'] ?? doc['fotoPerfil'])
                          ?.toString();
                  final nombre =
                      doc['nombre']?.toString() ?? 'Odontologo';
                  final rol =
                      (doc['rol'] ?? doc['role'])?.toString() ?? '';
                  return _SpecialistCard(
                    isDark: isDark,
                    foto: foto,
                    nombre: nombre,
                    rol: rol,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              DoctorDetailScreen(doctor: doc)),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final bool isDark;
  final String? foto;
  final String nombre;
  final String rol;
  final VoidCallback onTap;

  const _SpecialistCard({
    required this.isDark,
    required this.foto,
    required this.nombre,
    required this.rol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _kDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _kDarkBorder : const Color(0xFFE0E7FF),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : _kBluePrimary.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: isDark
                ? _kDarkSurface
                : const Color(0xFFE0E7FF),
            foregroundImage: (foto != null && foto!.isNotEmpty)
                ? NetworkImage(foto!)
                : null,
            child: (foto == null || foto!.isEmpty)
                ? Icon(Icons.person_rounded,
                    color: isDark ? _kBlueLight : _kBluePrimary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rol.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rol,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? _kBlueLight : _kBluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                  ),
                  child: const Text('Ver',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  final Color? iconColor;

  const _EmptyState({
    required this.isDark,
    required this.icon,
    required this.message,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? _kDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _kDarkBorder : const Color(0xFFE0E7FF),
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 48,
              color: iconColor ??
                  (isDark
                      ? const Color(0xFF475569)
                      : Colors.grey.shade400)),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : Colors.grey.shade600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Next Appointment Card ────────────────────────────────────────
class _NextAppointmentCard extends StatefulWidget {
  final bool isDark;
  const _NextAppointmentCard({required this.isDark});

  @override
  State<_NextAppointmentCard> createState() => _NextAppointmentCardState();
}

class _NextAppointmentCardState extends State<_NextAppointmentCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AppointmentProvider>().loadAppointments();
    });
  }

  Map<String, dynamic>? _nextAppointment(List<Map<String, dynamic>> appointments) {
    const activeStates = {
      'pendiente',
      'pendiente_sincronizacion',
      'programada',
      'confirmada',
      'en_curso',
    };
    final now = DateTime.now();
    final upcoming = appointments.where((apt) {
      final estado = apt['estado']?.toString().toLowerCase() ?? '';
      if (!activeStates.contains(estado)) return false;
      final fechaStr = apt['fecha']?.toString() ?? '';
      final horaStr = apt['hora']?.toString() ?? '00:00';
      final dt = DateTime.tryParse('$fechaStr $horaStr') ??
          DateTime.tryParse(fechaStr);
      return dt != null && !dt.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();

    upcoming.sort((a, b) {
      final da = DateTime.tryParse('${a['fecha']} ${a['hora'] ?? '00:00'}') ??
          DateTime.tryParse(a['fecha']?.toString() ?? '') ??
          DateTime(2100);
      final db = DateTime.tryParse('${b['fecha']} ${b['hora'] ?? '00:00'}') ??
          DateTime.tryParse(b['fecha']?.toString() ?? '') ??
          DateTime(2100);
      return da.compareTo(db);
    });

    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _doctorName(Map<String, dynamic> apt) {
    final odontologoObj = apt['odontologo'];
    return apt['nombre_odontologo']?.toString() ??
        apt['doctor']?.toString() ??
        (odontologoObj is Map
            ? '${odontologoObj['nombre'] ?? ''} ${odontologoObj['apellido'] ?? ''}'.trim()
            : null) ??
        'Odontólogo';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final blue = isDark ? _kBlueLight : _kBluePrimary;
    final appointments = context.watch<AppointmentProvider>().appointments;
    final next = _nextAppointment(appointments);

    final subtitle = next == null
        ? 'No hay ninguna cita agendada'
        : '${next['fecha']} · ${next['hora'] ?? ''}  ·  ${_doctorName(next)}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppointmentsScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? _kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: blue.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: blue.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                color: blue.withOpacity(0.1),
              ),
              child: Icon(Icons.calendar_today_rounded,
                  color: blue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu proxima cita',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 15,
                color: isDark
                    ? const Color(0xFF475569)
                    : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ── Health Summary Card ──────────────────────────────────────────
class _HealthSummaryCard extends StatefulWidget {
  final bool isDark;
  const _HealthSummaryCard({required this.isDark});

  @override
  State<_HealthSummaryCard> createState() => _HealthSummaryCardState();
}

class _HealthSummaryCardState extends State<_HealthSummaryCard> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
        setState(() { _error = 'No se pudo cargar el historial'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  /// Calcula una conclusión a partir de diagnósticos/tratamientos/alertas
  /// registrados en el historial clínico real del paciente.
  ({String headline, String detail, Color color, IconData icon}) _conclusion() {
    if (_records.isEmpty) {
      return (
        headline: 'Sin historial clínico aún',
        detail: 'Cuando tengas tu primera consulta, aquí verás un resumen de tu salud dental.',
        color: Colors.grey,
        icon: Icons.health_and_safety_rounded,
      );
    }

    final sorted = [..._records]..sort((a, b) {
      final da = DateTime.tryParse(a['fecha']?.toString() ?? '') ?? DateTime(1900);
      final db = DateTime.tryParse(b['fecha']?.toString() ?? '') ?? DateTime(1900);
      return db.compareTo(da);
    });

    final hasAlergia = _records.any(
        (r) => (r['tipo']?.toString() ?? '').toLowerCase().contains('alerg'));
    final pendientes = _records.where((r) {
      final tratamiento = r['tratamiento']?.toString().toLowerCase() ?? '';
      return tratamiento.contains('pendiente') || tratamiento.contains('continuar');
    }).length;

    final ultimo = sorted.first;
    final ultimaFecha = DateTime.tryParse(ultimo['fecha']?.toString() ?? '');
    final diasDesdeUltima =
        ultimaFecha != null ? DateTime.now().difference(ultimaFecha).inDays : null;
    final ultimoDiagnostico = ultimo['diagnostico']?.toString();

    if (hasAlergia) {
      return (
        headline: 'Tienes alergias registradas',
        detail: 'Tu historial incluye alertas de alergia. Coméntalo siempre con tu odontóloga antes de un tratamiento.',
        color: _kRedPrimary,
        icon: Icons.warning_amber_rounded,
      );
    }

    if (pendientes > 0) {
      return (
        headline: 'Tienes $pendientes tratamiento${pendientes == 1 ? '' : 's'} en seguimiento',
        detail: ultimoDiagnostico != null
            ? 'Último diagnóstico: $ultimoDiagnostico. Continúa con las indicaciones de tu odontóloga.'
            : 'Hay tratamientos que requieren seguimiento. Revisa tu historial para más detalles.',
        color: const Color(0xFFF59E0B),
        icon: Icons.pending_actions_rounded,
      );
    }

    if (diasDesdeUltima != null && diasDesdeUltima > 180) {
      return (
        headline: 'Hace ${(diasDesdeUltima / 30).floor()} meses de tu última visita',
        detail: 'Se recomienda una revisión cada 6 meses. Considera agendar una cita de control.',
        color: const Color(0xFFF59E0B),
        icon: Icons.event_repeat_rounded,
      );
    }

    return (
      headline: 'Tu salud dental va bien',
      detail: ultimoDiagnostico != null
          ? 'Último diagnóstico: $ultimoDiagnostico. No hay alertas ni tratamientos pendientes.'
          : 'No hay alertas ni tratamientos pendientes registrados en tu historial.',
      color: const Color(0xFF16A34A),
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final blue = isDark ? _kBlueLight : _kBluePrimary;

    Widget content;
    if (_loading) {
      content = SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: blue),
        ),
      );
    } else if (_error != null) {
      content = Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: _kRedLight),
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      final c = _conclusion();
      content = Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.color.withOpacity(0.12),
            ),
            child: Icon(c.icon, color: c.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.headline,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.detail,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MedicalHistoryTab())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? _kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? _kDarkBorder : const Color(0xFFE0E7FF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : blue.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

// ── Dental Tip Card ──────────────────────────────────────────────
class _DentalTipCard extends StatelessWidget {
  final bool isDark;
  const _DentalTipCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final blue = isDark ? _kBlueLight : _kBluePrimary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _kDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: blue.withOpacity(isDark ? 0.2 : 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : blue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blue.withOpacity(0.1),
            ),
            child: Icon(Icons.tips_and_updates_rounded,
                color: blue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cepillado correcto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Cepillate 2 minutos, 2 veces al dia para mantener tu salud dental.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Discounts Section
// ════════════════════════════════════════════════════════════════
class _DiscountsSection extends StatefulWidget {
  final AuthProvider auth;
  const _DiscountsSection({required this.auth});

  @override
  State<_DiscountsSection> createState() => _DiscountsSectionState();
}

class _DiscountsSectionState extends State<_DiscountsSection> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.auth.fetchDiscounts();
  }

  @override
  void didUpdateWidget(covariant _DiscountsSection old) {
    super.didUpdateWidget(old);
    if (old.auth != widget.auth) {
      _future = widget.auth.fetchDiscounts();
    }
  }

  String _formatValue(Map<String, dynamic> d) {
    final tipo = d['tipo']?.toString().toLowerCase() ?? '';
    final valor =
        double.tryParse(d['valor']?.toString() ?? '') ?? 0.0;
    if (tipo.contains('porcentaje')) {
      return '${valor.toStringAsFixed(valor.truncateToDouble() == valor ? 0 : 1)}%';
    }
    return '\$${valor.toStringAsFixed(valor.truncateToDouble() == valor ? 0 : 2)}';
  }

  String _formatRange(Map<String, dynamic> d) {
    final s = d['fecha_inicio']?.toString();
    final e = d['fecha_fin']?.toString();
    if (s != null && s.isNotEmpty && e != null && e.isNotEmpty) {
      return '$s - $e';
    }
    if (s != null && s.isNotEmpty) return 'Desde $s';
    if (e != null && e.isNotEmpty) return 'Hasta $e';
    return 'Vigencia desconocida';
  }

  Widget _redBanner(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kRedPrimary, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kRedPrimary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _redBanner(const SizedBox(
            height: 60,
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          ));
        }

        if (snap.hasError || (snap.data ?? []).isEmpty) {
          final isError = snap.hasError;
          return _redBanner(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Descuentos',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isError
                    ? 'No se pudieron cargar los descuentos'
                    : 'Aun no hay descuentos',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isError
                    ? 'Revisa tu conexion e intenta nuevamente.'
                    : 'Pronto encontraras las mejores ofertas aqui.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 13,
                ),
              ),
            ],
          ));
        }

        final discounts = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descuentos disponibles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...discounts.map((d) {
              final label = _formatValue(d);
              final range = _formatRange(d);
              final appliesTo = d['aplica_a']?.toString() ??
                  'Todos los procedimientos';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? _kDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? _kDarkBorder
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
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
                                d['nombre']?.toString() ?? 'Descuento',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    _kRedPrimary.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: _kRedPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((d['descripcion']?.toString() ?? '')
                            .isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            d['descripcion'].toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          appliesTo,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          range,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Feature Card
// ════════════════════════════════════════════════════════════════
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
    final isDark = context.isDark;
    final blue = isDark ? _kBlueLight : _kBluePrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? _kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? _kDarkBorder : const Color(0xFFE0E7FF),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : blue.withOpacity(0.09),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        blue.withOpacity(0.16),
                        blue.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Icon(icon, size: 32, color: blue),
                ),
                if (showBadge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _kRedPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? _kDarkCard : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Quick Access All Screen
// ════════════════════════════════════════════════════════════════
class _QuickAccessAllScreen extends StatelessWidget {
  const _QuickAccessAllScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : _kLightBg,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Accesos rapidos'),
        centerTitle: true,
        backgroundColor: isDark ? _kBlueDeep : _kBluePrimary,
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
                  color: isDark ? _kDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? _kDarkBorder
                        : const Color(0xFFE0E7FF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encuentra rapidamente las funciones mas importantes de tu cuenta.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade600,
                        fontSize: 13,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                  children: [
                    _FeatureCard(
                      title: 'Proxima cita',
                      icon: Icons.calendar_today_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const AppointmentsScreen()),
                      ),
                    ),
                    _FeatureCard(
                      title: 'Historial',
                      icon: Icons.folder_open_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const MedicalHistoryTab()),
                      ),
                    ),
                    _FeatureCard(
                      title: 'Pagos',
                      icon: Icons.credit_card_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const PaymentsScreen()),
                      ),
                    ),
                    _FeatureCard(
                      title: 'Chat doctor',
                      icon: Icons.chat_bubble_outline_rounded,
                      showBadge: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const ChatListScreen()),
                      ),
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

// ════════════════════════════════════════════════════════════════
//  Pantallas secundarias
// ════════════════════════════════════════════════════════════════
class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : _kLightBg,
      appBar: AppBar(
        title: const Text('Recetas'),
        backgroundColor: isDark ? _kBlueDeep : _kBluePrimary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 72,
                  color: isDark
                      ? const Color(0xFF475569)
                      : Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aun no hay recetas disponibles',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : Colors.grey,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final service = AppointmentService();
      final appointments = await service.getUserAppointments();

      final results = await Future.wait(appointments.map((apt) async {
        final id = (apt['id_backend'] ?? apt['id'])?.toString();
        if (id == null || id.startsWith('local_')) return null;
        final payment = await service.getAppointmentPayment(id);
        if (payment == null) return null;
        return {'appointment': apt, 'payment': payment};
      }));

      final list = results.whereType<Map<String, dynamic>>().toList();
      list.sort((a, b) {
        final da = DateTime.tryParse(
                (a['payment'] as Map)['fecha']?.toString() ?? '') ??
            DateTime(1900);
        final db = DateTime.tryParse(
                (b['payment'] as Map)['fecha']?.toString() ?? '') ??
            DateTime(1900);
        return db.compareTo(da);
      });

      setState(() { _payments = list; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  Color _statusColor(String estadoValidacion) {
    switch (estadoValidacion.toUpperCase()) {
      case 'CONFIRMADO':
      case 'APROBADO':
        return const Color(0xFF16A34A);
      case 'RECHAZADO':
        return _kRedPrimary;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String estadoValidacion) {
    switch (estadoValidacion.toUpperCase()) {
      case 'CONFIRMADO':
      case 'APROBADO':
        return 'Confirmado';
      case 'RECHAZADO':
        return 'Rechazado';
      default:
        return 'Por confirmar';
    }
  }

  String _doctorName(Map<String, dynamic> apt) {
    final odontologoObj = apt['odontologo'];
    return apt['nombre_odontologo']?.toString() ??
        apt['doctor']?.toString() ??
        (odontologoObj is Map
            ? '${odontologoObj['nombre'] ?? ''} ${odontologoObj['apellido'] ?? ''}'.trim()
            : null) ??
        'Odontólogo';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : _kLightBg,
      appBar: AppBar(
        title: const Text('Pagos'),
        backgroundColor: isDark ? _kBlueDeep : _kBluePrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus pagos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: isDark ? _kBlueLight : _kBluePrimary,
                      ),
                    ),
                  )
                else if (_error != null)
                  _EmptyState(
                    isDark: isDark,
                    icon: Icons.error_outline_rounded,
                    message: _error!,
                    iconColor: _kRedLight,
                  )
                else if (_payments.isEmpty)
                  _EmptyState(
                    isDark: isDark,
                    icon: Icons.receipt_long_rounded,
                    message: 'Aún no has realizado ningún pago',
                  )
                else
                  ..._payments.map((item) {
                    final apt = item['appointment'] as Map<String, dynamic>;
                    final payment = item['payment'] as Map<String, dynamic>;
                    final estadoValidacion =
                        payment['estado_validacion']?.toString() ?? 'POR_CONFIRMAR';
                    final color = _statusColor(estadoValidacion);
                    final monto = double.tryParse(
                            (payment['monto_final'] ?? payment['monto'])
                                ?.toString() ??
                            '') ??
                        0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentDetailScreen(
                              payment: payment,
                              appointment: apt,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? _kDarkCard : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? _kDarkBorder
                                  : const Color(0xFFE0E7FF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.12),
                                ),
                                child: Icon(Icons.receipt_long_rounded,
                                    color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment['servicio']?.toString() ??
                                          'Pago de cita',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${payment['fecha'] ?? apt['fecha'] ?? ''}  ·  ${_doctorName(apt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'S/ ${monto.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _statusLabel(estadoValidacion),
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 28),
                Text(
                  'Pago con Yape',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Escanea este QR con tu app de Yape para realizar el pago de tu cita.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset('assets/qryape.png',
                        width: 220, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Asegúrate de enviar el monto correcto y conservar el comprobante.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Payment Detail Screen
// ════════════════════════════════════════════════════════════════
class PaymentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Map<String, dynamic> appointment;

  const PaymentDetailScreen({
    Key? key,
    required this.payment,
    required this.appointment,
  }) : super(key: key);

  String _doctorName() {
    final odontologoObj = appointment['odontologo'];
    return appointment['nombre_odontologo']?.toString() ??
        appointment['doctor']?.toString() ??
        (odontologoObj is Map
            ? '${odontologoObj['nombre'] ?? ''} ${odontologoObj['apellido'] ?? ''}'.trim()
            : null) ??
        'Odontólogo';
  }

  Color _statusColor(String estadoValidacion) {
    switch (estadoValidacion.toUpperCase()) {
      case 'CONFIRMADO':
      case 'APROBADO':
        return const Color(0xFF16A34A);
      case 'RECHAZADO':
        return _kRedPrimary;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String estadoValidacion) {
    switch (estadoValidacion.toUpperCase()) {
      case 'CONFIRMADO':
      case 'APROBADO':
        return 'Confirmado';
      case 'RECHAZADO':
        return 'Rechazado';
      default:
        return 'Por confirmar';
    }
  }

  Widget _row(String label, String? value, bool isDark) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final estadoValidacion =
        payment['estado_validacion']?.toString() ?? 'POR_CONFIRMAR';
    final color = _statusColor(estadoValidacion);
    final monto = double.tryParse(
            (payment['monto_final'] ?? payment['monto'])?.toString() ?? '') ??
        0.0;
    final comprobante = payment['comprobante']?.toString();

    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : _kLightBg,
      appBar: AppBar(
        title: const Text('Detalle de pago'),
        backgroundColor: isDark ? _kBlueDeep : _kBluePrimary,
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? _kDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? _kDarkBorder : const Color(0xFFE0E7FF),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'S/ ${monto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(estadoValidacion),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? _kDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? _kDarkBorder : const Color(0xFFE0E7FF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Servicio', payment['servicio']?.toString(), isDark),
                    _row('Fecha', payment['fecha']?.toString(), isDark),
                    _row('Método de pago', payment['metodo_pago']?.toString(),
                        isDark),
                    _row('Descripción', payment['descripcion']?.toString(),
                        isDark),
                    _row('Cita', '${appointment['fecha'] ?? ''} · ${appointment['hora'] ?? ''}',
                        isDark),
                    _row('Odontólogo', _doctorName(), isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Comprobante',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              if (comprobante != null && comprobante.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    comprobante,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _EmptyState(
                      isDark: isDark,
                      icon: Icons.broken_image_outlined,
                      message: 'No se pudo cargar el comprobante',
                    ),
                  ),
                )
              else
                _EmptyState(
                  isDark: isDark,
                  icon: Icons.receipt_long_outlined,
                  message: 'Aún no se ha subido un comprobante para este pago',
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// MedicalHistoryTab is now imported from '../profile/medical_info_screen.dart'
