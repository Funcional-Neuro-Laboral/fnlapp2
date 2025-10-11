# Funcional Neuro Laboral - APP

Aplicación móvil multiplataforma para evaluaciones neurofuncionales laborales, desarrollada con Flutter para ofrecer una experiencia nativa en iOS y Android.

## Tecnologías Utilizadas

### <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/dart/dart-original.svg" alt="Dart" width="30" height="30"/> Dart
**Descripción:** Dart es un lenguaje de programación desarrollado por Google, optimizado para el desarrollo de aplicaciones client-side. Es un lenguaje orientado a objetos con sintaxis similar a C y fuerte tipado opcional.

**Uso en el proyecto:** Lenguaje principal de desarrollo para:
- Implementación de la lógica de negocio de la aplicación móvil
- Creación de widgets personalizados para evaluaciones neurológicas
- Manejo del estado de la aplicación de forma reactiva
- Integración con APIs REST del backend
- Procesamiento local de datos de evaluaciones

### <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" alt="Flutter" width="30" height="30"/> Flutter
**Descripción:** Flutter es el framework de desarrollo multiplataforma de Google que utiliza Dart. Permite crear aplicaciones nativas compiladas para móvil, web y desktop desde una sola base de código.

**Uso en el proyecto:** Framework principal para:
- Desarrollo de interfaces de usuario nativas e intuitivas
- Implementación de pruebas neurofuncionales interactivas
- Navegación fluida entre diferentes módulos de evaluación
- Integración con sensores del dispositivo móvil
- Renderizado de gráficos y visualizaciones de datos médicos

### <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/html5/html5-original.svg" alt="HTML5" width="30" height="30"/> HTML
**Descripción:** HTML (HyperText Markup Language) es el lenguaje de marcado estándar para crear páginas web y aplicaciones web.

**Uso en el proyecto:** Utilizado para:
- Componentes web embebidos dentro de la aplicación Flutter
- Visualización de reportes médicos formateados
- Integración de contenido web en WebViews
- Plantillas para exportación de documentos

### <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/cplusplus/cplusplus-original.svg" alt="C++" width="30" height="30"/> C++
**Descripción:** C++ es un lenguaje de programación de propósito general que es una extensión del lenguaje C. Ofrece programación orientada a objetos y control de bajo nivel.

**Uso en el proyecto:** Empleado para:
- Módulos nativos de alto rendimiento para procesamiento de datos
- Algoritmos optimizados de análisis neurológico
- Integración con bibliotecas nativas del sistema operativo
- Operaciones matemáticas complejas en tiempo real

### <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/cmake/cmake-original.svg" alt="CMake" width="30" height="30"/> CMake
**Descripción:** CMake es un sistema de construcción multiplataforma diseñado para controlar el proceso de compilación de software usando archivos de configuración simples e independientes de la plataforma.

**Uso en el proyecto:** Herramienta de build para:
- Compilación de módulos nativos en C++
- Gestión de dependencias nativas
- Configuración de builds para diferentes plataformas (iOS/Android)
- Integración del código nativo con Flutter

### <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/swift/swift-original.svg" alt="Swift" width="30" height="30"/> Swift
**Descripción:** Swift es un lenguaje de programación desarrollado por Apple para el desarrollo de aplicaciones en iOS, macOS, watchOS y tvOS.

**Uso en el proyecto:** Utilizado para:
- Implementación específica de funcionalidades iOS
- Integración con APIs nativas de iOS (HealthKit, Core Motion)
- Optimizaciones específicas para dispositivos Apple
- Acceso a funcionalidades exclusivas del ecosistema iOS

### <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/ruby/ruby-original.svg" alt="Ruby" width="30" height="30"/> Ruby
**Descripción:** Ruby es un lenguaje de programación dinámico y de código abierto enfocado en la simplicidad y productividad, con una sintaxis elegante que es natural de leer y fácil de escribir.

**Uso en el proyecto:** Empleado para:
- Scripts de automatización del proceso de build
- Configuración de herramientas de CI/CD
- Gestión de certificados y perfiles de distribución (Fastlane)
- Automatización de despliegues a app stores

## Instalación y Configuración

```bash
# Clonar el repositorio
git clone https://github.com/Funcional-Neuro-Laboral/fnlapp2.git

# Instalar Flutter (si no está instalado)
# Seguir las instrucciones en: https://flutter.dev/docs/get-started/install

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run
```

## Estructura del Proyecto

```
fnlapp2/
├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   ├── services/
│   └── utils/
├── android/
├── ios/
├── web/
└── test/
```

## Características Principales

- Evaluaciones neurofuncionales interactivas
- Sincronización con backend en tiempo real
- Interfaz adaptativa para diferentes tamaños de pantalla
- Soporte offline para evaluaciones
- Exportación de reportes en múltiples formatos

## Plataformas Soportadas

- iOS 12.0+
- Android API 21+
- Web (Progressive Web App)

## Contribución

Para contribuir al proyecto, asegúrate de seguir las convenciones de código de Dart/Flutter y ejecutar los tests antes de enviar cambios.

Más información sobre el proyecto en: https://fnldigital.com/

## Setup

Una vez clonado el proyecto, crear el archivo 'config.dart' dentro de la carpeta 'lib'. Y copiar el siguiente código en ese archivo adaptando las URL para pruebas en local y producción según corresponda:
```dart
class Config {
  static const String apiUrl = 'http://localhost:3000/api';
  static const String imagenesUrl = 'http://localhost:3000/imagenes';
}
```

El .gitignore ya excluye dicho archivo que tiene el rol de .env en este caso.
