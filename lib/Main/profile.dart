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
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:fnlapp/Main/certificate_screen.dart';
import '../Politicas y Terminos/condiciones_uso.dart';
import '../Politicas y Terminos/politica_privacidad.dart';
import '../theme/app_colors.dart';
import '../Util/date_format_es.dart';
import 'plan.dart' show totalProgramDays;

class ProfileScreen extends StatefulWidget {
  final ProfileData? profileData;
  final Function onLogout;
  final Function(String)? onImageSelected;
  final Function(String)? onProfileImageUpdated;
  final bool isDay21Completed;
  final int completedDays;

  ProfileScreen({
    required this.profileData,
    required this.onLogout,
    this.onImageSelected,
    this.onProfileImageUpdated,
    this.isDay21Completed = false,
    this.completedDays = 0,
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

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
    _loadTextSize();
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
        Uri.parse('${Config.apiUrl2}/subscriptions/current'),
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
        Uri.parse('${Config.apiUrl2}/subscriptions/cancel'),
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

      String url = '${Config.apiUrl2}/users/getprofile/$userId';
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
          title: const Text('¿Cerrar sesión?'),
          content: const Text('Tu progreso queda guardado. Puedes cerrar la sesión solo aquí o en todos tus dispositivos.'),
          actionsOverflowDirection: VerticalDirection.up,
          actionsOverflowButtonSpacing: 4,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('En todos mis dispositivos'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Solo en este dispositivo'),
            ),
          ],
        );
      },
    );
  }


  // ========== BUILD PRINCIPAL ==========

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = widget.profileData;
    final name = (profile?.fullName ?? '${profile?.nombres ?? 'Usuario'} ${profile?.apellidos ?? ''}').trim();
    final isCompany8 = profile?.idEmpresa == 8;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text('Perfil', style: textTheme.headlineMedium),
                const SizedBox(height: 14),
                _buildProfileCard(name, isCompany8),
                _sectionLabel('Tus datos'),
                _group([
                  _infoRow(Icons.alternate_email_rounded, 'Usuario', profile?.username ?? 'No disponible'),
                  _infoRow(Icons.work_outline_rounded, 'Puesto', profile?.hierarchicalLevel ?? 'No disponible'),
                  _infoRow(Icons.business_outlined, 'Empresa', profile?.nombreEmpresa ?? 'No disponible'),
                ]),
                _sectionLabel('Preferencias'),
                _group([
                  _actionRow(
                    icon: Icons.text_fields_rounded,
                    label: 'Tamaño del texto en actividades',
                    value: _textSizeLabel,
                    onTap: _chooseTextSize,
                  ),
                ]),
                if (isCompany8) ...[
                  _sectionLabel('Suscripción'),
                  _group([_buildSubscriptionRow()]),
                ],
                _sectionLabel('Ayuda'),
                _group([
                  _actionRow(
                    icon: Icons.description_outlined,
                    label: 'Términos de uso',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CondicionesUsoScreen())),
                  ),
                  _actionRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Política de privacidad',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PoliticaPrivacidadScreen())),
                  ),
                ]),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await _showLogoutDialog();
                    if (result != null) {
                      await TokenService.instance.logout(logoutAll: result);
                      widget.onLogout();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.errorBorder, width: 1.5),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== WIDGETS DE UI ==========

  Widget _buildProfileCard(String name, bool isCompany8) {
    final textTheme = Theme.of(context).textTheme;
    final completed = widget.completedDays.clamp(0, totalProgramDays);
    final imageProvider = _getImageProvider();
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.lavenderStrong,
                    foregroundImage: imageProvider,
                    child: Text(initial,
                        style: const TextStyle(color: AppColors.primaryDeep, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: IconButton(
                      tooltip: 'Cambiar foto de perfil',
                      onPressed: _pickImage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 3),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.photo_camera_outlined, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 1),
                    Text(
                      widget.profileData?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary, fontWeight: FontWeight.w400),
                    ),
                    if (isCompany8 && !_loadingSubscription) ...[
                      const SizedBox(height: 6),
                      _subscriptionBadge(_subscriptionData?.isPro ?? false),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Programa de $totalProgramDays días', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700))),
              Text('$completed de $totalProgramDays',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDeep)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: completed / totalProgramDays, minHeight: 8),
          ),
          const SizedBox(height: 12),
          if (widget.isDay21Completed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CertificateScreen(
                        username: widget.profileData?.fullName ?? 'Usuario',
                        completionDate: DateFormatEs.long(DateTime.now()),
                        programName: 'Programa de Manejo de Estrés Laboral - 21 Días',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.workspace_premium_outlined, size: 20),
                label: const Text('Ver mi certificado'),
              ),
            )
          else
            const Row(
              children: [
                Icon(Icons.workspace_premium_outlined, size: 16, color: AppColors.inkSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu certificado se habilita al completar el Día 21 y el test de salida.',
                    style: TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.inkSecondary),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _subscriptionBadge(bool isPro) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isPro ? AppColors.streakBg : AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPro ? Icons.star_rounded : Icons.person_outline_rounded,
              size: 14, color: isPro ? AppColors.streak : AppColors.inkSecondary),
          const SizedBox(width: 4),
          Text(isPro ? 'Funcy PRO' : 'Plan gratuito',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: isPro ? AppColors.streakText : AppColors.inkSecondary)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionRow() {
    if (_loadingSubscription) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
    }
    final isPro = _subscriptionData?.isPro ?? false;
    return _actionRow(
      icon: Icons.workspace_premium_outlined,
      label: isPro ? 'Funcy PRO' : 'Suscríbete a Funcy PRO',
      value: isPro ? 'Activa' : null,
      valueColor: AppColors.successText,
      onTap: isPro
          ? _cancelSubscription
          : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionScreen()),
              );
              if (result == true) await _loadSubscriptionData();
            },
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Semantics(
        header: true,
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkTertiary)),
      ),
    );
  }

  Widget _group(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDeep),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.inkSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? value,
    Color valueColor = AppColors.inkSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryDeep),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              if (value != null) ...[
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }

  // ========== TAMAÑO DE TEXTO ==========

  static const _textSizes = [(17.0, 'Pequeño'), (20.0, 'Mediano'), (24.0, 'Grande')];
  double _stepTextSize = 20.0;

  String get _textSizeLabel =>
      _textSizes.firstWhere((t) => t.$1 == _stepTextSize, orElse: () => _textSizes[1]).$2;

  Future<void> _loadTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble('stepTextSize');
    if (value != null && mounted) setState(() => _stepTextSize = value);
  }

  Future<void> _chooseTextSize() async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('Tamaño del texto', style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            for (final option in _textSizes)
              ListTile(
                onTap: () => Navigator.of(sheetContext).pop(option.$1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(option.$2, style: TextStyle(fontSize: option.$1 - 2, fontWeight: FontWeight.w600)),
                trailing: option.$1 == _stepTextSize
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : const Icon(Icons.circle_outlined, color: AppColors.placeholder),
                selected: option.$1 == _stepTextSize,
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('stepTextSize', selected);
    if (mounted) setState(() => _stepTextSize = selected);
  }
}
