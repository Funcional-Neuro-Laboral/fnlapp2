# Documentación: SubscriptionService

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura](#arquitectura)
3. [Dependencias](#dependencias)
4. [Métodos](#métodos)
5. [Flujo de Trabajo](#flujo-de-trabajo)
6. [Casos de Uso](#casos-de-uso)
7. [Manejo de Errores](#manejo-de-errores)
8. [Integración con Backend](#integración-con-backend)
9. [Ejemplos de Implementación](#ejemplos-de-implementación)
10. [Consideraciones de Seguridad](#consideraciones-de-seguridad)

---

## Introducción

`SubscriptionService` es un servicio estático en Flutter que gestiona la verificación de acceso a funcionalidades premium basadas en suscripciones. Este servicio actúa como una capa de abstracción entre la aplicación móvil y el backend, permitiendo verificar de manera centralizada si un usuario tiene acceso a características específicas según su plan de suscripción.

### Ubicación del Archivo
```
lib/services/subscription_service.dart
```

### Propósito Principal
- Verificar el acceso del usuario a funcionalidades premium
- Comunicarse con el backend para validar suscripciones
- Proporcionar métodos de alto nivel para verificar acceso a características específicas

---

## Arquitectura

### Diseño
- **Patrón**: Servicio estático (Singleton implícito)
- **Tipo**: Clase utilitaria con métodos estáticos
- **Responsabilidad**: Verificación de acceso a funcionalidades

### Características de Diseño
- ✅ Todos los métodos son estáticos (no requiere instanciación)
- ✅ Manejo centralizado de autenticación
- ✅ Abstracción de la lógica de verificación de suscripciones
- ✅ Separación de responsabilidades (no gestiona compras, solo verifica acceso)

---

## Dependencias

### Paquetes Flutter Utilizados

```dart
import 'package:http/http.dart' as http;        // Para peticiones HTTP
import 'dart:convert';                          // Para decodificar JSON
import 'package:shared_preferences/shared_preferences.dart';  // Para almacenar token
import '../config.dart';                        // Para obtener URL del API
```

### Dependencias del Proyecto
- `http`: ^1.2.1 - Cliente HTTP para realizar peticiones al backend
- `shared_preferences`: ^2.2.3 - Almacenamiento local para el token de autenticación
- `config.dart`: Archivo de configuración local que contiene la URL del API

---

## Métodos

### 1. `checkFeatureAccess(String feature)`

**Descripción**: Método base que realiza la verificación de acceso a una funcionalidad específica mediante una petición HTTP al backend.

**Parámetros**:
- `feature` (String): Identificador de la funcionalidad a verificar

**Retorno**: 
- `Future<Map<String, dynamic>>`: Respuesta completa del servidor en formato JSON

**Flujo Interno**:
1. Obtiene la instancia de `SharedPreferences`
2. Extrae el token de autenticación almacenado
3. Valida que el token exista (lanza excepción si no existe)
4. Realiza petición GET al endpoint: `${Config.apiUrl2}/subscriptions/check-access/$feature`
5. Incluye el token en el header `Authorization: Bearer {token}`
6. Decodifica la respuesta JSON si el status code es 200
7. Lanza excepción si el status code es diferente a 200

**Código**:
```dart
static Future<Map<String, dynamic>> checkFeatureAccess(String feature) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No se encontró el token de autenticación');
    }

    final response = await http.get(
      Uri.parse('${Config.apiUrl2}/subscriptions/check-access/$feature'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al verificar acceso: ${response.statusCode}');
    }
  } catch (e) {
    print('Error en checkFeatureAccess: $e');
    rethrow;
  }
}
```

**Errores Posibles**:
- `Exception('No se encontró el token de autenticación')`: Cuando no hay token almacenado
- `Exception('Error al verificar acceso: {statusCode}')`: Cuando el servidor responde con error
- Cualquier excepción de red o parsing se propaga con `rethrow`

---

### 2. `hasAccessToPrograms()`

**Descripción**: Verifica si el usuario tiene acceso a los programas de la aplicación.

**Parámetros**: Ninguno

**Retorno**: 
- `Future<bool>`: `true` si tiene acceso, `false` en caso contrario o si hay error

**Feature ID**: `'access_programs'`

**Código**:
```dart
static Future<bool> hasAccessToPrograms() async {
  try {
    final result = await checkFeatureAccess('access_programs');
    return result['data']['hasAccess'] ?? false;
  } catch (e) {
    return false;
  }
}
```

**Características**:
- Manejo silencioso de errores (retorna `false` en caso de excepción)
- Extrae el valor de `result['data']['hasAccess']`
- Usa operador null-coalescing (`??`) para garantizar un booleano

---

### 3. `hasAccessToChatPro()`

**Descripción**: Verifica si el usuario tiene acceso al chat Pro (funcionalidad premium de chat).

**Parámetros**: Ninguno

**Retorno**: 
- `Future<bool>`: `true` si tiene acceso, `false` en caso contrario o si hay error

**Feature ID**: `'access_chat_pro'`

**Código**:
```dart
static Future<bool> hasAccessToChatPro() async {
  try {
    final result = await checkFeatureAccess('access_chat_pro');
    return result['data']['hasAccess'] ?? false;
  } catch (e) {
    return false;
  }
}
```

---

### 4. `hasAccessToActivities()`

**Descripción**: Verifica si el usuario tiene acceso a las actividades premium.

**Parámetros**: Ninguno

**Retorno**: 
- `Future<bool>`: `true` si tiene acceso, `false` en caso contrario o si hay error

**Feature ID**: `'access_activities'`

**Código**:
```dart
static Future<bool> hasAccessToActivities() async {
  try {
    final result = await checkFeatureAccess('access_activities');
    return result['data']['hasAccess'] ?? false;
  } catch (e) {
    return false;
  }
}
```

---

## Flujo de Trabajo

### Diagrama de Flujo General

```
┌─────────────────┐
│ Usuario intenta │
│ acceder a       │
│ funcionalidad   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Llamada a método del    │
│ SubscriptionService     │
│ (ej: hasAccessToPrograms)│
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ checkFeatureAccess()    │
│ - Obtiene token         │
│ - Valida token          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Petición HTTP GET       │
│ /subscriptions/         │
│ check-access/{feature}  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Backend valida          │
│ suscripción y responde  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Procesa respuesta       │
│ - Extrae hasAccess      │
│ - Retorna bool          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ App permite/bloquea     │
│ acceso según resultado  │
└─────────────────────────┘
```

### Pasos Detallados

1. **Inicio**: El usuario intenta acceder a una funcionalidad premium
2. **Verificación**: Se llama a un método específico del servicio (ej: `hasAccessToPrograms()`)
3. **Autenticación**: El servicio obtiene el token JWT desde `SharedPreferences`
4. **Validación**: Se verifica que el token exista
5. **Petición**: Se realiza una petición HTTP GET al endpoint del backend
6. **Procesamiento Backend**: El servidor valida la suscripción del usuario
7. **Respuesta**: El backend retorna un JSON con el estado de acceso
8. **Procesamiento**: El servicio extrae el valor `hasAccess` de la respuesta
9. **Resultado**: Se retorna un booleano indicando si tiene acceso
10. **Acción**: La aplicación permite o bloquea el acceso según el resultado

---

## Casos de Uso

### Caso de Uso 1: Verificación de Acceso a Programas

**Contexto**: Después de completar un test de estrés, el usuario intenta generar un programa personalizado.

**Implementación en `testestres_form.dart`**:

```dart
// Verificar acceso a programas antes de generar
final hasAccess = await SubscriptionService.hasAccessToPrograms();

if (!hasAccess) {
  // Usuario no tiene acceso, mostrar diálogo de suscripción
  final shouldNavigate = await _showSubscriptionDialog();

  if (shouldNavigate == true) {
    // Usuario eligió suscribirse, navegar a pantalla de suscripción
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionScreen(showBackButton: false),
      ),
    );

    if (result == true) {
      // Suscripción exitosa, generar programa
      await _generateProgram(userProfile, totalScore);
      // ... resto del código
    }
  }
}
```

**Flujo**:
1. Usuario completa test de estrés
2. Sistema verifica acceso con `hasAccessToPrograms()`
3. Si no tiene acceso → muestra diálogo de suscripción
4. Si acepta → navega a pantalla de suscripción
5. Si se suscribe exitosamente → genera el programa

---

### Caso de Uso 2: Verificación de Acceso a Chat Pro

**Contexto**: El usuario intenta acceder a funcionalidades avanzadas del chat.

**Implementación sugerida**:
```dart
final hasChatProAccess = await SubscriptionService.hasAccessToChatPro();

if (hasChatProAccess) {
  // Mostrar funcionalidades premium del chat
  _showProFeatures();
} else {
  // Mostrar mensaje de upgrade
  _showUpgradeDialog();
}
```

---

### Caso de Uso 3: Verificación de Acceso a Actividades

**Contexto**: El usuario intenta acceder a actividades premium.

**Implementación sugerida**:
```dart
final hasActivitiesAccess = await SubscriptionService.hasAccessToActivities();

if (hasActivitiesAccess) {
  // Cargar actividades premium
  _loadPremiumActivities();
} else {
  // Mostrar solo actividades gratuitas
  _loadFreeActivities();
}
```

---

## Manejo de Errores

### Estrategia de Manejo

El servicio implementa dos niveles de manejo de errores:

#### Nivel 1: `checkFeatureAccess()` (Método Base)
- **Estrategia**: Propagación de errores (`rethrow`)
- **Comportamiento**: 
  - Imprime el error en consola para debugging
  - Propaga la excepción al llamador
  - Permite manejo personalizado de errores

**Errores que propaga**:
- Token no encontrado
- Errores de red (timeout, conexión fallida)
- Errores HTTP (4xx, 5xx)
- Errores de parsing JSON

#### Nivel 2: Métodos Específicos (`hasAccessTo*`)
- **Estrategia**: Manejo silencioso
- **Comportamiento**: 
  - Captura todas las excepciones
  - Retorna `false` por defecto
  - No interrumpe el flujo de la aplicación

**Ventajas**:
- ✅ La aplicación no se rompe si hay problemas de red
- ✅ Experiencia de usuario más fluida
- ✅ Comportamiento predecible (siempre retorna bool)

**Desventajas**:
- ⚠️ Puede ocultar errores importantes
- ⚠️ Dificulta el debugging en producción

### Ejemplo de Manejo de Errores

```dart
try {
  final hasAccess = await SubscriptionService.hasAccessToPrograms();
  // Usar hasAccess
} catch (e) {
  // Este bloque nunca se ejecutará porque hasAccessToPrograms()
  // maneja los errores internamente y retorna false
  print('Error inesperado: $e');
}
```

---

## Integración con Backend

### Endpoint del API

**URL Base**: `${Config.apiUrl2}/subscriptions/check-access/{feature}`

**Configuración actual** (según `config.dart`):
```
https://funcyfnl.ddns.net/api/subscriptions/check-access/{feature}
```

### Método HTTP
- **Método**: `GET`
- **Autenticación**: Bearer Token (JWT)

### Headers Requeridos

```http
Authorization: Bearer {token_jwt}
Content-Type: application/json
```

### Parámetros de URL

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `feature` | String | Identificador de la funcionalidad | `access_programs` |

### Respuesta Exitosa (200 OK)

**Formato JSON Esperado**:
```json
{
  "data": {
    "hasAccess": true,
    "subscription": {
      "plan": "pro",
      "expiresAt": "2024-12-31T23:59:59Z"
    }
  }
}
```

**Estructura**:
- `data.hasAccess` (boolean): Indica si el usuario tiene acceso
- `data.subscription` (object, opcional): Información adicional de la suscripción

### Respuestas de Error

| Status Code | Descripción | Manejo |
|-------------|-------------|--------|
| 401 | No autorizado (token inválido/expirado) | Se lanza excepción |
| 403 | Prohibido (sin suscripción) | Se retorna `hasAccess: false` |
| 404 | Feature no encontrado | Se lanza excepción |
| 500 | Error del servidor | Se lanza excepción |

### Features Soportadas

| Feature ID | Descripción | Método Asociado |
|------------|-------------|-----------------|
| `access_programs` | Acceso a programas personalizados | `hasAccessToPrograms()` |
| `access_chat_pro` | Acceso a chat Pro | `hasAccessToChatPro()` |
| `access_activities` | Acceso a actividades premium | `hasAccessToActivities()` |

---

## Ejemplos de Implementación

### Ejemplo 1: Verificación Simple

```dart
// Verificar acceso antes de mostrar funcionalidad
final hasAccess = await SubscriptionService.hasAccessToPrograms();

if (hasAccess) {
  // Mostrar programas
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => ProgramsScreen(),
  ));
} else {
  // Mostrar pantalla de suscripción
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => SubscriptionScreen(),
  ));
}
```

### Ejemplo 2: Verificación con Loading

```dart
bool _isCheckingAccess = false;
bool _hasAccess = false;

Future<void> _checkAccess() async {
  setState(() {
    _isCheckingAccess = true;
  });

  _hasAccess = await SubscriptionService.hasAccessToPrograms();

  setState(() {
    _isCheckingAccess = false;
  });
}

@override
Widget build(BuildContext context) {
  if (_isCheckingAccess) {
    return CircularProgressIndicator();
  }

  return _hasAccess 
    ? ProgramsScreen() 
    : SubscriptionPrompt();
}
```

### Ejemplo 3: Verificación Múltiple

```dart
Future<Map<String, bool>> checkAllAccess() async {
  final results = await Future.wait([
    SubscriptionService.hasAccessToPrograms(),
    SubscriptionService.hasAccessToChatPro(),
    SubscriptionService.hasAccessToActivities(),
  ]);

  return {
    'programs': results[0],
    'chatPro': results[1],
    'activities': results[2],
  };
}
```

### Ejemplo 4: Verificación con Manejo de Errores Detallado

```dart
Future<bool> checkAccessWithRetry(String feature, {int maxRetries = 3}) async {
  int attempts = 0;
  
  while (attempts < maxRetries) {
    try {
      final result = await SubscriptionService.checkFeatureAccess(feature);
      return result['data']['hasAccess'] ?? false;
    } catch (e) {
      attempts++;
      if (attempts >= maxRetries) {
        print('Error después de $maxRetries intentos: $e');
        return false;
      }
      await Future.delayed(Duration(seconds: 2));
    }
  }
  return false;
}
```

---

## Consideraciones de Seguridad

### ✅ Aspectos de Seguridad Implementados

1. **Autenticación con Token JWT**
   - El token se almacena de forma segura en `SharedPreferences`
   - Se envía en el header `Authorization` siguiendo el estándar Bearer Token
   - El backend valida el token antes de procesar la petición

2. **Comunicación HTTPS**
   - Las peticiones se realizan sobre HTTPS (según configuración en `config.dart`)
   - Protege los datos en tránsito

3. **Validación en el Backend**
   - La lógica de suscripción está en el servidor (no se puede manipular desde la app)
   - El backend es la fuente de verdad para el estado de suscripción

### ⚠️ Consideraciones y Mejoras Potenciales

1. **Almacenamiento del Token**
   - **Actual**: `SharedPreferences` (no es el más seguro)
   - **Recomendación**: Usar `flutter_secure_storage` para almacenar tokens sensibles
   - El proyecto ya tiene `flutter_secure_storage: ^9.2.2` instalado

2. **Validación de Respuesta**
   - **Actual**: Confía en la estructura JSON del backend
   - **Recomendación**: Validar la estructura de la respuesta antes de acceder a propiedades

3. **Timeouts**
   - **Actual**: No hay timeout configurado
   - **Recomendación**: Agregar timeout a las peticiones HTTP para evitar esperas indefinidas

4. **Caché de Resultados**
   - **Actual**: Siempre consulta al backend
   - **Recomendación**: Implementar caché temporal para reducir peticiones innecesarias

5. **Logging de Errores**
   - **Actual**: Solo imprime en consola
   - **Recomendación**: Integrar servicio de logging para producción

### Ejemplo de Mejora de Seguridad

```dart
// Usar flutter_secure_storage en lugar de SharedPreferences
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubscriptionService {
  static const _storage = FlutterSecureStorage();
  
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  // ... resto del código
}
```

---

## Relación con Otros Componentes

### Componentes Relacionados

1. **`subscription_screen.dart`**
   - Gestiona la compra de suscripciones
   - Usa `in_app_purchase` para procesar pagos
   - **Relación**: `SubscriptionService` verifica el acceso después de la compra

2. **`profile.dart`**
   - Muestra información de la suscripción del usuario
   - **Relación**: Puede usar `SubscriptionService` para verificar estado actual

3. **`config.dart`**
   - Contiene la URL base del API
   - **Relación**: `SubscriptionService` depende de `Config.apiUrl2`

4. **`SharedPreferences`**
   - Almacena el token de autenticación
   - **Relación**: `SubscriptionService` lee el token desde aquí

---

## Resumen

### Funcionalidades Principales
- ✅ Verificación de acceso a funcionalidades premium
- ✅ Comunicación con backend para validar suscripciones
- ✅ Métodos de alto nivel para características específicas
- ✅ Manejo robusto de errores

### Limitaciones Actuales
- ⚠️ No gestiona compras (solo verifica acceso)
- ⚠️ Depende completamente del backend
- ⚠️ No implementa caché de resultados
- ⚠️ Almacenamiento de token no es el más seguro

### Mejoras Futuras Sugeridas
1. Implementar caché temporal de resultados
2. Usar `flutter_secure_storage` para tokens
3. Agregar timeouts a las peticiones HTTP
4. Validar estructura de respuestas del backend
5. Implementar logging estructurado

---

## Conclusión

`SubscriptionService` es un componente esencial para el sistema de suscripciones de la aplicación. Proporciona una interfaz limpia y fácil de usar para verificar el acceso a funcionalidades premium, mientras mantiene la lógica de negocio en el backend donde debe estar por seguridad.

El servicio está bien diseñado para su propósito actual, pero hay oportunidades de mejora en términos de seguridad y rendimiento que podrían implementarse en futuras versiones.

---

**Última actualización**: Diciembre 2024  
**Versión del servicio**: 1.0  
**Autor**: Documentación generada automáticamente

