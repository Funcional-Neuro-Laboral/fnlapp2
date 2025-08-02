# Funcional Neuro Laboral - APP

Aplicación en Flutter para FNL.

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
