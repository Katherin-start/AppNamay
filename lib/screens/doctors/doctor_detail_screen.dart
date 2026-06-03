import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  late Future<Map<String, dynamic>> _doctorFuture;
  List<Map<String, dynamic>> _reviews = [];
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final doctorId = widget.doctor['id']?.toString();
    _doctorFuture = _loadDoctorDetail(doctorId);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadDoctorDetail(String? doctorId) async {
    if (doctorId == null || doctorId.isEmpty) {
      throw Exception('ID de odontólogo inválido');
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final detail = await auth.fetchDoctorDetail(doctorId);
    final reviews = detail['reseñas'] ?? detail['reviews'] ?? [];
    if (reviews is List) {
      _reviews = reviews
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return detail;
  }

  Future<void> _submitReview() async {
    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      _showSnackBar('Escribe un comentario antes de enviar tu reseña.');
      return;
    }

    final doctorId = widget.doctor['id']?.toString();
    if (doctorId == null || doctorId.isEmpty) {
      _showSnackBar('No se pudo identificar al odontólogo.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final review = await auth.submitDoctorReview(doctorId, _rating, comment);
      _showSnackBar('Reseña enviada correctamente.');
      _reviewController.clear();
      setState(() {
        _rating = 5;
        _reviews.insert(0, review);
      });
    } catch (e) {
      _showSnackBar('Error al enviar reseña: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = review['rating']?.toString() ?? '0';
    final comentario = review['comentario']?.toString() ?? '';
    final paciente = review['paciente'] as Map<String, dynamic>? ?? review['pacientes'] as Map<String, dynamic>?;
    final pacienteNombre = paciente != null
        ? '${paciente['nombre'] ?? ''} ${paciente['apellido'] ?? ''}'.trim()
        : review['paciente_nombre']?.toString() ?? 'Paciente';
    final fecha = review['creado_en']?.toString() ?? review['created_at']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pacienteNombre.isNotEmpty ? pacienteNombre : 'Paciente',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) {
                    final starIndex = index + 1;
                    final ratingValue = int.tryParse(rating) ?? 0;
                    return Icon(
                      starIndex <= ratingValue ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                      size: 18,
                    );
                  },
                ),
              ),
            ],
          ),
          if (fecha.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              fecha,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ],
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comentario,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final nombre = doctor['nombre']?.toString() ?? 'Odontólogo';
    final apellido = doctor['apellido']?.toString() ?? '';
    final foto = doctor['foto_perfil']?.toString() ?? doctor['fotoPerfil']?.toString();
    final rol = doctor['rol']?.toString() ?? doctor['role']?.toString() ?? 'Odontólogo';
    final email = doctor['email']?.toString() ?? doctor['correo']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del odontólogo'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _doctorFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No se pudo cargar los datos del odontólogo:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                  ),
                ),
              );
            }

            final doctorDetail = snapshot.data ?? doctor;
            final detailName = doctorDetail['nombre']?.toString() ?? nombre;
            final detailApellido = doctorDetail['apellido']?.toString() ?? apellido;
            final detailFoto = doctorDetail['foto_perfil']?.toString() ?? doctorDetail['fotoPerfil']?.toString() ?? foto;
            final detailRol = doctorDetail['rol']?.toString() ?? doctorDetail['role']?.toString() ?? rol;
            final detailEmail = doctorDetail['email']?.toString() ?? doctorDetail['correo']?.toString() ?? email;
            final detailBiografia = doctorDetail['biografia']?.toString().trim() ?? '';
            final reviewsCount = _reviews.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.shade200,
                        foregroundImage: detailFoto != null && detailFoto.isNotEmpty ? NetworkImage(detailFoto) : null,
                        child: detailFoto == null || detailFoto.isEmpty
                            ? const Icon(Icons.person, size: 36, color: Color(0xFF4F46E5))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$detailName${detailApellido.isNotEmpty ? ' $detailApellido' : ''}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detailRol,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                            ),
                            if (detailEmail.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      detailEmail,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Biografía',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      detailBiografia.isNotEmpty
                          ? detailBiografia
                          : 'El odontólogo aún no ha agregado una biografía.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Dejar una reseña',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valoración',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                            (index) {
                              final starIndex = index + 1;
                              return IconButton(
                                onPressed: () {
                                  setState(() => _rating = starIndex);
                                },
                                icon: Icon(
                                  starIndex <= _rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber.shade700,
                                ),
                                splashRadius: 22,
                                padding: EdgeInsets.zero,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _reviewController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu comentario aquí...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF4F46E5).withOpacity(0.60),
                              disabledForegroundColor: Colors.white.withOpacity(0.92),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Enviar reseña'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Comentarios ($reviewsCount)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        'Aún no hay comentarios para este odontólogo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.5),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildReviewItem(_reviews[index]);
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
