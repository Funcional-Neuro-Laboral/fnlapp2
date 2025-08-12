import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'models/profile_data.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileData? profileData;
  final Function onLogout;
  final Function(String)? onImageSelected; // Callback para manejar la nueva imagen

  ProfileScreen({
    required this.profileData,
    required this.onLogout,
    this.onImageSelected,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // Para web
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      // Mostrar diálogo para elegir entre cámara y galería
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // En web, leemos los bytes de la imagen
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          // En móvil, usamos File
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null;
          });
        }

        // Llamar al callback si existe
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(image.path);
        }
      }
    } catch (e) {
      // Mostrar error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: const Text('¿De dónde quieres obtener la imagen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Cámara'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Galería'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isWeb = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isWeb, isTablet),
                      Expanded(
                        child: _buildContent(isWeb, isTablet, screenWidth),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWeb, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(
        left: isWeb ? 200 : (isTablet ? 80 : 16),
        top: isWeb ? 40 : (isTablet ? 50 : 60),
        right: isWeb ? 40 : (isTablet ? 30 : 20),
      ),
      child: Text(
        'Perfil',
        style: TextStyle(
          color: const Color(0xFF212121),
          fontSize: isWeb ? 42 : (isTablet ? 34 : 32),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildContent(bool isWeb, bool isTablet, double screenWidth) {
    final maxWidth = isWeb ? 800.0 : double.infinity;
    final horizontalPadding = isWeb ? 40.0 : (isTablet ? 30.0 : 20.0);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            SizedBox(height: isWeb ? 20 : (isTablet ? 35 : 50)),
            _buildProfileImage(isWeb, isTablet),
            SizedBox(height: isWeb ? 25 : 20),
            _buildUserName(isWeb, isTablet),
            SizedBox(height: isWeb ? 35 : 30),
            _buildInfoGrid(isWeb, isTablet, screenWidth),
            SizedBox(height: isWeb ? 40 : (isTablet ? 35 : 30)),
            _buildLogoutButton(isWeb, isTablet),
            SizedBox(height: isWeb ? 30 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(bool isWeb, bool isTablet) {
    final imageSize = isWeb ? 150.0 : (isTablet ? 140.0 : 130.0);

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF52178F),
              Color(0xFFA88BC7),
            ],
            begin: Alignment(1.00, 1.00),
            end: Alignment(1.00, 0.50),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A67C8).withOpacity(0.3),
              blurRadius: isWeb ? 25 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: CircleAvatar(
            radius: (imageSize - 16) / 2,
            backgroundColor: Colors.transparent,
            backgroundImage: _getImageProvider(),
            child: _getImageProvider() == null
                ? Icon(
              Icons.person,
              size: isWeb ? 60 : (isTablet ? 55 : 50),
              color: const Color(0xFF4320AD),
            )
                : null,
          ),
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (kIsWeb && _selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    } else if (!kIsWeb && _selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (widget.profileData?.profileImage != null) {
      return NetworkImage(widget.profileData!.profileImage!);
    }
    return null;
  }

  Widget _buildUserName(bool isWeb, bool isTablet) {
    return Text(
      "${widget.profileData?.nombres ?? 'Usuario'} ${widget.profileData?.apellidos ?? ''}",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF212121),
        fontSize: isWeb ? 28 : (isTablet ? 26 : 24),
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoGrid(bool isWeb, bool isTablet, double screenWidth) {
    final cardPadding = isWeb ? 25.0 : (isTablet ? 22.0 : 20.0);
    final cardSpacing = isWeb ? 16.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFDCD4F6),
        borderRadius: BorderRadius.circular(isWeb ? 25 : 20),
      ),
      child: Column(
        children: [
          if (isWeb && screenWidth > 1200)
          // Layout horizontal para pantallas muy anchas
            Row(
              children: [
                Expanded(child: _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'ID',
                    value: widget.profileData?.email.split('@')[0] ?? 'No disponible',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
                SizedBox(width: cardSpacing),
                Expanded(child: _buildInfoCard(
                    icon: Icons.female,
                    title: 'Género',
                    value: '--',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
                SizedBox(width: cardSpacing),
                Expanded(child: _buildInfoCard(
                    icon: Icons.person,
                    title: 'Puesto',
                    value: '--',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
                SizedBox(width: cardSpacing),
                Expanded(child: _buildInfoCard(
                    icon: Icons.business_outlined,
                    title: 'Centro',
                    value: widget.profileData?.nombreEmpresa ?? 'No disponible',
                    isWeb: isWeb,
                    isTablet: isTablet
                )),
              ],
            )
          else
          // Layout en grid 2x2 para el resto de pantallas
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'ID',
                        value: widget.profileData?.email.split('@')[0] ?? 'No disponible',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.female,
                        title: 'Género',
                        value: '--',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: cardSpacing),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.person,
                        title: 'Puesto',
                        value: '--',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.business_outlined,
                        title: 'Centro',
                        value: widget.profileData?.nombreEmpresa ?? 'No disponible',
                        isWeb: isWeb,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isWeb,
    required bool isTablet,
  }) {
    final cardPadding = isWeb ? 20.0 : (isTablet ? 18.0 : 16.0);
    final iconSize = isWeb ? 24.0 : (isTablet ? 22.0 : 20.0);
    final titleFontSize = isWeb ? 16.0 : 15.0;
    final valueFontSize = isWeb ? 14.0 : 13.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 15 : 10),
        boxShadow: isWeb
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? 10 : 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0EEFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4320AD),
              size: iconSize,
            ),
          ),
          SizedBox(width: isWeb ? 15 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF3D3D3D),
                    fontSize: titleFontSize,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: valueFontSize,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isWeb, bool isTablet) {
    final buttonPadding = isWeb ? 20.0 : 16.0;
    final fontSize = isWeb ? 18.0 : 16.0;
    final horizontalMargin = isWeb ? 0.0 : 20.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isWeb ? 400 : double.infinity,
      ),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: ElevatedButton(
        onPressed: () => widget.onLogout(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF6D4BD8),
          padding: EdgeInsets.symmetric(
            horizontal: 32,
            vertical: buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: const BorderSide(
              color: Color(0xFF6D4BD8),
              width: 1.5,
            ),
          ),
          elevation: isWeb ? 2 : 0,
          shadowColor: isWeb ? Colors.black.withOpacity(0.1) : null,
        ),
        child: Text(
          'Cerrar sesión',
          style: TextStyle(
            color: const Color(0xFF6D4BD8),
            fontSize: fontSize,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}