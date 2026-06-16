class Appointment {
  final String? id;
  final String fecha;
  final String hora;
  final String idPacienteUuid;
  final String idOdontologo;
  final String estado; // pendiente, programada, confirmada, en_curso, cancelada
  final DateTime? creadoEn;
  final String? notaCancelacion;
  final bool procesada;
  final String? procesadaPorRol; // 'cajero' | 'recepcionista'
  final String? procesadaPorId;
  final DateTime? procesadaEn;

  Appointment({
    this.id,
    required this.fecha,
    required this.hora,
    required this.idPacienteUuid,
    required this.idOdontologo,
    required this.estado,
    this.creadoEn,
    this.notaCancelacion,
    this.procesada = false,
    this.procesadaPorRol,
    this.procesadaPorId,
    this.procesadaEn,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      fecha: json['fecha'],
      hora: json['hora'],
      idPacienteUuid: json['id_paciente_uuid'],
      idOdontologo: json['id_odontologo'],
      estado: json['estado'],
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en']) : null,
      notaCancelacion: json['nota_cancelacion'],
      procesada: json['procesada'] == true || (json['procesada']?.toString() == '1'),
      procesadaPorRol: json['procesada_por_rol'],
      procesadaPorId: json['procesada_por_id'],
      procesadaEn: json['procesada_en'] != null ? DateTime.parse(json['procesada_en']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'hora': hora,
      'id_paciente_uuid': idPacienteUuid,
      'id_odontologo': idOdontologo,
      'estado': estado,
      'creado_en': creadoEn?.toIso8601String(),
      'nota_cancelacion': notaCancelacion,
      'procesada': procesada,
      'procesada_por_rol': procesadaPorRol,
      'procesada_por_id': procesadaPorId,
      'procesada_en': procesadaEn?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Appointment(id: $id, fecha: $fecha, hora: $hora, doctor: $idOdontologo, estado: $estado)';
}

class Payment {
  final String? id;
  final String idPacienteUuid;
  final String idCita;
  final double monto;
  final double montoFinal;
  final String metodoPago; // Yape, Efectivo
  final String estado; // por_pagar, pendiente
  final String estadoValidacion; // POR_CONFIRMAR
  final String fecha;
  final String? servicio;
  final String? descripcion;
  final String? qrImagen;
  final String? comprobante;
  final DateTime? creadoEn;

  Payment({
    this.id,
    required this.idPacienteUuid,
    required this.idCita,
    required this.monto,
    required this.montoFinal,
    required this.metodoPago,
    required this.estado,
    required this.estadoValidacion,
    required this.fecha,
    this.servicio,
    this.descripcion,
    this.qrImagen,
    this.comprobante,
    this.creadoEn,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      idPacienteUuid: json['id_paciente_uuid'],
      idCita: json['id_cita'],
      monto: (json['monto'] as num).toDouble(),
      montoFinal: (json['monto_final'] as num).toDouble(),
      metodoPago: json['metodo_pago'],
      estado: json['estado'],
      estadoValidacion: json['estado_validacion'],
      fecha: json['fecha'],
      servicio: json['servicio'],
      descripcion: json['descripcion'],
      qrImagen: json['qr_imagen'],
      comprobante: json['comprobante'],
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_paciente_uuid': idPacienteUuid,
      'id_cita': idCita,
      'monto': monto,
      'monto_final': montoFinal,
      'metodo_pago': metodoPago,
      'estado': estado,
      'estado_validacion': estadoValidacion,
      'fecha': fecha,
      'servicio': servicio,
      'descripcion': descripcion,
      'qr_imagen': qrImagen,
      'comprobante': comprobante,
      'creado_en': creadoEn?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Payment(id: $id, monto: $monto, metodo: $metodoPago, estado: $estado)';
}

class AppointmentResponse {
  final Appointment appointment;
  final Payment payment;
  final String? message;
  final String code;

  AppointmentResponse({
    required this.appointment,
    required this.payment,
    this.message,
    required this.code,
  });

  factory AppointmentResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentResponse(
      appointment: Appointment.fromJson(json['appointment']),
      payment: Payment.fromJson(json['payment']),
      message: json['message'],
      code: json['code'],
    );
  }
}

class AppointmentSlotSuggestion {
  final String fecha;
  final String hora;
  final String nota;

  AppointmentSlotSuggestion({
    required this.fecha,
    required this.hora,
    required this.nota,
  });

  factory AppointmentSlotSuggestion.fromJson(Map<String, dynamic> json) {
    return AppointmentSlotSuggestion(
      fecha: json['fecha'],
      hora: json['hora'],
      nota: json['nota'],
    );
  }
}
