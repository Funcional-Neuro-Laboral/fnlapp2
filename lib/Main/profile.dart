import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Util/token_service.dart';
import 'models/profile_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileData? profileData;
  final Function onLogout;
  final Function(String)? onImageSelected;
  final Function(String)? onProfileImageUpdated;

  ProfileScreen({
    required this.profileData,
    required this.onLogout,
    this.onImageSelected,
    this.onProfileImageUpdated,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Mantén todos los métodos existentes (_uploadProfileImage, _reloadProfileFromServer, etc.)
  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null && _selectedImageBytes == null) {
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('token');

      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      final uri = Uri.parse('${Config.apiUrl2}/users/upload-photo/$userId');
      final request = http.MultipartRequest('PUT', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (kIsWeb && _selectedImageBytes != null) {
        String filename = 'profile_image.jpg';
        String contentType = 'image/jpeg';

        if (_selectedImageBytes!.length > 3) {
          if (_selectedImageBytes![0] == 0x89 &&
              _selectedImageBytes![1] == 0x50 &&
              _selectedImageBytes![2] == 0x4E &&
              _selectedImageBytes![3] == 0x47) {
            filename = 'profile_image.png';
            contentType = 'image/png';
          }
          else if (_selectedImageBytes![0] == 0xFF &&
              _selectedImageBytes![1] == 0xD8 &&
              _selectedImageBytes![2] == 0xFF) {
            contentType = 'image/jpeg';
          }
        }

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedImageBytes!,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ));
      } else if (!kIsWeb && _selectedImage != null) {
        String path = _selectedImage!.path.toLowerCase();
        String contentType;

        if (path.endsWith('.png')) {
          contentType = 'image/png';
        } else if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else {
          throw Exception('Solo se permiten archivos JPG y PNG');
        }

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _selectedImage!.path,
          contentType: MediaType.parse(contentType),
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final newImageUrl = jsonResponse['data']['imageUrl'];

        imageCache.clear();
        imageCache.clearLiveImages();

        await _reloadProfileFromServer();

        if (widget.onProfileImageUpdated != null) {
          widget.onProfileImageUpdated!(newImageUrl);
        }

        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imagen de perfil actualizada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final errorResponse = json.decode(responseBody);
        throw Exception('Error del servidor: ${response.statusCode} - ${errorResponse['error']['message']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar imagen de perfil'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _reloadProfileFromServer() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        throw Exception('No se pudieron obtener los datos del usuario');
      }

      String url = '${Config.apiUrl2}/users/getprofile/$userId';
      final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          }
      );

      if (response.statusCode == 200) {
        var profileJson = json.decode(response.body);
        var updatedProfile = ProfileData.fromJson(profileJson);

        setState(() {
          if (widget.profileData != null) {
            widget.profileData!.profileImage = updatedProfile.profileImage;
          }
        });
      }
    } catch (e) {
      print('Error al recargar perfil desde servidor: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        String fileName = image.name.toLowerCase();
        if (!fileName.endsWith('.jpg') && !fileName.endsWith('.jpeg') && !fileName.endsWith('.png')) {
          return;
        }

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null;
          });
        }

        if (widget.onImageSelected != null) {
          widget.onImageSelected!(image.path);
        }

        await _uploadProfileImage();
      }
    } catch (e) {
      // Error handling
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;
    final horizontalPadding = isDesktop ? 200.0 : isTablet ? 80.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.05),

                // Título responsivo
                Text(
                  'Perfil',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF212121),
                    fontSize: size.width < 400 ? 28.0 : size.width < 600 ? 32.0 : 36.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // Contenido centrado con ancho máximo
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 800 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        _buildProfileImage(size),
                        SizedBox(height: size.height * 0.03),
                        _buildUserName(size),
                        SizedBox(height: size.height * 0.04),
                        _buildInfoGrid(size, isTablet, isDesktop),
                        SizedBox(height: size.height * 0.05),
                        _buildLogoutButton(size, isDesktop),
                        SizedBox(height: size.height * 0.03),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(Size size) {
    final imageSize = size.width < 400 ? 125.0 : size.width < 600 ? 140.0 : 160.0;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF52178F), Color(0xFFA88BC7)],
            begin: Alignment(1.00, 1.00),
            end: Alignment(1.00, 0.50),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A67C8).withOpacity(0.3),
              blurRadius: size.width < 600 ? 15 : 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: CircleAvatar(
            radius: (imageSize - 12) / 2,
            backgroundColor: Colors.transparent,
            backgroundImage: _getImageProvider(),
            child: _getImageProvider() == null
                ? Icon(
              Icons.person,
              size: size.width < 400 ? 40 : size.width < 600 ? 50 : 60,
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
      return NetworkImage(
        widget.profileData!.profileImage!,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
    }
    return null;
  }

  Widget _buildUserName(Size size) {
    return Text(
      "${widget.profileData?.nombres ?? 'Usuario'} ${widget.profileData?.apellidos ?? ''}",
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: const Color(0xFF212121),
        fontSize: size.width < 400 ? 20.0 : size.width < 600 ? 24.0 : 28.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoGrid(Size size, bool isTablet, bool isDesktop) {
    final cardPadding = size.width < 400 ? 16.0 : size.width < 600 ? 20.0 : 24.0;
    final cardSpacing = size.width < 400 ? 12.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFDCD4F6),
        borderRadius: BorderRadius.circular(size.width < 600 ? 16 : 20),
      ),
      child: isDesktop && size.width > 1200
          ? _buildDesktopLayout(cardSpacing, size)
          : _buildTabletMobileLayout(cardSpacing, size),
    );
  }

  Widget _buildDesktopLayout(double cardSpacing, Size size) {
    return Row(
      children: [
        Expanded(child: _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'ID',
          value: widget.profileData?.username ?? 'No disponible',
          size: size,
        )),
        SizedBox(width: cardSpacing),
        Expanded(child: _buildInfoCard(
          icon: Icons.female,
          title: 'Género',
          value: widget.profileData?.gender ?? 'No disponible',
          size: size,
        )),
        SizedBox(width: cardSpacing),
        Expanded(child: _buildInfoCard(
          icon: Icons.person,
          title: 'Puesto',
          value: widget.profileData?.hierarchicalLevel ?? 'No disponible',
          size: size,
        )),
        SizedBox(width: cardSpacing),
        Expanded(child: _buildInfoCard(
          icon: Icons.business_outlined,
          title: 'Centro',
          value: widget.profileData?.nombreEmpresa ?? 'No disponible',
          size: size,
        )),
      ],
    );
  }

  Widget _buildTabletMobileLayout(double cardSpacing, Size size) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'ID',
              value: widget.profileData?.username ?? 'No disponible',
              size: size,
            )),
            SizedBox(width: cardSpacing),
            Expanded(child: _buildInfoCard(
              icon: Icons.female,
              title: 'Género',
              value: widget.profileData?.gender ?? 'No disponible',
              size: size,
            )),
          ],
        ),
        SizedBox(height: cardSpacing),
        Row(
          children: [
            Expanded(child: _buildInfoCard(
              icon: Icons.person,
              title: 'Puesto',
              value: widget.profileData?.hierarchicalLevel ?? 'No disponible',
              size: size,
            )),
            SizedBox(width: cardSpacing),
            Expanded(child: _buildInfoCard(
              icon: Icons.business_outlined,
              title: 'Centro',
              value: widget.profileData?.nombreEmpresa ?? 'No disponible',
              size: size,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Size size,
  }) {
    final cardPadding = size.width < 400 ? 12.0 : size.width < 600 ? 16.0 : 20.0;
    final iconSize = size.width < 400 ? 18.0 : size.width < 600 ? 20.0 : 22.0;
    final titleFontSize = size.width < 400 ? 12.0 : size.width < 600 ? 14.0 : 16.0;
    final valueFontSize = size.width < 400 ? 12.0 : size.width < 600 ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width < 600 ? 10 : 12),
        boxShadow: size.width >= 600 ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(size.width < 400 ? 6 : 8),
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
          SizedBox(width: size.width < 400 ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF3D3D3D),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: valueFontSize,
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

  Widget _buildLogoutButton(Size size, bool isDesktop) {
    final buttonPadding = size.width < 400 ? 14.0 : size.width < 600 ? 16.0 : 18.0;
    final fontSize = size.width < 400 ? 16.0 : size.width < 600 ? 16.0 : 18.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 400 : size.width * 0.8,
      ),
      child: ElevatedButton(
        onPressed: () async {
          final result = await _showLogoutDialog();
          if (result != null) {
            await TokenService.instance.logout(logoutAll: result);
            widget.onLogout();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF6D4BD8),
          padding: EdgeInsets.symmetric(
            horizontal: size.width < 400 ? 24 : 32,
            vertical: buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: const BorderSide(
              color: Color(0xFF6D4BD8),
              width: 1.5,
            ),
          ),
          elevation: size.width >= 600 ? 2 : 0,
          shadowColor: size.width >= 600 ? Colors.black.withOpacity(0.1) : null,
        ),
        child: Text(
          'Cerrar sesión',
          style: GoogleFonts.inter(
            color: const Color(0xFF6D4BD8),
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<bool?> _showLogoutDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cerrar sesión'),
          content: Text('¿Deseas cerrar sesión en todos tus dispositivos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Solo este dispositivo'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Todos los dispositivos'),
            ),
          ],
        );
      },
    );
  }
}
