import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/google_play_verification_service.dart';
import '../services/subscription_service.dart';
import 'dart:async';

class SubscriptionScreen extends StatefulWidget {
  final bool showBackButton;

  const SubscriptionScreen({
    Key? key,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _available = true;

  static const String _productId = 'fnl_monthly_vip';

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _subscription.cancel();
      }, onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
      _initStoreInfo();
    } else {
      // En web, marca como no disponible
      setState(() {
        _available = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initStoreInfo() async {
    if (kIsWeb) return;

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      setState(() {
        _available = available;
        _products = [];
        _isLoading = false;
      });
      return;
    }

    const Set<String> kIds = <String>{_productId};
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Productos no encontrados: ${response.notFoundIDs}');
    }

    setState(() {
      _products = response.productDetails;
      _isLoading = false;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      print("🔥🔥🔥 PURCHASE DETECTED 🔥🔥🔥");
      print("Product ID: ${purchaseDetails.productID}");
      print("Purchase ID: ${purchaseDetails.purchaseID}");
      print(
          "Server Verification Data: ${purchaseDetails.verificationData.serverVerificationData}");
      print("Source: ${purchaseDetails.verificationData.source}");
      print("Status: ${purchaseDetails.status}");

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError(purchaseDetails.error!);
        // Completar la compra incluso si hay error para limpiar el estado
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Compra exitosa - verificar con backend
        await _verifyPurchaseWithBackend(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // Compra cancelada
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Compra cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Completar la compra cancelada para limpiar el estado
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }

  void _showPendingUI() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Procesando compra...')),
    );
  }

  void _handleError(IAPError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error en la compra: ${error.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Verifica la compra con el backend usando GooglePlayVerificationService
  /// Según la documentación, este método debe:
  /// 1. Obtener purchaseToken y productId de la compra
  /// 2. Verificar con el backend usando el servicio
  /// 3. Si es exitoso, completar la compra en Google Play
  /// 4. Verificar acceso inmediatamente
  Future<void> _verifyPurchaseWithBackend(
      PurchaseDetails purchaseDetails) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener purchaseToken y productId
      // Para Android, el purchaseToken puede venir de:
      // - purchaseID (recomendado según documentación)
      // - verificationData.serverVerificationData (alternativa para Android)
      String purchaseToken = purchaseDetails.purchaseID ?? '';

      // Si purchaseID está vacío, intentar con serverVerificationData (para Android)
      if (purchaseToken.isEmpty) {
        purchaseToken = purchaseDetails.verificationData.serverVerificationData;
      }

      final String productId = purchaseDetails.productID;

      // Validar que tenemos un purchaseToken válido
      if (purchaseToken.isEmpty) {
        throw Exception('No se recibió el token de compra de Google Play');
      }

      // Verificar con el backend usando el servicio
      final result = await GooglePlayVerificationService.verifyPurchase(
        purchaseToken: purchaseToken,
        productId: productId,
      );

      if (result['success'] == true) {
        // Suscripción activada exitosamente en el backend
        // Ahora completar la compra en Google Play
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        setState(() {
          _isLoading = false;
        });

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ??
                  '¡Suscripción PRO activada correctamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Verificar acceso inmediatamente para confirmar
          final hasAccess = await SubscriptionService.hasAccessToPrograms();
          if (hasAccess) {
            // Navegar de vuelta indicando éxito
            Navigator.of(context).pop(true);
          } else {
            // Si por alguna razón no tiene acceso aún, esperar un momento y verificar de nuevo
            await Future.delayed(Duration(seconds: 1));
            final hasAccessRetry =
                await SubscriptionService.hasAccessToPrograms();
            if (hasAccessRetry) {
              Navigator.of(context).pop(true);
            } else {
              // Mostrar mensaje informativo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Suscripción activada. Por favor, espera unos segundos...'),
                  backgroundColor: Colors.blue,
                ),
              );
              Navigator.of(context).pop(true);
            }
          }
        }
      } else {
        throw Exception(result['message'] ?? 'Error al activar suscripción');
      }
    } catch (e) {
      print('Error al verificar compra con backend: $e');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar compra: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }

      // No completar la compra si falla la verificación
      // Esto permite que el usuario pueda reintentar
    }
  }

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    if (productDetails.id.contains('monthly') ||
        productDetails.id.contains('yearly')) {
      // Es una suscripción
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // Es una compra única
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    // Breakpoints responsivos
    final isSmallPhone = size.height < 700;
    final isTablet = shortestSide >= 600;
    final isDesktop = size.width >= 1200;
    final isLandscape = size.width > size.height;

    // Padding horizontal adaptativo
    final horizontalPadding = isDesktop
        ? size.width * 0.15
        : isTablet
            ? size.width * 0.1
            : size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFF5027D0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Para landscape o desktop, usar layout horizontal
            if (isLandscape && !isSmallPhone || isDesktop) {
              return _buildLandscapeLayout(
                  size, constraints, isDesktop, isTablet);
            }
            // Para portrait, usar layout vertical con scroll
            return _buildPortraitLayout(
                size, constraints, horizontalPadding, isSmallPhone, isTablet);
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(Size size, BoxConstraints constraints,
      double horizontalPadding, bool isSmallPhone, bool isTablet) {
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(height: isSmallPhone ? 8 : 16),
              _buildHeader(size, isTablet: isTablet),
              SizedBox(height: isSmallPhone ? 12 : 20),
              _buildPriceCard(size, isTablet: isTablet),
              SizedBox(height: isSmallPhone ? 12 : 20),
              _buildFeaturesList(size, isTablet: isTablet),
              SizedBox(height: isSmallPhone ? 16 : 24),
              _buildSubscribeButton(size, isDesktop: false, isTablet: isTablet),
              SizedBox(height: isSmallPhone ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
      Size size, BoxConstraints constraints, bool isDesktop, bool isTablet) {
    final maxContentWidth = isDesktop ? 1200.0 : 900.0;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxContentWidth,
            minHeight: constraints.maxHeight,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lado izquierdo: Header y precio
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(size, isTablet: isTablet, isLandscape: true),
                      SizedBox(height: 20),
                      _buildPriceCard(size, isTablet: isTablet),
                      SizedBox(height: 20),
                      _buildSubscribeButton(size,
                          isDesktop: isDesktop, isTablet: isTablet),
                    ],
                  ),
                ),
                SizedBox(width: 32),
                // Lado derecho: Features
                Expanded(
                  flex: 5,
                  child: _buildFeaturesList(size,
                      isTablet: isTablet, isLandscape: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size size,
      {bool isTablet = false, bool isLandscape = false}) {
    // Tamaños adaptativos basados en el dispositivo
    final baseIconSize = isTablet ? 50.0 : 40.0;
    final baseTitleSize = isTablet ? 52.0 : 42.0;
    final baseSubtitleSize = isTablet ? 22.0 : 16.0;

    final iconSize = isLandscape ? baseIconSize * 0.9 : baseIconSize;
    final titleSize = isLandscape ? baseTitleSize * 0.9 : baseTitleSize;
    final subtitleSize =
        isLandscape ? baseSubtitleSize * 0.9 : baseSubtitleSize;
    final iconPadding = isTablet ? 20.0 : 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(
            Icons.workspace_premium,
            size: iconSize,
            color: Color(0xFF5027D0),
          ),
        ),
        SizedBox(height: isLandscape ? 10 : 14),
        Text(
          'Funcy Pro',
          style: GoogleFonts.inter(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Desbloquea tu mejor versión con Funcy',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(Size size,
      {bool isTablet = false, bool isLandscape = false}) {
    final features = [
      {'icon': Icons.psychology, 'text': 'Acceso ilimitado al chat de IA'},
      {'icon': Icons.insights, 'text': 'Análisis detallados de estrés'},
      {'icon': Icons.trending_up, 'text': 'Seguimiento avanzado de progreso'},
      {'icon': Icons.workspace_premium, 'text': 'Contenido premium exclusivo'},
      {'icon': Icons.priority_high, 'text': 'Soporte prioritario'},
    ];

    // Tamaños adaptativos
    final fontSize = isTablet ? 16.0 : 14.0;
    final iconSize = isTablet ? 24.0 : 20.0;
    final checkSize = isTablet ? 22.0 : 18.0;
    final containerPadding = isTablet ? 24.0 : 16.0;
    final itemSpacing = isTablet ? 14.0 : 10.0;
    final iconContainerPadding = isTablet ? 10.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      constraints: BoxConstraints(
        maxWidth: isLandscape ? 500 : 450,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : itemSpacing,
              bottom: index == features.length - 1 ? 0 : itemSpacing,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(iconContainerPadding),
                  decoration: BoxDecoration(
                    color: Color(0xFF5027D0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Color(0xFF5027D0),
                    size: iconSize,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature['text'] as String,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF5027D0),
                  size: checkSize,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceCard(Size size, {bool isTablet = false}) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (!_available || _products.isEmpty) {
      return Center(
        child: Text(
          'Servicio no disponible',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 18.0 : 16.0,
            color: Colors.white,
          ),
        ),
      );
    }

    final product = _products.first;
    final priceSize = isTablet ? 48.0 : 38.0;
    final labelSize = isTablet ? 18.0 : 15.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            product.price,
            style: GoogleFonts.inter(
              fontSize: priceSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'por mes',
          style: GoogleFonts.inter(
            fontSize: labelSize,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(Size size,
      {bool isDesktop = false, bool isTablet = false}) {
    final buttonTextSize = isTablet ? 18.0 : 16.0;
    final buttonPadding = isTablet ? 18.0 : 14.0;
    final maxWidth = isDesktop ? 400.0 : (isTablet ? 350.0 : 320.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading || _products.isEmpty
                ? null
                : () => _buyProduct(_products.first),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF5027D0),
              disabledBackgroundColor: Colors.white.withOpacity(0.6),
              disabledForegroundColor: Color(0xFF5027D0).withOpacity(0.5),
              padding: EdgeInsets.symmetric(vertical: buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF5027D0)),
                    ),
                  )
                : Text(
                    'Suscríbete a Funcy PRO',
                    style: GoogleFonts.inter(
                      fontSize: buttonTextSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
