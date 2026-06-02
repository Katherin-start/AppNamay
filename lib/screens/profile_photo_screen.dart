import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/backend_config.dart';
import '../providers/auth_provider.dart';

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  bool _isPicking = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una foto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Subir foto al endpoint del backend
      String? publicUrl;
      try {
        final token = authProvider.getAuthToken();
        if (token == null || token.isEmpty) {
          throw Exception('No hay token de autenticación');
        }
        
        // Debug: imprimir primeros caracteres del token
        // ignore: avoid_print
        print('ProfilePhotoScreen: token length=${token.length}, prefix=${token.substring(0, (token.length > 20 ? 20 : token.length))}...');
        
        final uri = Uri.parse('${BackendConfig.apiBaseUrl}/mobile/profile/photo');
        
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });
        
        // Agregar archivo como campo "foto"
        final filePath = _selectedImage!.path;
        final mimeType = _getMimeType(filePath);
        final filename = _getFileName(filePath);

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            filePath,
            filename: filename,
            contentType: MediaType(
              mimeType.split('/').first,
              mimeType.split('/').last,
            ),
          ),
        );
        
        // ignore: avoid_print
        print('ProfilePhotoScreen: uploading file $filename with mimeType=$mimeType');
        
        final response = await request.send();
        final responseData = await response.stream.toBytes();
        
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(utf8.decode(responseData));
          publicUrl = jsonResponse['foto_perfil'];
          // ignore: avoid_print
          print('ProfilePhotoScreen: uploaded via backend, publicUrl=$publicUrl');
        } else {
          final errorBody = utf8.decode(responseData);
          // ignore: avoid_print
          print('ProfilePhotoScreen: backend error ${response.statusCode}: $errorBody');
          throw Exception('Error en subida: $errorBody');
        }
      } catch (e) {
        // Si falla la subida, loguear el error
        // ignore: avoid_print
        print('ProfilePhotoScreen: upload error: $e');
        publicUrl = null;
      }

      // Si la subida falló, mostrar error
      if (publicUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir la foto al servidor'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Actualizar perfil con la URL pública
      final payload = {'foto_perfil': publicUrl};
      // ignore: avoid_print
      print('ProfilePhotoScreen: updating profile with payload=$payload');
      final success = await authProvider.updateProfile(payload);
      if (success) {
        await authProvider.fetchProfile();
      }
      // ignore: avoid_print
      print('ProfilePhotoScreen: updateProfile returned $success');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ??
                    'Error al actualizar foto de perfil',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  String _getFileName(String filePath) {
    final parts = filePath.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Foto de perfil',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/logo_appnamay.png',
                  height: 100,
                  width: 100,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Completa tu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sube una foto para que otros pacientes te conozcan mejor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Preview de la foto o placeholder
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(90),
                    border: Border.all(
                      color: const Color(0xFF1E3A8A).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(90),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 60,
                              color: Color(0xFF1E3A8A),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Sin foto',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
              // Botón para galería
              ElevatedButton.icon(
                onPressed: _isUploading || _isPicking ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Galería'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Botón para cámara
              OutlinedButton.icon(
                onPressed: _isUploading || _isPicking ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tomar foto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón para subir
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadPhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Subir y continuar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Botón para saltar
              TextButton(
                onPressed: _isUploading
                    ? null
                    : () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text(
                  'Saltar por ahora',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
