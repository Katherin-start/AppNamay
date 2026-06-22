import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final userName = profile?['nombre']?.toString() ??
      profile?['name']?.toString() ??
      auth.userEmail?.split('@').first ??
      'Usuario';
    final userEmail = (profile?['correo'] ?? profile?['email'] ?? auth.userEmail)
      ?.toString() ??
      'correo@ejemplo.com';
    final photoUrl = profile?['foto_perfil']?.toString() ??
      profile?['fotoPerfil']?.toString();
    final userPhone = profile?['telefono']?.toString() ??
      profile?['phone']?.toString() ??
      'Sin registrar';
    final userDni = profile?['dni']?.toString().isNotEmpty == true
      ? profile!['dni'].toString()
      : 'Sin registrar';
    final userRole = profile?['rol']?.toString() ??
      profile?['role']?.toString() ??
      profile?['rol_id']?.toString();
    final showUserRole = userRole != null &&
      userRole.isNotEmpty &&
      userRole.toLowerCase() != 'paciente';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con gradiente y avatar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withOpacity(0.78)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Mi perfil',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white,
                            foregroundImage: photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Icon(Icons.person, size: 50, color: primary)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt, size: 16, color: primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                    if (showUserRole) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          userRole!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información personal
                    _SectionLabel(title: 'Información personal'),
                    const SizedBox(height: 10),
                    _GroupedCard(
                      children: [
                        _InfoRow(icon: Icons.badge_outlined, label: 'Nombre', value: userName),
                        _InfoRow(icon: Icons.email_outlined, label: 'Correo electrónico', value: userEmail),
                        _InfoRow(icon: Icons.credit_card_outlined, label: 'DNI', value: userDni),
                        _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: userPhone, isLast: true),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Configuración
                    _SectionLabel(title: 'Configuración'),
                    const SizedBox(height: 10),
                    _GroupedCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.edit_outlined,
                          title: 'Editar perfil',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.lock_outline,
                          title: 'Cambiar contraseña',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.notifications_outlined,
                          title: 'Notificaciones',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.help_outline,
                          title: 'Ayuda y soporte',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Cerrar sesión
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoggingOut
                            ? null
                            : () async {
                                final currentContext = context;
                                setState(() => _isLoggingOut = true);
                                try {
                                  await auth.logout();
                                  if (!mounted) return;
                                  Navigator.pushNamedAndRemoveUntil(
                                    currentContext,
                                    '/login',
                                    (route) => false,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(currentContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al cerrar sesión: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() => _isLoggingOut = false);
                                }
                              },
                        icon: _isLoggingOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.logout),
                        label: Text(_isLoggingOut ? 'Cerrando...' : 'Cerrar sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupedCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
      ],
    );
  }
}
