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
import 'package:google_fonts/google_fonts.dart';
import 'package:fnlapp/Main/certificate_screen.dart';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
  static const label = Color(0xFF5F668B);
  static const border = Color(0xFFD9DCEF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const disabledText = Color(0xFF9AA0C0);
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
}

class _FnlText {
  static TextStyle h1(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.2,
      );

  static TextStyle h2(double size, {Color color = _FnlColors.blue}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.25,
      );

  static TextStyle body({
    double size = 16,
    Color color = _FnlColors.body,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );

  static TextStyle label({
    double size = 14,
    Color color = _FnlColors.label,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle button({Color color = _FnlColors.white}) =>
      GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

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
  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  SubscriptionData? _subscriptionData;
  bool _loadingSubscription = true;
  bool _isUploadingPhoto = false; // bloquea toques repetidos en la foto
  bool _isLoggingOut = false;
  bool _imagesPrecached = false;

  // Ancho máximo del contenido: evita que las tarjetas se estiren de borde
  // a borde en tablet/web.
  static const double _maxContentWidth = 560.0;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const NetworkImage(_funcyUrl), context);
      _imagesPrecached = true;
    }
  }

  // ========== MENSAJES ==========

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _FnlColors.blue,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: _FnlColors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: _FnlText.body(size: 14, color: _FnlColors.white),
              ),
            ),
          ],
        ),
      ),
    );
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
        if (!mounted) return;
        setState(() {
          _subscriptionData = SubscriptionData.fromJson(jsonData);
          _loadingSubscription = false;
        });
      } else {
        throw Exception('Error al cargar suscripción');
      }
    } catch (e) {
      debugPrint('Error al cargar datos de suscripción: $e');
      if (!mounted) return;
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

      if (token == null) {
        throw Exception('No se pudo obtener el token');
      }

      final response = await http.post(
        Uri.parse('${app_config.Config.apiUrl2}/subscriptions/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _loadSubscriptionData();
        _showSnack('Suscripción cancelada exitosamente');
      } else {
        throw Exception('Error al cancelar suscripción');
      }
    } catch (e) {
      debugPrint('Error al cancelar suscripción: $e');
      _showSnack('Error al cancelar suscripción', error: true);
    }
  }

  Future<T?> _showFnlDialog<T>({
    required String title,
    required String message,
    required List<Widget> Function(BuildContext dialogContext) actionsBuilder,
    bool barrierDismissible = true,
  }) {
    const double mascotHeight = 88;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: _FnlColors.blue.withOpacity(0.55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: _FnlSpace.md, vertical: _FnlSpace.md),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: mascotHeight / 2),
                    padding: const EdgeInsets.fromLTRB(
                        _FnlSpace.md, mascotHeight / 2 + _FnlSpace.sm,
                        _FnlSpace.md, _FnlSpace.md),
                    decoration: BoxDecoration(
                      color: _FnlColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border:
                          Border.all(color: _FnlColors.bubbleBorder, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: _FnlColors.bubbleBorder,
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: _FnlText.h2(24),
                          ),
                          const SizedBox(height: _FnlSpace.xs),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: _FnlText.body(),
                          ),
                          const SizedBox(height: _FnlSpace.md),
                          ...actionsBuilder(dialogContext),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: mascotHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: mascotHeight * 0.7,
                          height: mascotHeight * 0.7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _FnlColors.violetSecondary
                                    .withOpacity(0.22),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Image.network(
                          _funcyUrl,
                          height: mascotHeight,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              height: mascotHeight,
                              width: mascotHeight,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _FnlColors.violetSecondary,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => SizedBox(
                              height: mascotHeight, width: mascotHeight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showCancelDialog() {
    return _showFnlDialog<bool>(
      title: 'Cancelar suscripción',
      message: '¿Estás seguro de que deseas cancelar tu suscripción Funcy PRO?',
      actionsBuilder: (ctx) => [
        _PrimaryButton(
          label: 'No',
          onTap: () => Navigator.of(ctx).pop(false),
        ),
        const SizedBox(height: _FnlSpace.xs),
        _TextAction(
          label: 'Sí, cancelar',
          onTap: () => Navigator.of(ctx).pop(true),
        ),
      ],
    );
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return _showFnlDialog<ImageSource>(
      title: 'Seleccionar imagen',
      message: '¿De dónde quieres obtener la imagen?',
      actionsBuilder: (ctx) => [
        _PrimaryButton(
          label: 'Cámara',
          icon: Icons.photo_camera_rounded,
          onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: 'Galería',
          icon: Icons.photo_library_rounded,
          onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
        ),
        const SizedBox(height: _FnlSpace.xs),
        _TextAction(
          label: 'Cancelar',
          onTap: () => Navigator.of(ctx).pop(),
        ),
      ],
    );
  }

  Future<bool?> _showLogoutDialog() {
    return _showFnlDialog<bool>(
      title: 'Cerrar sesión',
      message: '¿Deseas cerrar sesión en todos tus dispositivos?',
      actionsBuilder: (ctx) => [
        _PrimaryButton(
          label: 'Solo este dispositivo',
          onTap: () => Navigator.of(ctx).pop(false),
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: 'Todos los dispositivos',
          onTap: () => Navigator.of(ctx).pop(true),
        ),
        const SizedBox(height: _FnlSpace.xs),
        _TextAction(
          label: 'Cancelar',
          onTap: () => Navigator.of(ctx).pop(),
        ),
      ],
    );
  }

  // ========== MÉTODOS DE IMAGEN DE PERFIL ==========

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null && _selectedImageBytes == null) {
      return;
    }

    if (mounted) setState(() => _isUploadingPhoto = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('token');

      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      final uri =
          Uri.parse('${app_config.Config.apiUrl2}/users/upload-photo/$userId');
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

        if (mounted) {
          setState(() {
            _selectedImage = null;
            _selectedImageBytes = null;
          });
        }

        _showSnack('Imagen de perfil actualizada exitosamente');
      } else {
        final errorResponse = json.decode(responseBody);
        throw Exception(
            'Error del servidor: ${response.statusCode} - ${errorResponse['error']['message']}');
      }
    } catch (e) {
      debugPrint('Error al subir imagen de perfil: $e');

      if (mounted) {
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      }
      _showSnack('Error al actualizar imagen de perfil', error: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
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

        if (!mounted) return;
        setState(() {
          if (widget.profileData != null) {
            widget.profileData!.profileImage = updatedProfile.profileImage;
          }
        });
      }
    } catch (e) {
      debugPrint('Error al recargar perfil desde servidor: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_isUploadingPhoto) return;

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
          _showSnack('Solo se permiten imágenes JPG o PNG', error: true);
          return;
        }

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          if (!mounted) return;
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
      debugPrint('Error al seleccionar imagen: $e');
      _showSnack('No se pudo seleccionar la imagen', error: true);
    }
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

  // ========== BUILD PRINCIPAL ==========

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;

    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: Stack(
        children: [
          // Círculos decorativos
          const Positioned(
            top: -70,
            right: -70,
            child: IgnorePointer(child: _DecorCircle(size: 220)),
          ),
          const Positioned(
            bottom: -90,
            left: -90,
            child: IgnorePointer(child: _DecorCircle(size: 240)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              // El espacio inferior deja libre la barra de navegación
              padding: const EdgeInsets.only(bottom: 110),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: hPad, vertical: _FnlSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(size),
                        const SizedBox(height: _FnlSpace.md),
                        _buildProfileCard(size),
                        const SizedBox(height: _FnlSpace.sm),
                        _buildInfoCard(),
                        const SizedBox(height: _FnlSpace.md),
                        ..._buildActions(size),
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

  Widget _buildHeader(Size size) {
    final titleFontSize = size.width < 400 ? 28.0 : 34.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FUNCY · DETALLES',
          style: _FnlText.label(
            size: 12,
            color: _FnlColors.violet,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text('Mi Perfil', style: _FnlText.h1(titleFontSize)),
      ],
    );
  }

  Widget _buildProfileCard(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: _FnlSpace.md, vertical: _FnlSpace.md),
      decoration: BoxDecoration(
        color: _FnlColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: _FnlColors.bubbleBorder,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileImage(size),
          const SizedBox(height: _FnlSpace.sm),
          _buildUserName(size),
          _buildSubscriptionBadge(size),
        ],
      ),
    );
  }

  Widget _buildProfileImage(Size size) {
    final imageSize = size.width < 400
        ? 112.0
        : size.width < 600
            ? 128.0
            : 144.0;
    final provider = _getImageProvider();

    return Semantics(
      button: true,
      label: 'Cambiar foto de perfil',
      child: GestureDetector(
        onTap: _isUploadingPhoto ? null : _pickImage,
        child: SizedBox(
          width: imageSize + 12,
          height: imageSize + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo
              Container(
                width: imageSize * 0.85,
                height: imageSize * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _FnlColors.violetSecondary.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              // Foto
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _FnlColors.lavender,
                  border: Border.all(color: _FnlColors.violet, width: 3),
                  image: provider != null
                      ? DecorationImage(image: provider, fit: BoxFit.cover)
                      : null,
                ),
                child: provider == null
                    ? Icon(
                        Icons.person_rounded,
                        size: imageSize * 0.45,
                        color: _FnlColors.violet,
                      )
                    : null,
              ),
              // Overlay mientras sube
              if (_isUploadingPhoto)
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _FnlColors.white.withOpacity(0.7),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: _FnlColors.violet,
                      ),
                    ),
                  ),
                ),
              // Insignia de cámara
              Positioned(
                right: 0,
                bottom: 4,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _FnlColors.violet,
                    shape: BoxShape.circle,
                    border: Border.all(color: _FnlColors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 18,
                    color: _FnlColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserName(Size size) {
    final fontSize = size.width < 400
        ? 20.0
        : size.width < 600
            ? 22.0
            : 24.0;

    return Text(
      widget.profileData?.fullName ??
          "${widget.profileData?.nombres ?? 'Usuario'} ${widget.profileData?.apellidos ?? ''}",
      textAlign: TextAlign.center,
      style: _FnlText.h2(fontSize),
    );
  }

  Widget _buildSubscriptionBadge(Size size) {
    // Verificar si el usuario es de company_id 8
    int? companyId = widget.profileData?.idEmpresa;

    // Si NO es company_id 8, no mostrar el badge
    if (companyId != 8) {
      return const SizedBox.shrink();
    }

    if (_loadingSubscription) {
      return const Padding(
        padding: EdgeInsets.only(top: _FnlSpace.xs),
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _FnlColors.violet,
          ),
        ),
      );
    }

    final isPro = _subscriptionData?.isPro ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: _FnlSpace.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isPro ? _FnlColors.violet : _FnlColors.lavender,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPro ? _FnlColors.violet : _FnlColors.bubbleBorder,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPro
                  ? Icons.workspace_premium_rounded
                  : Icons.account_circle_rounded,
              color: isPro ? _FnlColors.white : _FnlColors.violet,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isPro ? 'Funcy PRO' : 'Plan FREE',
              style: _FnlText.label(
                color: isPro ? _FnlColors.white : _FnlColors.violet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de información con filas icono + etiqueta + valor
  Widget _buildInfoCard() {
    final items = <_InfoItem>[
      _InfoItem(
        icon: Icons.alternate_email_rounded,
        title: 'Nombre de Usuario',
        value: widget.profileData?.username ?? 'No disponible',
      ),
      _InfoItem(
        icon: Icons.wc_rounded,
        title: 'Género',
        value: widget.profileData?.gender ?? 'No disponible',
      ),
      _InfoItem(
        icon: Icons.badge_outlined,
        title: 'Puesto',
        value: widget.profileData?.hierarchicalLevel ?? 'No disponible',
      ),
      _InfoItem(
        icon: Icons.business_rounded,
        title: 'Centro',
        value: widget.profileData?.nombreEmpresa ?? 'No disponible',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_FnlSpace.md),
      decoration: BoxDecoration(
        color: _FnlColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _FnlColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: _FnlColors.border,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMACIÓN',
            style: _FnlText.label(size: 13, letterSpacing: 1.0),
          ),
          const SizedBox(height: _FnlSpace.sm),
          for (int i = 0; i < items.length; i++) ...[
            _buildInfoRow(items[i]),
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 2,
                  thickness: 2,
                  color: _FnlColors.lavender,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: _FnlColors.lavender,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: _FnlColors.violet, size: 22),
        ),
        const SizedBox(width: _FnlSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title.toUpperCase(),
                style: _FnlText.label(
                  size: 12,
                  color: _FnlColors.body,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: _FnlText.body(
                  color: _FnlColors.blue,
                  weight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Botones de acción
  List<Widget> _buildActions(Size size) {
    final actions = <Widget?>[
      _buildCertificateButton(),
      _buildSubscriptionButton(),
      _buildLogoutButton(),
    ].whereType<Widget>().toList();

    final spaced = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: _FnlSpace.sm));
      spaced.add(Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: actions[i],
        ),
      ));
    }
    return spaced;
  }

  Widget? _buildSubscriptionButton() {
    // Verificar si el usuario es de company_id 8
    int? companyId = widget.profileData?.idEmpresa;

    // Si NO es company_id 8, no mostrar el botón
    if (companyId != 8) {
      return null;
    }

    if (_loadingSubscription) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _FnlColors.violet,
          ),
        ),
      );
    }

    final isPro = _subscriptionData?.isPro ?? false;

    if (isPro) {
      // Cancelar suscripción: acción secundaria
      return _SecondaryButton(
        label: 'Cancelar suscripción',
        icon: Icons.cancel_outlined,
        onTap: _cancelSubscription,
      );
    }

    // Suscribirse: CTA primario
    return _PrimaryButton(
      label: 'Suscríbete a Funcy PRO',
      icon: Icons.arrow_forward_rounded,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubscriptionScreen()),
        );
        if (result == true) {
          await _loadSubscriptionData();
        }
      },
    );
  }

  Widget _buildLogoutButton() {
    return _SecondaryButton(
      label: 'Cerrar sesión',
      icon: Icons.logout_rounded,
      loading: _isLoggingOut,
      onTap: () async {
        if (_isLoggingOut) return;
        final result = await _showLogoutDialog();
        if (result == null) return;

        if (mounted) setState(() => _isLoggingOut = true);
        try {
          await TokenService.instance.logout(logoutAll: result);
          widget.onLogout();
        } catch (e) {
          debugPrint('Error al cerrar sesión: $e');
          _showSnack('No se pudo cerrar la sesión', error: true);
        } finally {
          if (mounted) setState(() => _isLoggingOut = false);
        }
      },
    );
  }

  /// Botón para ver el certificado (disponible después de completar el programa)
  Widget? _buildCertificateButton() {
    // Si no ha completado el exit test, no mostrar el botón del certificado
    if (!widget.isDay21Completed) {
      return null;
    }

    return _PrimaryButton(
      label: 'Ver Mi Certificado',
      icon: Icons.arrow_forward_rounded,
      onTap: () {
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

// Pequeño contenedor de datos para cada fila de información del perfil.
class _InfoItem {
  final IconData icon;
  final String title;
  final String value;

  _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}

class _DecorCircle extends StatelessWidget {
  final double size;
  const _DecorCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _FnlColors.lavenderDeep,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final Color fg = enabled ? _FnlColors.white : _FnlColors.disabledText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: (enabled || loading) ? _FnlColors.violet : _FnlColors.border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled && !loading ? onTap : null,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_FnlColors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: _FnlText.button(color: fg),
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20, color: fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool loading;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
        borderRadius: radius,
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: loading ? null : onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _FnlColors.violet,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: _FnlColors.violet),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _FnlColors.violet,
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
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: _FnlColors.violet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _FnlColors.violet,
        ),
      ),
    );
  }
}