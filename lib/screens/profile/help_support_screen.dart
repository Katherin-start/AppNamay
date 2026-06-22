import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'q': '¿Cómo reservo una cita?',
      'a': 'Ve a la pestaña de Citas y toca "Agendar cita". Elige especialista, '
          'fecha, horario disponible, el servicio y el método de pago, y confirma.',
    },
    {
      'q': '¿Cómo cancelo o reagendo una cita?',
      'a': 'En "Mis citas", abre la cita y usa el ícono de papelera para cancelarla '
          'o el de calendario para reagendarla. Las citas pasadas no se pueden modificar.',
    },
    {
      'q': '¿Qué métodos de pago aceptan?',
      'a': 'Puedes pagar con Yape (sube la captura de tu pago) o en efectivo directamente '
          'en el consultorio el día de tu cita.',
    },
    {
      'q': '¿Cómo contacto a mi odontólogo?',
      'a': 'Usa la sección de Chat para escribirle directamente a tu especialista o al '
          'personal de la clínica.',
    },
    {
      'q': '¿Dónde veo mi historial clínico?',
      'a': 'En tu perfil encontrarás la sección de información médica con tu historial '
          'clínico y tratamientos registrados.',
    },
    {
      'q': '¿Olvidé mi contraseña, qué hago?',
      'a': 'Desde la pantalla de inicio de sesión selecciona "¿Olvidaste tu contraseña?" '
          'para recibir un correo de recuperación.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y soporte'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Preguntas frecuentes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: List.generate(_faqs.length, (i) {
                    final faq = _faqs[i];
                    return Column(
                      children: [
                        ExpansionTile(
                          title: Text(
                            faq['q']!,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedAlignment: Alignment.topLeft,
                          children: [
                            Text(
                              faq['a']!,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                        if (i != _faqs.length - 1)
                          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
