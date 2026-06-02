import 'package:flutter/material.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailScreen({Key? key, required this.appointmentId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de cita'),
      ),
      body: const Center(
        child: Text('Detalle de la cita'),
      ),
    );
  }
}
