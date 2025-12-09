import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:fnlapp/config.dart';
import 'package:fnlapp/Main/home.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'utils/pdf_download.dart';

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
  bool isLoading = true;
  Map<String, dynamic>? certificateData;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _savedPdfPath; // Ruta del PDF guardado

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCertificateData();
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _loadCertificateData() async {
    // Simplemente usar datos proporcionados por el widget
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

  Future<void> _downloadCertificate() async {
    try {
      String? token = await getToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se encontró token de autenticación'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generando certificado...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

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

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Certificado generado exitosamente!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }

          // Descargar/abrir el PDF según la plataforma
          final pdfBytes = generateResponse.bodyBytes;
          final userName =
              certificateData?['username'] ?? widget.username ?? 'Usuario';
          final fileName = 'Certificado_${userName.replaceAll(' ', '_')}.pdf';

          if (kIsWeb) {
            // En web: Crear blob URL y descargar automáticamente
            try {
              _downloadPdfWeb(pdfBytes, fileName);
              print('✅ PDF descargado en web correctamente');
            } catch (e) {
              print('❌ Error al descargar PDF en web: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al descargar el PDF: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // En móvil: Guardar el PDF en Descargas
            try {
              Directory? directory;

              if (Platform.isAndroid) {
                // En Android, guardar en Downloads
                directory = Directory('/storage/emulated/0/Download');
                if (!await directory.exists()) {
                  directory = await getExternalStorageDirectory();
                }
              } else if (Platform.isIOS) {
                // En iOS, guardar en Documents (accesible desde Archivos)
                directory = await getApplicationDocumentsDirectory();
              }

              if (directory != null) {
                final file = File('${directory.path}/$fileName');
                await file.writeAsBytes(pdfBytes);

                // Guardar la ruta para compartir después
                setState(() {
                  _savedPdfPath = file.path;
                });

                print('📄 PDF guardado en: ${file.path}');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Certificado guardado en ${Platform.isAndroid ? "Descargas" : "Documentos"}'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            } catch (e) {
              print('❌ Error al guardar PDF en móvil: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar el certificado'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } else {
          // La respuesta es JSON
          final responseData = json.decode(generateResponse.body);

          if (responseData['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(responseData['message'] ??
                      '¡Certificado generado exitosamente!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            // Si hay URL de descarga, mostrarla (opcional - backend retorna PDF directo)
            if (responseData['downloadUrl'] != null) {
              print('📥 Download URL: ${responseData['downloadUrl']}');
            }

            // Si hay datos del certificado, actualizar el estado
            if (responseData['certificate'] != null) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar certificado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Descarga el PDF en web usando blob URL
  Future<void> _downloadPdfWeb(List<int> pdfBytes, String fileName) async {
    if (kIsWeb) {
      await downloadPdfWeb(pdfBytes, fileName);
      print('✅ PDF descargado: $fileName');
    }
  }

  /// Genera el PDF desde el backend y lo guarda localmente
  Future<String?> _generateAndSavePdf() async {
    try {
      String? token = await getToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se encontró token de autenticación'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

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

      if (generateResponse.statusCode == 200 ||
          generateResponse.statusCode == 201) {
        final contentType = generateResponse.headers['content-type'] ?? '';

        if (contentType.contains('application/pdf')) {
          final pdfBytes = generateResponse.bodyBytes;
          final fileName =
              'Certificado_Funcional_${DateTime.now().millisecondsSinceEpoch}.pdf';

          Directory? directory;

          if (Platform.isAndroid) {
            // En Android, guardar en Downloads
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          } else if (Platform.isIOS) {
            // En iOS, guardar en Documents
            directory = await getApplicationDocumentsDirectory();
          } else {
            // Fallback para otras plataformas
            directory = await getTemporaryDirectory();
          }

          if (directory != null) {
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(pdfBytes);

            print('📄 PDF guardado en: ${file.path}');

            setState(() {
              _savedPdfPath = file.path;
            });

            return file.path;
          }
        }
      }

      throw Exception(
          'Error al generar certificado: ${generateResponse.statusCode}');
    } catch (e) {
      print('❌ Error al generar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el certificado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _shareCertificate() async {
    try {
      // Si no hay PDF guardado, generarlo primero
      String? pdfPath = _savedPdfPath;

      if (pdfPath == null || !File(pdfPath).existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generando certificado...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        pdfPath = await _generateAndSavePdf();
      }

      if (pdfPath != null && File(pdfPath).existsSync()) {
        // Compartir el PDF junto con el texto
        final result = await Share.shareXFiles(
          [XFile(pdfPath)],
          text:
              '¡He completado el ${widget.programName ?? "programa"} con Funcional Neuro Laboral! 🎓',
          subject: 'Mi Certificado FNL',
        );

        if (result.status == ShareResultStatus.success) {
          print('✅ Certificado compartido exitosamente');
        }
      }
    } catch (e) {
      print('❌ Error al compartir: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir el certificado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenWidth > 600;

    // Padding más inteligente basado en el tamaño de pantalla
    double padding;
    if (screenWidth > 1024) {
      padding = 32.0; // Desktop: padding fijo
    } else if (screenWidth > 600) {
      padding = screenWidth * 0.05; // Tablet: 5% del ancho
    } else {
      padding = 20.0; // Móvil: padding fijo
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : errorMessage != null
                ? _buildErrorState()
                : _buildCertificateContent(
                    context, isTablet, padding, screenHeight),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6D4BD8)),
          SizedBox(height: 20),
          Text(
            'Generando tu certificado...',
            style: TextStyle(fontSize: 16, color: Color(0xFF212121)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D4BD8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Volver al inicio',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateContent(BuildContext context, bool isTablet,
      double padding, double screenHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isMediumTablet = screenWidth > 768 && screenWidth <= 1024;
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;

    // Max width más grande para tablets
    final maxContentWidth = isDesktop
        ? 900.0
        : (isMediumTablet ? 700.0 : (isSmallTablet ? 600.0 : double.infinity));

    // En desktop, usar SingleChildScrollView con mejor altura mínima
    if (isDesktop) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - 48, // Altura mínima para centrar
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(flex: 1),
                          _buildHeader(context),
                          SizedBox(height: 48),
                          _buildActionButtons(context),
                          Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Para móvil y tablet, mantener scroll
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? padding : padding),
                  vertical: isDesktop ? 32 : (isTablet ? 28 : 20),
                ),
                child: Column(
                  children: [
                    SizedBox(height: isTablet ? 32 : 20),
                    _buildHeader(context),
                    SizedBox(height: isTablet ? 48 : 32),
                    _buildActionButtons(context),
                    SizedBox(height: isTablet ? 32 : 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isMediumTablet = screenWidth > 768 && screenWidth <= 1024;
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;
    final isMobile = screenWidth <= 600;

    // Tamaños responsivos mejorados (tablets más grandes)
    final iconSize = isDesktop
        ? 80.0
        : (isMediumTablet ? 70.0 : (isSmallTablet ? 60.0 : 48.0));
    final titleSize = isDesktop
        ? 40.0
        : (isMediumTablet ? 36.0 : (isSmallTablet ? 30.0 : 24.0));
    final subtitleSize = isDesktop
        ? 18.0
        : (isMediumTablet ? 17.0 : (isSmallTablet ? 16.0 : 14.0));
    final badgeIconSize = isDesktop
        ? 26.0
        : (isMediumTablet ? 24.0 : (isSmallTablet ? 22.0 : 20.0));
    final badgeTextSize = isDesktop
        ? 17.0
        : (isMediumTablet ? 16.0 : (isSmallTablet ? 15.0 : 13.0));
    final containerPadding = isDesktop
        ? 56.0
        : (isMediumTablet ? 48.0 : (isSmallTablet ? 36.0 : 24.0));

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isDesktop ? 24 : 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo o imagen decorativa
          Container(
            padding: EdgeInsets.all(isDesktop
                ? 20
                : (isMediumTablet ? 18 : (isSmallTablet ? 17 : 16))),
            decoration: BoxDecoration(
              color: const Color(0xFF6D4BD8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified,
              size: iconSize,
              color: const Color(0xFF6D4BD8),
            ),
          ),
          SizedBox(
              height: isDesktop
                  ? 32
                  : (isMediumTablet ? 28 : (isSmallTablet ? 24 : 20))),

          Text(
            '¡Programa Completado!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: isDesktop ? 20 : (isMediumTablet ? 16 : 12)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 50
                  : (isMediumTablet ? 30 : (isSmallTablet ? 20 : 0)),
            ),
            child: Text(
              'Has finalizado exitosamente el Programa de Bienestar Emocional',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleSize,
                color: const Color(0xFF757575),
                fontFamily: 'Inter',
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 32 : (isMediumTablet ? 26 : 20)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 24
                  : (isMediumTablet ? 22 : (isSmallTablet ? 20 : 16)),
              vertical: isDesktop ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF6D4BD8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6D4BD8).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: badgeIconSize,
                  color: const Color(0xFF6D4BD8),
                ),
                SizedBox(width: isDesktop ? 10 : 8),
                Flexible(
                  child: Text(
                    'Tu certificado está listo',
                    style: TextStyle(
                      fontSize: badgeTextSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6D4BD8),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isMediumTablet = screenWidth > 768 && screenWidth <= 1024;
    final isSmallTablet = screenWidth > 600 && screenWidth <= 768;
    final isMobile = screenWidth <= 600;

    // Tamaños responsivos mejorados para tablets
    final buttonTextSize = isDesktop
        ? 19.0
        : (isMediumTablet ? 18.0 : (isSmallTablet ? 17.0 : 15.0));
    final buttonIconSize = isDesktop
        ? 26.0
        : (isMediumTablet ? 24.0 : (isSmallTablet ? 22.0 : 20.0));
    final buttonPadding = isDesktop
        ? 24.0
        : (isMediumTablet ? 22.0 : (isSmallTablet ? 18.0 : 14.0));
    final buttonSpacing = isDesktop
        ? 24.0
        : (isMediumTablet ? 20.0 : (isSmallTablet ? 18.0 : 16.0));
    final borderRadius = isDesktop
        ? 16.0
        : (isMediumTablet ? 14.0 : (isSmallTablet ? 13.0 : 12.0));
    final textButtonSize = isDesktop
        ? 17.0
        : (isMediumTablet ? 16.0 : (isSmallTablet ? 15.0 : 14.0));

    return Column(
      children: [
        // Botón de generar certificado
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloadCertificate,
            icon:
                Icon(Icons.download, color: Colors.white, size: buttonIconSize),
            label: Text(
              'Generar Certificado',
              style: TextStyle(
                fontSize: buttonTextSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D4BD8),
              padding: EdgeInsets.symmetric(vertical: buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: isDesktop ? 2 : 4,
              shadowColor: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        SizedBox(height: buttonSpacing),

        // Botón de compartir
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareCertificate,
            icon: Icon(Icons.share,
                color: const Color(0xFF6D4BD8), size: buttonIconSize),
            label: Text(
              'Compartir',
              style: TextStyle(
                fontSize: buttonTextSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6D4BD8),
                fontFamily: 'Inter',
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              side: const BorderSide(color: Color(0xFF6D4BD8), width: 2),
            ),
          ),
        ),
        SizedBox(height: buttonSpacing),

        // Botón de volver al inicio
        TextButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 16 : 12,
              horizontal: isDesktop ? 24 : 16,
            ),
          ),
          child: Text(
            'Volver al inicio',
            style: TextStyle(
              fontSize: textButtonSize,
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
