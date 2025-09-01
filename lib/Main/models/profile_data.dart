//import 'package:fnlapp/config.dart';

class ProfileData {
  final String email;
  final String? username;
  final String hierarchicalLevel;
  String? profileImage;
  final int? idEmpresa;
  final String nombres;
  final String apellidos;
  String? nombreEmpresa;
  final String? gender;
  final String? estresLevel;

  ProfileData({
    required this.email,
    required this.username,
    required this.nombres,
    required this.apellidos,
    required this.hierarchicalLevel,
    this.profileImage,
    this.idEmpresa,
    required this.nombreEmpresa,
    required this.gender,
    this.estresLevel,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    const String defaultImageUrl = 'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/user_img.jpg';
  
  // Verifica si el perfil tiene una imagen válida
  String? profileImagePath = json['profileImage'];
  String finalImageUrl = defaultImageUrl; // Usar imagen por defecto inicialmente
  
  if (profileImagePath != null && 
      profileImagePath.isNotEmpty && 
      profileImagePath.startsWith('https://')) {
    finalImageUrl = profileImagePath;
  }

    return ProfileData(
      email: json['email'] ?? 'Correo no disponible',
      nombres: json['nombres'] ?? 'Usuario',
      apellidos: json['apellidos'] ?? '',
      nombreEmpresa: json['companyName'] ?? 'Empresa no definida',
      username: json['username'],
      hierarchicalLevel: json['hierarchicalLevel']?.toString() ?? 'No definido',
      profileImage: finalImageUrl, // Usar la URL procesada
      idEmpresa: json['id_empresa'] as int?,
      gender: json['gender']?.toString() ?? 'No especificado',
      estresLevel: json['estresLevel'] as String?,
    );
  }

  @override
  String toString() {
    return 'ProfileData{profileImage: $profileImage, hierarchicalLevel: $hierarchicalLevel, email: $email, id_empresa: $idEmpresa, gender: $gender}';
  }
}