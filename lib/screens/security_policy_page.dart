import 'package:flutter/material.dart';

class SecurityPolicyPage extends StatelessWidget {
  const SecurityPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de seguridad'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Seguridad',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Última actualización: 15 de enero de 2024',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Compromiso con la Seguridad',
              'En Clínica Dental Namay estamos comprometidos a proteger sus datos y garantizar una experiencia segura en nuestra aplicación móvil. La seguridad de su información es nuestra prioridad.',
            ),
            _buildSection(
              '2. Encriptación de Datos',
              'Utilizamos encriptación de extremo a extremo (E2E) para proteger:',
              items: [
                'Comunicaciones médicas entre pacientes y doctores',
                'Datos personales en tránsito',
                'Contraseñas y credenciales de acceso',
                'Información financiera y de pagos',
              ],
            ),
            _buildSection(
              '3. Autenticación y Control de Acceso',
              'Implementamos múltiples capas de seguridad:',
              items: [
                'Autenticación con JWT (JSON Web Tokens)',
                'Verificación de email en dos pasos',
                'Renovación automática de sesiones',
                'Cierre automático de sesión después de inactividad',
                'Control de acceso basado en roles (RBAC)',
              ],
            ),
            _buildSection(
              '4. Almacenamiento Seguro',
              'Su información se almacena en:',
              items: [
                'Servidores certificados ISO 27001',
                'Bases de datos encriptadas',
                'Copias de seguridad automáticas diarias',
                'Cumplimiento con regulaciones de protección de datos (RGPD/PDPA)',
              ],
            ),
            _buildSection(
              '5. Protección de Datos Médicos',
              'Los datos médicos sensibles están protegidos bajo:',
              items: [
                'Estándares HIPAA (Health Insurance Portability and Accountability Act)',
                'Acceso restringido solo a profesionales autorizados',
                'Registro de auditoría de todas las consultas',
                'Anonimización de datos cuando sea posible',
                'Retención de datos según normativa legal (7 años)',
              ],
            ),
            _buildSection(
              '6. Política de Contraseñas',
              'Los usuarios deben cumplir con:',
              items: [
                'Mínimo 8 caracteres',
                'Incluir mayúsculas, minúsculas, números y símbolos',
                'No reutilizar contraseñas anteriores',
                'Cambio recomendado cada 90 días',
                'Nunca compartir su contraseña con otros usuarios',
              ],
            ),
            _buildSection(
              '7. Auditoría y Monitoreo',
              'Realizamos monitoreo continuo:',
              items: [
                'Registro de todos los accesos al sistema',
                'Detección de actividades sospechosas',
                'Alertas en tiempo real de accesos inusuales',
                'Análisis diario de registros de seguridad',
                'Revisión trimestral de vulnerabilidades',
              ],
            ),
            _buildSection(
              '8. Respuesta ante Incidentes',
              'En caso de un incidente de seguridad:',
              items: [
                'Notificaremos a los usuarios afectados en 24 horas',
                'Proporcionaremos detalles sobre el incidente',
                'Ofreceremos monitoreo gratuito de crédito por 12 meses',
                'Implementaremos medidas preventivas adicionales',
              ],
            ),
            _buildSection(
              '9. Acceso de Terceros',
              'Solo autorizamos acceso a terceros para:',
              items: [
                'Proveedores de servicios certificados',
                'Autoridades judiciales (con orden judicial)',
                'Profesionales médicos referidos por usted',
                'Servicios de pago (con datos mínimos)',
              ],
              footer: 'Nunca vendemos ni compartimos sus datos sin consentimiento explícito.',
            ),
            _buildSection(
              '10. Derechos del Usuario',
              'Usted tiene derecho a:',
              items: [
                'Acceder a todos sus datos personales almacenados',
                'Rectificar información inexacta',
                'Solicitar la eliminación de sus datos',
                'Portabilidad de datos a otros servicios',
                'Retirar el consentimiento en cualquier momento',
              ],
            ),
            _buildSection(
              '11. Actualizaciones de Seguridad',
              'La aplicación recibe:',
              items: [
                'Actualizaciones de seguridad automáticas',
                'Parches de vulnerabilidades en 24-48 horas',
                'Pruebas de penetración anuales',
                'Auditorías externas de seguridad semestrales',
              ],
            ),
            _buildSection(
              '12. Contacto de Seguridad',
              'Reportar problemas de seguridad:',
              items: [
                '📧 security@clinicadentalnamay.com',
                '📞 Línea de seguridad: +51 999 888 777',
                '⚠️ Reporte inmediatamente cualquier sospecha',
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Su confianza es fundamental para nosotros.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _buildSection(
    String title,
    String description, {
    List<String>? items,
    String? footer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        if (items != null) ...[
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $item',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF1E3A8A).withOpacity(0.3),
              ),
            ),
            child: Text(
              footer,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
