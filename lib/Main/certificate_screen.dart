import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:fnlapp/config.dart';
import 'package:fnlapp/Main/home.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'utils/pdf_download.dart';

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

  static TextStyle h2(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
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

/// Pantalla de certificado que se muestra al completar el programa de 21 días
/// Permite visualizar y descargar el certificado de finalización
class CertificateScreen extends StatefulWidget {
  final String? username;
  final String? completionDate;
  final String? programName;

  const CertificateScreen({
    Key? key,
    this.username,
    this.completionDate,
    this.programName = 'Programa de Manejo de Estrés Laboral',
  }) : super(key: key);

  @override
  _CertificateScreenState createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with SingleTickerProviderStateMixin {
  static const String _happyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/happy.png';
  static const String _sadUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/sad.png';

  static const double _maxContentWidth = 480.0;

  bool isLoading = true;
  Map<String, dynamic>? certificateData;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _savedPdfPath; // Ruta del PDF guardado (solo móvil)

  bool? _isGenerating = false; // bloquea toques repetidos en "Generar"
  bool? _isSharing = false; // bloquea toques repetidos en "Compartir"
  bool? _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCertificateData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached != true) {
      precacheImage(const NetworkImage(_happyUrl), context);
      precacheImage(const NetworkImage(_sadUrl), context);
      _imagesPrecached = true;
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _loadCertificateData() async {
    // Simplemente usar datos proporcionados por el widget
    if (!mounted) return;
    setState(() {
      certificateData = {
        'username': widget.username ?? 'Usuario',
        'completionDate': widget.completionDate ?? _formatDate(DateTime.now()),
        'programName':
            widget.programName ?? 'Programa de Manejo de Estrés Laboral',
        'certificateId': 'FNL-${DateTime.now().millisecondsSinceEpoch}',
      };
      isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _field(String key, String fallback) {
    final value = certificateData?[key]?.toString().trim();
    return (value == null || value.isEmpty) ? fallback : value;
  }

  String get _userName =>
      (certificateData?['username'] ?? widget.username ?? 'Usuario')
          .toString();

  // ========== MENSAJES ==========

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  // ========== DESCARGA Y COMPARTIR ==========

  Future<void> _downloadCertificate() async {
    if (_isGenerating == true) return;
    setState(() => _isGenerating = true);

    try {
      String? token = await getToken();

      if (token == null) {
        _showSnack('Error: No se encontró token de autenticación',
            error: true);
        return;
      }

      _showSnack('Generando certificado...');

      // Generar certificado usando el endpoint del backend
      final generateResponse = await http.post(
        Uri.parse('${Config.apiUrl2}/certificates/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userName':
              certificateData?['username'] ?? widget.username ?? 'Usuario',
        }),
      );

      print('🎓 Generate Certificate Response: ${generateResponse.statusCode}');
      print('🎓 Content-Type: ${generateResponse.headers['content-type']}');

      if (generateResponse.statusCode == 200 ||
          generateResponse.statusCode == 201) {
        // Verificar si la respuesta es un PDF
        final contentType = generateResponse.headers['content-type'] ?? '';

        if (contentType.contains('application/pdf')) {
          // El backend devuelve el PDF directamente
          print(
              '📥 PDF recibido directamente (${generateResponse.bodyBytes.length} bytes)');

          // Descargar/abrir el PDF según la plataforma
          final pdfBytes = generateResponse.bodyBytes;
          final userName = _userName;
          final fileName = 'Certificado_${userName.replaceAll(' ', '_')}.pdf';

          if (kIsWeb) {
            // En web: Crear blob URL y descargar automáticamente
            try {
              await _downloadPdfWeb(pdfBytes, fileName);
              print('✅ PDF descargado en web correctamente');
              _showSnack('¡Certificado generado exitosamente!');
            } catch (e) {
              print('❌ Error al descargar PDF en web: $e');
              _showSnack('Error al descargar el PDF', error: true);
            }
          } else {
            // En móvil: Guardar el PDF
            try {
              // Primero guardamos temporalmente para tener una ruta
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/$fileName');
              await tempFile.writeAsBytes(pdfBytes);

              // Guardar la ruta para compartir después
              if (mounted) {
                setState(() {
                  _savedPdfPath = tempFile.path;
                });
              }

              if (Platform.isIOS) {
                // En iOS: Usar Share para que el usuario elija dónde guardar
                // El sistema mostrará opciones como "Guardar en Archivos"
                await Share.shareXFiles(
                  [XFile(tempFile.path)],
                  subject: 'Certificado $userName',
                );

                _showSnack(
                    'Selecciona "Guardar en Archivos" para guardar tu certificado');
              } else if (Platform.isAndroid) {
                // En Android, guardar directamente en Downloads
                Directory? directory =
                    Directory('/storage/emulated/0/Download');
                if (!await directory.exists()) {
                  directory = await getExternalStorageDirectory();
                }

                if (directory != null) {
                  final file = File('${directory.path}/$fileName');
                  await file.writeAsBytes(pdfBytes);

                  if (mounted) {
                    setState(() {
                      _savedPdfPath = file.path;
                    });
                  }

                  print('📄 PDF guardado en: ${file.path}');
                  _showSnack('Certificado guardado en Descargas');
                }
              }
            } catch (e) {
              print('❌ Error al guardar PDF en móvil: $e');
              _showSnack('Error al guardar el certificado', error: true);
            }
          }
        } else {
          // La respuesta es JSON
          final responseData = json.decode(generateResponse.body);

          if (responseData['success'] == true) {
            _showSnack(responseData['message']?.toString() ??
                '¡Certificado generado exitosamente!');

            // Si hay URL de descarga, mostrarla (opcional - backend retorna PDF directo)
            if (responseData['downloadUrl'] != null) {
              print('📥 Download URL: ${responseData['downloadUrl']}');
            }

            // Si hay datos del certificado, actualizar el estado
            if (responseData['certificate'] != null && mounted) {
              setState(() {
                certificateData = responseData['certificate'];
              });
            }
          } else {
            throw Exception(
                responseData['message'] ?? 'Error al generar certificado');
          }
        }
      } else {
        try {
          final errorData = json.decode(generateResponse.body);
          throw Exception(errorData['message'] ??
              'Error al generar certificado: ${generateResponse.statusCode}');
        } catch (e) {
          throw Exception(
              'Error al generar certificado: ${generateResponse.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error al generar certificado: $e');
      _showSnack('No se pudo generar el certificado', error: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Descarga el PDF en web usando blob URL
  Future<void> _downloadPdfWeb(List<int> pdfBytes, String fileName) async {
    if (kIsWeb) {
      await downloadPdfWeb(pdfBytes, fileName);
      print('✅ PDF descargado: $fileName');
    }
  }

  /// Pide el PDF al backend y devuelve los bytes 
  Future<Uint8List?> _fetchCertificatePdfBytes() async {
    try {
      final token = await getToken();

      if (token == null) {
        _showSnack('Error: No se encontró token de autenticación',
            error: true);
        return null;
      }

      final generateResponse = await http.post(
        Uri.parse('${Config.apiUrl2}/certificates/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userName':
              certificateData?['username'] ?? widget.username ?? 'Usuario',
        }),
      );

      final contentType = generateResponse.headers['content-type'] ?? '';
      if ((generateResponse.statusCode == 200 ||
              generateResponse.statusCode == 201) &&
          contentType.contains('application/pdf')) {
        return generateResponse.bodyBytes;
      }

      throw Exception(
          'Error al generar certificado: ${generateResponse.statusCode}');
    } catch (e) {
      print('❌ Error al generar PDF: $e');
      _showSnack('Error al generar el certificado', error: true);
      return null;
    }
  }


  Future<String?> _generateAndSavePdf() async {
    final pdfBytes = await _fetchCertificatePdfBytes();
    if (pdfBytes == null) return null;

    try {
      final fileName =
          'Certificado_Funcional_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Guardar en directorio temporal; el compartir ofrece las opciones
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      print('📄 PDF guardado temporalmente en: ${file.path}');

      if (mounted) {
        setState(() {
          _savedPdfPath = file.path;
        });
      }

      return file.path;
    } catch (e) {
      print('❌ Error al guardar PDF: $e');
      _showSnack('Error al generar el certificado', error: true);
      return null;
    }
  }

  Future<void> _shareCertificate() async {
    if (_isSharing == true) return;
    setState(() => _isSharing = true);

    final shareText =
        '¡He completado el ${widget.programName ?? "programa"} con Funcional Neuro Laboral! 🎓';

    try {
      if (kIsWeb) {
        _showSnack('Generando certificado...');
        final bytes = await _fetchCertificatePdfBytes();
        if (bytes == null) return;

        final fileName = 'Certificado_${_userName.replaceAll(' ', '_')}.pdf';

        bool shared = false;
        try {
          final result = await Share.shareXFiles(
            [
              XFile.fromData(
                bytes,
                mimeType: 'application/pdf',
                name: fileName,
              )
            ],
            fileNameOverrides: [fileName],
            text: shareText,
            subject: 'Mi Certificado FNL',
          );
          shared = result.status != ShareResultStatus.unavailable;
        } catch (e) {
          print('⚠️ Web Share no disponible: $e');
        }

        // Si el navegador no permite compartir archivos, se descarga.
        if (!shared) {
          await _downloadPdfWeb(bytes, fileName);
          _showSnack('Tu navegador no permite compartir; se descargó el PDF');
        }
        return;
      }

      // ---------- MÓVIL ----------
      String? pdfPath = _savedPdfPath;

      if (pdfPath == null || !File(pdfPath).existsSync()) {
        _showSnack('Generando certificado...');
        pdfPath = await _generateAndSavePdf();
      }

      if (pdfPath != null && File(pdfPath).existsSync()) {
        // Compartir el PDF junto con el texto
        final result = await Share.shareXFiles(
          [XFile(pdfPath)],
          text: shareText,
          subject: 'Mi Certificado FNL',
        );

        if (result.status == ShareResultStatus.success) {
          print('✅ Certificado compartido exitosamente');
        }
      }
    } catch (e) {
      print('❌ Error al compartir: $e');
      _showSnack('Error al compartir el certificado', error: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoading) {
      content = _buildLoadingState();
    } else if (errorMessage != null) {
      content = _buildErrorState();
    } else {
      content = _buildCertificateContent();
    }

    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
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
            SafeArea(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _FnlColors.violet,
            ),
          ),
          const SizedBox(height: _FnlSpace.sm),
          Text('Preparando tu certificado...', style: _FnlText.body()),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_FnlSpace.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _buildMascot(_sadUrl, 120)),
              const SizedBox(height: _FnlSpace.sm),
              Text(
                'No pudimos cargar tu certificado',
                textAlign: TextAlign.center,
                style: _FnlText.h2(22),
              ),
              const SizedBox(height: _FnlSpace.xs),
              Text(
                errorMessage ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: _FnlText.body(),
              ),
              const SizedBox(height: _FnlSpace.md),
              _PrimaryButton(
                label: 'Volver al inicio',
                icon: Icons.arrow_forward_rounded,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateContent() {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
    final titleSize = width < 400 ? 28.0 : 34.0;
    final mascotSize = isTablet ? 150.0 : 120.0;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final body = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            // El contenido mide al menos el alto visible: se centra cuando cabe
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad, vertical: _FnlSpace.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(titleSize),
                      const SizedBox(height: _FnlSpace.md),
                      _buildHeroCard(mascotSize),
                      const SizedBox(height: _FnlSpace.md),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (reduceMotion) return body;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: body),
    );
  }

  Widget _buildHeader(double titleSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FUNCY · LOGRO',
          style: _FnlText.label(
            size: 12,
            color: _FnlColors.violet,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text('Mi certificado', style: _FnlText.h1(titleSize)),
        ),
      ],
    );
  }


  Widget _buildHeroCard(double mascotSize) {
    final overlap = mascotSize / 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: overlap),
          padding: EdgeInsets.fromLTRB(
            _FnlSpace.md,
            overlap + _FnlSpace.sm,
            _FnlSpace.md,
            _FnlSpace.md,
          ),
          decoration: BoxDecoration(
            color: _FnlColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: _FnlColors.bubbleBorder,
                offset: Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Píldora de estado
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _FnlColors.lavender,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: _FnlColors.bubbleBorder, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 18, color: _FnlColors.violet),
                      const SizedBox(width: 6),
                      Text(
                        'Tu certificado está listo',
                        style: _FnlText.label(color: _FnlColors.violet),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  '¡Programa completado!',
                  textAlign: TextAlign.center,
                  style: _FnlText.h2(24),
                ),
              ),
              const SizedBox(height: _FnlSpace.xs),
              Text(
                'Has finalizado exitosamente el Programa de Bienestar Emocional.',
                textAlign: TextAlign.center,
                style: _FnlText.body(size: 15),
              ),
              const SizedBox(height: _FnlSpace.md),
              const Divider(
                height: 2,
                thickness: 2,
                color: _FnlColors.lavender,
              ),
              const SizedBox(height: _FnlSpace.sm),
              _buildInfoRow(
                icon: Icons.person_rounded,
                title: 'Otorgado a',
                value: _field('username', 'Usuario'),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.school_rounded,
                title: 'Programa',
                value: _field(
                    'programName', 'Programa de Manejo de Estrés Laboral'),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.event_rounded,
                title: 'Fecha',
                value: _field('completionDate', _formatDate(DateTime.now())),
              ),
            ],
          ),
        ),
        _FloatingMascot(child: _buildMascot(_happyUrl, mascotSize)),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Semantics(
      label: '$title: $value',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _FnlColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _FnlColors.violet, size: 22),
          ),
          const SizedBox(width: _FnlSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: _FnlText.label(
                    size: 12,
                    color: _FnlColors.body,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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
      ),
    );
  }

  Widget _buildActions() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrimaryButton(
              label: 'Generar certificado',
              icon: Icons.download_rounded,
              loading: _isGenerating == true,
              onTap: _downloadCertificate,
            ),
            const SizedBox(height: 12),
            _SecondaryButton(
              label: 'Compartir',
              icon: Icons.share_rounded,
              loading: _isSharing == true,
              onTap: _shareCertificate,
            ),
            const SizedBox(height: _FnlSpace.xs),
            _TextAction(label: 'Volver al inicio', onTap: _goHome),
          ],
        ),
      ),
    );
  }

  // Mascota con halo
  Widget _buildMascot(String url, double size) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.7,
            height: size * 0.7,
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
          Image.network(
            url,
            height: size,
            width: size,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: size,
                width: size,
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _FnlColors.violetSecondary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => SizedBox(height: size, width: size),
          ),
        ],
      ),
    );
  }
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

/// Movimiento vertical suave y continuo para la mascota.
/// Se desactiva si el usuario pidió reducir animaciones.
class _FloatingMascot extends StatefulWidget {
  final Widget child;
  const _FloatingMascot({required this.child});

  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -8 * _curve.value),
        child: child,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool? loading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = loading ?? false;
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: _FnlColors.violet,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
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
                            style: _FnlText.button(),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 20, color: _FnlColors.white),
                        ],
                      ],
                    ),
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
  final bool? loading;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = loading ?? false;
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 52,
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
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
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
          color: _FnlColors.label,
        ),
      ),
    );
  }
}