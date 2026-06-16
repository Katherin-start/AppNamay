# 📱 IMPLEMENTACIÓN: Persistencia de Citas en Flutter

**Archivo:** `d:\App_Namay\dental_namay_app`  
**Estado:** ✅ NUEVOS SERVICIOS Y PROVIDERS CREADOS  
**Próximo:** Actualizar book_appointment_screen.dart

---

## 📦 ARCHIVOS CREADOS

### 1. `lib/services/storage_service.dart` ✅
- Manejo de almacenamiento local con SharedPreferences
- Funciones para guardar, obtener, actualizar, eliminar citas
- Persistencia de tokens de autenticación
- Métodos:
  - `saveAppointment()` - Guardar cita localmente
  - `getAppointments()` - Obtener todas las citas
  - `updateAppointment()` - Actualizar cita
  - `deleteAppointment()` - Eliminar cita

### 2. `lib/services/appointment_service.dart` ✅
- Comunicación con backend
- Sincronización offline-first
- Métodos:
  - `createAppointment()` - Crear en backend
  - `getUserAppointments()` - Sincronizar citas
  - `cancelAppointment()` - Cancelar cita
  - `syncPendingAppointments()` - Sincronizar pendientes

### 3. `lib/providers/appointment_provider.dart` ✅
- Estado centralizado de citas
- Manejo de citas locales y síncronizadas
- Métodos principales:
  - `createAppointment()` - Crear + guardar local
  - `loadAppointments()` - Cargar desde backend
  - `syncPendingAppointments()` - Sincronizar cuando haya conexión
  - `getUpcomingAppointments()` - Citas próximas
  - `getPastAppointments()` - Historial

---

## 🔄 FLUJO DE CREACIÓN DE CITA

```
Usuario presiona "Confirmar Cita"
  ↓
book_appointment_screen.dart: _onConfirm()
  ↓
AppointmentProvider.createAppointment()
  ├─→ Intenta conectarse al backend
  ├─→ Si éxito: Guarda con sincronizado=true ✅
  └─→ Si fallo: Guarda con sincronizado=false (pendiente) ⚠️
  ↓
StorageService.saveAppointment()
  └─→ Guarda en SharedPreferences (persistencia local)
  ↓
La cita aparece INMEDIATAMENTE en la app
  ↓
Cuando hay conexión: AppointmentProvider.syncPendingAppointments()
  └─→ Envía las pendientes al backend
```

---

## 🛠️ PASOS DE IMPLEMENTACIÓN

### Paso 1: Actualizar book_appointment_screen.dart

**Reemplazar la función `_onConfirm()` con:**

```dart
void _onConfirm() async {
  if (_selectedDentist == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona un especialista antes de confirmar.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona un horario antes de confirmar.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Usar AppointmentProvider para crear cita
  if (!mounted) return;
  
  final appointmentProvider = Provider.of<AppointmentProvider>(
    context,
    listen: false,
  );

  final fecha = '${_selectedDate.year.toString().padLeft(4, '0')}'
      '-${_selectedDate.month.toString().padLeft(2, '0')}'
      '-${_selectedDate.day.toString().padLeft(2, '0')}';

  // Extraer hora en formato 24h (ej: "16:00")
  final timeList = _selectedTime!.split(':');
  int hour = int.parse(timeList[0]);
  final minute = timeList[1].split(' ')[0];
  
  // Si es PM, sumar 12 (excepto si es 12:00 PM)
  if (_selectedTime!.contains('PM') && hour != 12) {
    hour += 12;
  } else if (_selectedTime!.contains('AM') && hour == 12) {
    hour = 0;
  }
  
  final formattedHour = hour.toString().padLeft(2, '0');
  final hora = '$formattedHour:$minute';

  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final success = await appointmentProvider.createAppointment(
      fecha: fecha,
      hora: hora,
      idOdontologo: _selectedDentist!['id'] ?? '',
      nombreOdontologo: _selectedDentist!['nombre'] ?? 'Odontólogo',
      monto: 100.0, // Ajustar según necesidad
      metodoPago: _selectedPaymentMethod,
      servicio: _selectedDiscount != null
          ? _selectedDiscount!['nombre']?.toString() ?? 'Cita'
          : 'Cita',
      descripcion: _consultationReason.isNotEmpty ? _consultationReason : null,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Cerrar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cita confirmada: $fecha $hora - '
              '${_selectedDentist!['nombre']} ✅',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Volver a la pantalla anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cita guardada localmente. Se sincronizará cuando haya conexión. ⚠️\n'
              '${appointmentProvider.errorMessage}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  } catch (e) {
    if (mounted) {
      Navigator.of(context).pop(); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**También agregar el import:**
```dart
import '../../providers/appointment_provider.dart';
```

### Paso 2: Actualizar los imports en main.dart

Asegurar que el `AppointmentProvider` esté en los providers:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => AppointmentProvider()),
    // ... otros providers
  ],
  child: const MyApp(),
),
```

### Paso 3: Ejecutar comandos Flutter

```bash
cd d:\App_Namay\dental_namay_app

# Limpiar y obtener dependencias
flutter clean
flutter pub get

# Compilar
flutter pub run build_runner build
```

### Paso 4: Testear

1. **Crear una cita en la app**
2. **Cierra la app completamente**
3. **Reabre la app**
4. **La cita debe aparecer en "Mis citas"** ✅

---

## 📊 VERIFICACIÓN EN ALMACENAMIENTO LOCAL

Para depurar qué se guardó localmente (solo en desarrollo):

```dart
import 'package:shared_preferences/shared_preferences.dart';

// En una pantalla de debug:
final prefs = await SharedPreferences.getInstance();
final keys = prefs.getKeys();
for (var key in keys) {
  if (key.startsWith('appointment_')) {
    print('$key: ${prefs.getString(key)}');
  }
}
```

---

## 🔌 SINCRONIZACIÓN AUTOMÁTICA

Para sincronizar cuando se recupere conexión, agregar en `main.dart`:

```dart
void _setupConnectivityListener() {
  connectivity.onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      // Hay conexión, sincronizar citas pendientes
      final appointmentProvider = context.read<AppointmentProvider>();
      appointmentProvider.syncPendingAppointments();
    }
  });
}
```

Requiere agregar dependencia en pubspec.yaml:
```yaml
connectivity_plus: ^5.0.0
```

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [ ] Crear archivos storage_service.dart, appointment_service.dart, appointment_provider.dart
- [ ] Actualizar book_appointment_screen.dart con nueva función _onConfirm()
- [ ] Agregar imports en main.dart
- [ ] Ejecutar `flutter pub get`
- [ ] Testear creación de cita
- [ ] Cerrar/abrir app y verificar que la cita persiste
- [ ] Verificar en logs de backend que se notifica a CAJERO/RECEPCIONISTA
- [ ] (Opcional) Implementar sincronización automática con connectivity_plus

---

## 🎯 RESULTADO ESPERADO

✅ **Antes (sin persistencia):**
- Usuario crea cita
- Cierra la app
- Reabre
- Las citas desaparecen 😞

✅ **Ahora (con persistencia):**
- Usuario crea cita
- Se guarda localmente INMEDIATAMENTE
- Se intenta enviar al backend (si hay conexión)
- Cierra la app
- Reabre
- Las citas siguen ahí 🎉
- Si estaban pendientes, se sincronizan cuando hay conexión
