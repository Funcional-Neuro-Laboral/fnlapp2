import 'package:fnlapp/config.dart';

class ProfileData {
  final String email;
  final String hierarchicalLevel;
  final String? profileImage;
  final int? idEmpresa;
  final String nombres;
  final String apellidos;
  String? nombreEmpresa;

  ProfileData({
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.hierarchicalLevel,
    this.profileImage,
    this.idEmpresa,
    this.nombreEmpresa,
  });

  // --- FÁBRICA CORREGIDA PARA SER A PRUEBA DE NULOS ---
  factory ProfileData.fromJson(Map<String, dynamic> json) {
    // Verifica si el perfil de la imagen es una URL completa o solo una ruta
    String? profileImagePath = json['profileImage'];
    if (profileImagePath != null && !profileImagePath.startsWith('http')) {
      // Construye la URL completa si es necesario
      profileImagePath =
          Config.imagenesUrl + profileImagePath.replaceAll('\\', '/');
    }

    return ProfileData(
      // Usamos '??' para proveer un valor por defecto si el campo es nulo.
      email: json['email'] ?? 'Correo no disponible',
      nombres: json['nombres'] ?? 'Usuario',
      apellidos: json['apellidos'] ?? '',

      // Manejamos el nivel jerárquico de forma segura.
      hierarchicalLevel: json['hierarchicalLevel']?.toString() ?? 'No definido',

      profileImage: profileImagePath,

      // Nos aseguramos de que el id sea un entero nulable.
      idEmpresa: json['id_empresa'] as int?,
    );
  }

  @override
  String toString() {
    return 'ProfileData{profileImage: $profileImage, hierarchicalLevel: $hierarchicalLevel, email: $email, id_empresa: $idEmpresa}';
  }
}