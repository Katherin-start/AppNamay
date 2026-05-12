import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos de usuario'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y Condiciones de Uso',
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
              '1. Aceptación de los Términos',
              'Al descargar, registrarse o utilizar la aplicación móvil "Dental Namay", usted acepta cumplir con estos Términos y Condiciones. Si no está de acuerdo con alguna parte, no debe utilizar la aplicación.',
            ),
            _buildSection(
              '2. Descripción del Servicio',
              'La aplicación permite a los pacientes de nuestra clínica dental:',
              items: [
                'Solicitar y gestionar citas médicas',
                'Comunicarse con su odontólogo a través de chat',
                'Acceder a su historial clínico y tratamientos',
                'Recibir recordatorios de citas y notificaciones importantes',
                'Realizar pagos y consultar su estado de cuenta',
              ],
            ),
            _buildSection(
              '3. Privacidad y Datos Personales',
              'Su privacidad es importante para nosotros. Al usar la aplicación, usted acepta la recopilación y uso de su información según nuestra Política de Privacidad, que incluye:',
              items: [
                'Datos personales: Nombre, email, teléfono, DNI, dirección',
                'Datos médicos: Historial clínico, tratamientos, alergias',
                'Datos de uso: Interacciones con la aplicación, citas, mensajes',
                'Datos de dispositivo: Token de notificaciones, versión del sistema',
              ],
              footer: 'Nunca compartiremos sus datos médicos con terceros sin su consentimiento explícito.',
            ),
            _buildSection(
              '4. Seguridad de la Información',
              'Implementamos medidas de seguridad técnicas y organizativas para proteger sus datos:',
              items: [
                '✅ Encriptación de extremo a extremo en las comunicaciones',
                '✅ Autenticación segura con JWT',
                '✅ Almacenamiento seguro de datos en servidores certificados',
                '✅ Acceso restringido a información médica sensible',
                '✅ Registro de auditoría de todas las acciones en el sistema',
              ],
            ),
            _buildSection(
              '5. Responsabilidades del Usuario',
              'Usted se compromete a:',
              items: [
                '✅ Proporcionar información veraz y actualizada',
                '✅ No compartir sus credenciales de acceso',
                '✅ Utilizar la aplicación de manera ética y respetuosa',
                '✅ Reportar cualquier problema de seguridad inmediatamente',
                '❌ No intentar vulnerar la seguridad del sistema',
                '❌ No utilizar la aplicación para acosar a profesionales o pacientes',
              ],
            ),
            _buildSection(
              '6. Cancelación de Citas',
              'Política de cancelación:',
              items: [
                'Cancelación con 24+ horas de anticipación: Sin costo',
                'Cancelación entre 12-24 horas: Cargo del 30% de la consulta',
                'Cancelación con menos de 12 horas o inasistencia: Cargo del 100%',
                '3 inasistencias acumuladas limitarán su capacidad de agendar citas por 30 días',
              ],
            ),
            _buildSection(
              '7. Propiedad Intelectual',
              'Todo el contenido de la aplicación, incluyendo logos, textos, imágenes, diseño y código fuente, es propiedad exclusiva de Clínica Dental Namay. No está permitido copiar, modificar o distribuir el contenido sin autorización.',
            ),
            _buildSection(
              '8. Limitación de Responsabilidad',
              'La aplicación es una herramienta de gestión y comunicación. Clínica Dental Namay no se responsabiliza por:',
              items: [
                'Problemas técnicos fuera de nuestro control',
                'Decisiones médicas tomadas basadas únicamente en el chat',
                'Retrasos en citas por causas de fuerza mayor',
              ],
              footer: 'En caso de emergencia dental, siempre debe acudir personalmente a la clínica o llamar a urgencias.',
            ),
            _buildSection(
              '9. Modificaciones',
              'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios serán notificados a través de la aplicación y se considerarán aceptados si continúa usando el servicio después de 30 días de la notificación.',
            ),
            _buildSection(
              '10. Ley Aplicable',
              'Estos términos se rigen por las leyes aplicables. Cualquier disputa será resuelta en los tribunales competentes.',
            ),
            _buildSection(
              '11. Contacto',
              'Para preguntas sobre estos términos, contáctenos:',
              items: [
                '📧 Email: legal@clinicadentalnamay.com',
                '📞 Teléfono: +51 123 456 789',
                '📍 Dirección: Av. Principal 123, Lima',
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Al registrarse, usted acepta estos términos y condiciones.',
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
