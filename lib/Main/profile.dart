import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fnlapp/Main/subscription_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Util/token_service.dart';
import 'models/profile_data.dart';
import 'models/subscription_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart' as app_config;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:fnlapp/Main/certificate_screen.dart';
import 'package:fnlapp/SplashScreen/welcome_screen.dart' show FuncyColors;

class ProfileScreen extends StatefulWidget {
  final ProfileData? profileData;
  final Function onLogout;
  final Function(String)? onImageSelected;
  final Function(String)? onProfileImageUpdated;
  final bool isDay21Completed;

  ProfileScreen({
    required this.profileData,
    required this.onLogout,
    this.onImageSelected,
    this.onProfileImageUpdated,
    this.isDay21Completed = false,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  SubscriptionData? _subscriptionData;
  bool _loadingSubscription = true;

  // Ancho máximo del contenido (mismo criterio que en PlanScreen): evita
  // que la tarjeta y el header se estiren de borde a borde en tablet/web.
  static const double _maxContentWidth = 560.0;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  // ========== MÉTODOS DE SUSCRIPCIÓN ==========

  Future<void> _loadSubscriptionData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No se pudo obtener el token');
      }

      final response = await http.get(
        Uri.parse('${app_config.Config.apiUrl2}/subscriptions/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _subscriptionData = SubscriptionData.fromJson(jsonData);
          _loadingSubscription = false;
        });
      } else {
        throw Exception('Error al cargar suscripción');
      }
    } catch (e) {
      print('Error al cargar datos de suscripción: $e');
      setState(() {
        _loadingSubscription = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await _showCancelDialog();
    if (confirmed != true) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${app_config.Config.apiUrl2}/subscriptions/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _loadSubscriptionData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Suscripción cancelada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error al cancelar suscripción');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar suscripción'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showCancelDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancelar suscripción'),
          content: Text(
              '¿Estás seguro de que deseas cancelar tu suscripción Funcy PRO?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }

  // ========== MÉTODOS DE IMAGEN DE PERFIL ==========

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

      final uri = Uri.parse('${app_config.Config.apiUrl2}/users/upload-photo/$userId');
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
          } else if (_selectedImageBytes![0] == 0xFF &&
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
        throw Exception(
            'Error del servidor: ${response.statusCode} - ${errorResponse['error']['message']}');
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

      String url = '${app_config.Config.apiUrl2}/users/getprofile/$userId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
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
        if (!fileName.endsWith('.jpg') &&
            !fileName.endsWith('.jpeg') &&
            !fileName.endsWith('.png')) {
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
      print('Error al seleccionar imagen: $e');
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

  // ========== DIÁLOGO DE LOGOUT ==========

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

  // ========== BUILD PRINCIPAL ==========

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Mismo lenguaje visual del login, bienvenida y "Mi Plan Diario":
          // degradado de marca con formas suaves de profundidad.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FuncyColors.primaryDark,
                  FuncyColors.primary,
                  FuncyColors.primaryLight,
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _decorativeCircle(220, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            top: 220,
            left: -80,
            child: _decorativeCircle(170, Colors.white.withOpacity(0.05)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      children: [
                        _buildHeader(size),
                        const SizedBox(height: 8),
                        _buildProfileCard(size),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // Header con el mismo estilo "kicker + título" de PlanScreen, más la
  // mascota Funcy dando la bienvenida al usuario en su perfil.
  Widget _buildHeader(Size size) {
    final mascotSize = size.width < 400 ? 64.0 : 80.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUNCY · TU PERFIL',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mi Perfil',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: size.width < 400 ? 26.0 : 30.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Image.asset(
          'assets/images/happy_mascot.png',
          height: mascotSize,
          width: mascotSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Tarjeta blanca flotante (mismo criterio que la tarjeta de progreso en
  // PlanScreen), con el avatar superpuesto sobre el borde superior.
  Widget _buildProfileCard(Size size) {
    final avatarSize = size.width < 400
        ? 125.0
        : size.width < 600
            ? 140.0
            : 160.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: avatarSize / 2),
          padding: EdgeInsets.fromLTRB(20, avatarSize / 2 + 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: FuncyColors.primaryDark.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildUserName(size),
              SizedBox(height: size.height * 0.015),
              _buildSubscriptionBadge(size),
              SizedBox(height: size.height * 0.02),
              _buildInfoSection(),
              SizedBox(height: size.height * 0.02),
              _buildSubscriptionButton(size),
              SizedBox(height: size.height * 0.015),
              _buildLogoutButton(size),
              SizedBox(height: size.height * 0.015),
              // Botón de certificado (visible solo si completó el programa)
              _buildCertificateButton(size),
            ],
          ),
        ),
        _buildProfileImage(size),
      ],
    );
  }

  // ========== WIDGETS DE UI ==========

  Widget _buildProfileImage(Size size) {
    final imageSize = size.width < 400
        ? 125.0
        : size.width < 600
            ? 140.0
            : 160.0;

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
                    size: size.width < 400
                        ? 40
                        : size.width < 600
                            ? 50
                            : 60,
                    color: const Color(0xFF4320AD),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildUserName(Size size) {
    return Text(
      widget.profileData?.fullName ??
          "${widget.profileData?.nombres ?? 'Usuario'} ${widget.profileData?.apellidos ?? ''}",
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: const Color(0xFF212121),
        fontSize: size.width < 400
            ? 20.0
            : size.width < 600
                ? 24.0
                : 28.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubscriptionBadge(Size size) {
    // Verificar si el usuario es de company_id 8
    int? companyId = widget.profileData?.idEmpresa;

    // Si NO es company_id 8, no mostrar el badge
    if (companyId != 8) {
      return SizedBox.shrink();
    }

    if (_loadingSubscription) {
      return SizedBox(
        height: 30,
        width: 30,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final isPro = _subscriptionData?.isPro ?? false;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width < 400 ? 12 : 16,
        vertical: size.width < 400 ? 6 : 8,
      ),
      decoration: BoxDecoration(
        gradient: isPro
            ? LinearGradient(
                colors: [Color(0xFF52178F), Color(0xFFA88BC7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPro ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPro
            ? [
                BoxShadow(
                  color: Color(0xFF8A67C8).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.workspace_premium : Icons.account_circle,
            color: Colors.white,
            size: size.width < 400 ? 16 : 18,
          ),
          SizedBox(width: 6),
          Text(
            isPro ? 'Funcy PRO' : 'Plan FREE',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: size.width < 400 ? 13 : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Sección de información: chips de color individuales en vez de una
  // grilla rígida de columnas. El número de columnas se decide con
  // LayoutBuilder, a partir del ANCHO DISPONIBLE real en ese punto del
  // árbol (nunca del ancho de pantalla), así que no importa cuánto se
  // estire la ventana: cada chip siempre tiene espacio suficiente y el
  // texto nunca queda comprimido letra por letra.
  Widget _buildInfoSection() {
    final items = <_InfoItem>[
      _InfoItem(
        icon: Icons.email_outlined,
        title: 'ID',
        value: widget.profileData?.username ?? 'No disponible',
        color: const Color(0xFF6D4BD8), // morado de marca
      ),
      _InfoItem(
        icon: Icons.female,
        title: 'Género',
        value: widget.profileData?.gender ?? 'No disponible',
        color: const Color(0xFF2FB8A6), // teal
      ),
      _InfoItem(
        icon: Icons.person_outline,
        title: 'Puesto',
        value: widget.profileData?.hierarchicalLevel ?? 'No disponible',
        color: const Color(0xFFEF7D57), // coral
      ),
      _InfoItem(
        icon: Icons.business_outlined,
        title: 'Centro',
        value: widget.profileData?.nombreEmpresa ?? 'No disponible',
        color: const Color(0xFFF2B134), // ámbar
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FuncyColors.primary.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: FuncyColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Información',
                style: GoogleFonts.inter(
                  color: const Color(0xFF212121),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              // 1 columna si el espacio real es angosto, 2 si alcanza.
              // Umbral bajo (380) a propósito: dos chips de ~180px cada
              // uno leen bien, y por debajo de eso una sola columna evita
              // cualquier compresión de texto.
              final columns = constraints.maxWidth < 380 ? 1 : 2;
              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items
                    .map((item) => SizedBox(
                          width: itemWidth,
                          child: _buildInfoChip(item),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: item.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF212121),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

  Widget _buildSubscriptionButton(Size size) {
    // Verificar si el usuario es de company_id 8
    int? companyId = widget.profileData?.idEmpresa;

    // Si NO es company_id 8, no mostrar el botón
    if (companyId != 8) {
      return SizedBox.shrink();
    }

    if (_loadingSubscription) {
      return SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isPro = _subscriptionData?.isPro ?? false;
    final buttonPadding = size.width < 400
        ? 14.0
        : size.width < 600
            ? 16.0
            : 18.0;
    final fontSize = size.width < 400
        ? 16.0
        : size.width < 600
            ? 16.0
            : 18.0;

    return Container(
      width: double.infinity,
      // Ancho fijo (ya no depende de size.width): al vivir dentro de la
      // tarjeta blanca, que ya está acotada por _maxContentWidth, un
      // límite fijo evita que el botón se vea desproporcionado.
      constraints: const BoxConstraints(maxWidth: 400),
      child: ElevatedButton.icon(
        onPressed: isPro
            ? _cancelSubscription
            : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionScreen()),
                );
                if (result == true) {
                  await _loadSubscriptionData();
                }
              },
        icon: Icon(
          isPro ? Icons.cancel : Icons.workspace_premium,
          size: size.width < 400 ? 18 : 20,
        ),
        label: Text(
          isPro ? 'Cancelar suscripción' : 'Suscríbete a Funcy PRO',
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPro ? Colors.red : Color(0xFF4320AD),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: size.width < 400 ? 24 : 32,
            vertical: buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(Size size) {
    final buttonPadding = size.width < 400
        ? 14.0
        : size.width < 600
            ? 16.0
            : 18.0;
    final fontSize = size.width < 400
        ? 16.0
        : size.width < 600
            ? 16.0
            : 18.0;

    // Acento rojo/coral (distinto de la familia morada usada en el resto
    // de la pantalla): así "Cerrar sesión" se lee de inmediato como una
    // acción distinta —de salida— y no compite visualmente con los CTAs
    // principales (suscripción, certificado).
    const logoutColor = Color(0xFFE0564C);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      child: OutlinedButton.icon(
        onPressed: () async {
          final result = await _showLogoutDialog();
          if (result != null) {
            await TokenService.instance.logout(logoutAll: result);
            widget.onLogout();
          }
        },
        icon: Icon(
          Icons.logout_rounded,
          color: logoutColor,
          size: size.width < 400 ? 18 : 20,
        ),
        label: Text(
          'Cerrar sesión',
          style: GoogleFonts.inter(
            color: logoutColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: logoutColor.withOpacity(0.06),
          padding: EdgeInsets.symmetric(
            horizontal: size.width < 400 ? 24 : 32,
            vertical: buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          side: BorderSide(
            color: logoutColor.withOpacity(0.35),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// Botón para ver el certificado (disponible después de completar el programa)
  Widget _buildCertificateButton(Size size) {
    final buttonPadding = size.width < 400
        ? 14.0
        : size.width < 600
            ? 16.0
            : 18.0;
    final fontSize = size.width < 400
        ? 14.0
        : size.width < 600
            ? 15.0
            : 16.0;

    // Si no ha completado el exit test, no mostrar el botón del certificado
    if (!widget.isDay21Completed) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6D4BD8), Color(0xFF5027D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6D4BD8).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CertificateScreen(
                username: widget.profileData?.fullName ?? 'Usuario',
                completionDate:
                    '${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} de ${DateTime.now().year}',
                programName: 'Programa de Manejo de Estrés Laboral - 21 Días',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: size.width < 400 ? 24 : 32,
            vertical: buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        icon: const Icon(Icons.workspace_premium, size: 22),
        label: Text(
          'Ver Mi Certificado',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return months[month - 1];
  }
}

// Pequeño contenedor de datos para cada chip de información del perfil.
class _InfoItem {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}