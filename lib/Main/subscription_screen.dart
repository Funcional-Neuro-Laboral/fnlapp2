import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/google_play_verification_service.dart';
import '../services/subscription_service.dart';
import 'dart:async';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
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

  static TextStyle body({double size = 16, Color color = _FnlColors.body}) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle feature(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: _FnlColors.blue,
        height: 1.3,
      );

  static TextStyle button({Color color = _FnlColors.white}) =>
      GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

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
  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _available = true;

  String? _storeDebugInfo;

  bool _restoreTried = false;

  static const String _productId = 'fnl_monthly_vip';

  void _log(String message) => debugPrint('[IAP] $message');

  String _mask(String value) {
    if (value.isEmpty) return '(vacío)';
    if (value.length <= 12) return '***(len ${value.length})';
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)} (len ${value.length})';
  }

  @override
  void initState() {
    super.initState();
    _log('initState | kIsWeb=$kIsWeb | productId=$_productId');

    if (!kIsWeb) {
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _log('purchaseStream emitió ${purchaseDetailsList.length} evento(s)');
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _log('purchaseStream cerrado (onDone)');
        _subscription?.cancel();
      }, onError: (error) {
        _log('purchaseStream ERROR: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
      _initStoreInfo();
    } else {
      // En web, marca como no disponible
      _storeDebugInfo = 'Web: las compras no están disponibles';
      setState(() {
        _available = false;
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const NetworkImage(_funcyUrl), context);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initStoreInfo() async {
    if (kIsWeb) return;

    try {
      _log('========== GOOGLE PLAY BILLING ==========');
      final bool available = await _inAppPurchase.isAvailable();
      _log('isAvailable = $available');

      if (!mounted) return;

      if (!available) {
        _log('❌ Billing NO disponible (Play Store ausente/desactualizada, '
            'emulador sin Google Play, o app no instalada desde Play)');
        setState(() {
          _available = false;
          _products = [];
          _storeDebugInfo = 'isAvailable() = false';
          _isLoading = false;
        });
        return;
      }

      const Set<String> kIds = <String>{_productId};
      _log('Consultando producto: $_productId');

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(kIds);

      _log('productDetails encontrados: ${response.productDetails.length}');
      for (final p in response.productDetails) {
        _log('  → id=${p.id} | title=${p.title} | price=${p.price} '
            '| rawPrice=${p.rawPrice} | currency=${p.currencyCode}');
      }
      _log('notFoundIDs: ${response.notFoundIDs}');
      if (response.error != null) {
        _log('❌ response.error: code=${response.error!.code} '
            'message=${response.error!.message} '
            'details=${response.error!.details}');
      }
      _log('==========================================');

      if (!mounted) return;

      if (response.notFoundIDs.isNotEmpty) {
        _log('❌ Productos no encontrados: ${response.notFoundIDs}');
      }

      setState(() {
        _products = response.productDetails;
        _storeDebugInfo = response.productDetails.isEmpty
            ? 'notFound=${response.notFoundIDs} | error=${response.error?.message}'
            : null;
        _isLoading = false;
      });
    } catch (e, st) {
      // Sin este catch, un fallo aquí dejaba el spinner girando para siempre
      _log('❌ EXCEPCIÓN en _initStoreInfo: $e');
      _log('$st');
      if (!mounted) return;
      setState(() {
        _products = [];
        _storeDebugInfo = 'Excepción: $e';
        _isLoading = false;
      });
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      try {
        _log('----- PURCHASE EVENT -----');
        _log('productID=${purchaseDetails.productID}');
        _log('status=${purchaseDetails.status}');
        _log('purchaseID (orderId en Android)=${purchaseDetails.purchaseID}');
        _log('source=${purchaseDetails.verificationData.source}');
        _log('serverVerificationData (purchaseToken)='
            '${_mask(purchaseDetails.verificationData.serverVerificationData)}');
        _log('pendingCompletePurchase=${purchaseDetails.pendingCompletePurchase}');

        if (purchaseDetails.status == PurchaseStatus.pending) {
          _showPendingUI();
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
          // Completar la compra incluso si hay error para limpiar el estado
          if (purchaseDetails.pendingCompletePurchase) {
            _log('completePurchase (por error)');
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _verifyPurchaseWithBackend(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _log('Compra cancelada por el usuario');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Compra cancelada'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      } catch (e, st) {
        _log('❌ EXCEPCIÓN procesando evento de compra: $e');
        _log('$st');
      }
    });
  }

  void _showPendingUI() {
    _log('Compra en estado PENDING');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Procesando compra...')),
    );
  }

  void _handleError(IAPError error) {
    _log('❌ IAPError | source=${error.source} | code=${error.code} '
        '| message=${error.message} | details=${error.details}');

    final String raw = '${error.message} ${error.details}'.toLowerCase();

    // El usuario cerró el diálogo de Google Play
    if (raw.contains('usercanceled')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compra cancelada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (raw.contains('alreadyowned') && !_restoreTried) {
      _restoreTried = true;
      _log('ITEM_ALREADY_OWNED → restorePurchases()');
      _inAppPurchase.restorePurchases().catchError((e) {
        _log('❌ restorePurchases falló: $e');
      });
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error en la compra: ${error.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Verifica la compra con el backend usando GooglePlayVerificationService
  /// Este método:
  /// 1. Obtiene purchaseToken y productId de la compra
  /// 2. Verifica con el backend usando el servicio
  /// 3. Si es exitoso, completa la compra en Google Play
  /// 4. Verifica el acceso inmediatamente
  Future<void> _verifyPurchaseWithBackend(
      PurchaseDetails purchaseDetails) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // IMPORTANTE (Android): `purchaseID` es el ORDER ID (GPA.xxxx-xxxx),
      String purchaseToken =
          purchaseDetails.verificationData.serverVerificationData;
      String tokenSource = 'serverVerificationData';

      // Respaldo: si viniera vacío, se usa purchaseID
      if (purchaseToken.isEmpty) {
        purchaseToken = purchaseDetails.purchaseID ?? '';
        tokenSource = 'purchaseID';
      }

      final String productId = purchaseDetails.productID;

      _log('VERIFICANDO con backend | productId=$productId '
          '| token=${_mask(purchaseToken)} | origen=$tokenSource '
          '| orderId=${purchaseDetails.purchaseID}');

      // Validar que tenemos un purchaseToken válido
      if (purchaseToken.isEmpty) {
        throw Exception('No se recibió el token de compra de Google Play');
      }

      // Verificar con el backend usando el servicio
      final result = await GooglePlayVerificationService.verifyPurchase(
        purchaseToken: purchaseToken,
        productId: productId,
      );

      _log('Respuesta backend | success=${result['success']} '
          '| message=${result['message']}');

      if (result['success'] == true) {
        // Suscripción activada exitosamente en el backend
        // Ahora completar la compra en Google Play
        if (purchaseDetails.pendingCompletePurchase) {
          _log('completePurchase (acknowledge en Google Play)');
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Mostrar mensaje de éxito
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
        _log('hasAccessToPrograms (1er intento) = $hasAccess');
        if (!mounted) return;
        if (hasAccess) {
          // Navegar de vuelta indicando éxito
          Navigator.of(context).pop(true);
        } else {
          // Si por alguna razón no tiene acceso aún, esperar y verificar de nuevo
          await Future.delayed(Duration(seconds: 1));
          final hasAccessRetry =
              await SubscriptionService.hasAccessToPrograms();
          _log('hasAccessToPrograms (reintento) = $hasAccessRetry');
          if (!mounted) return;
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
      } else {
        throw Exception(result['message'] ?? 'Error al activar suscripción');
      }
    } catch (e, st) {
      _log('❌ Error al verificar compra con backend: $e');
      _log('$st');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar compra: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );

      // No completar la compra si falla la verificación:
      // esto permite que el usuario pueda reintentar
    }
  }

// ignore: unused_element
  Future<void> _simulateSuccessfulPurchase() async {
    _log('🧪 SIMULACIÓN: compra exitosa');

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  Future<void> _buyProduct(ProductDetails productDetails) async {
    _log('Botón Suscribirme | id=${productDetails.id} '
        '| price=${productDetails.price}');

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    try {
      final bool launched =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      _log('buyNonConsumable → launched=$launched');

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo iniciar la compra. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      _log('❌ PlatformException al comprar | code=${e.code} '
          '| message=${e.message} | details=${e.details}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar la compra: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, st) {
      _log('❌ Excepción al comprar: $e');
      _log('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar la compra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static const List<Map<String, dynamic>> _features = [
    {'icon': Icons.psychology_rounded, 'text': 'Acceso ilimitado al chat de IA'},
    {'icon': Icons.insights_rounded, 'text': 'Análisis detallados de estrés'},
    {
      'icon': Icons.trending_up_rounded,
      'text': 'Seguimiento avanzado de progreso'
    },
    {
      'icon': Icons.workspace_premium_rounded,
      'text': 'Contenido premium exclusivo'
    },
    {'icon': Icons.priority_high_rounded, 'text': 'Soporte prioritario'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: Stack(
        children: [
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 840;
                final isTablet = constraints.maxWidth > 600;
                final isSmallHeight = constraints.maxHeight < 700;

                if (isWide) {
                  return _buildWideLayout(constraints);
                }
                return _buildSingleColumn(
                    constraints, isTablet, isSmallHeight);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Botón de retroceso circular (solo si showBackButton)
  Widget _buildBackButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: widget.showBackButton
          ? Material(
              color: _FnlColors.white,
              shape: const CircleBorder(
                side: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: _FnlColors.violet,
                ),
              ),
            )
          : null,
    );
  }

  // Móvil y tablet vertical: contenido con scroll + barra inferior fija
  Widget _buildSingleColumn(
      BoxConstraints constraints, bool isTablet, bool isSmallHeight) {
    final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
    final maxContentWidth = isTablet ? 560.0 : double.infinity;
    final mascotSize = isTablet
        ? 200.0
        : isSmallHeight
            ? 110.0
            : 150.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, _FnlSpace.sm, hPad, _FnlSpace.xs),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildBackButton(),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    hPad, _FnlSpace.xs, hPad, _FnlSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(mascotSize, isTablet),
                    const SizedBox(height: _FnlSpace.md),
                    _buildFeaturesCard(isTablet),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, _FnlSpace.xs, hPad, _FnlSpace.md),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPriceCard(isTablet),
                  const SizedBox(height: 12),
                  _buildSubscribeButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Tablet horizontal / escritorio: dos columnas
  Widget _buildWideLayout(BoxConstraints constraints) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              _FnlSpace.lg, _FnlSpace.sm, _FnlSpace.lg, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildBackButton(),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: _FnlSpace.lg, vertical: _FnlSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(180, true),
                          const SizedBox(height: _FnlSpace.md),
                          _buildPriceCard(true),
                          const SizedBox(height: 12),
                          _buildSubscribeButton(),
                        ],
                      ),
                    ),
                    const SizedBox(width: _FnlSpace.lg),
                    Expanded(
                      flex: 5,
                      child: _buildFeaturesCard(true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Funcy con halo + título + subtítulo
  Widget _buildHeader(double mascotSize, bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: mascotSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: mascotSize * 0.8,
                height: mascotSize * 0.8,
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
                _funcyUrl,
                height: mascotSize,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: mascotSize,
                    width: mascotSize,
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
                errorBuilder: (_, __, ___) =>
                    SizedBox(height: mascotSize, width: mascotSize),
              ),
            ],
          ),
        ),
        const SizedBox(height: _FnlSpace.sm),
        // Píldora + título
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _FnlColors.lavender,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 18, color: _FnlColors.violet),
              const SizedBox(width: 6),
              Text(
                'Suscripción mensual',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _FnlColors.violet,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Funcy ', style: _FnlText.h1(isTablet ? 40 : 34)),
            TextSpan(
              text: 'Pro',
              style: _FnlText.h1(isTablet ? 40 : 34)
                  .copyWith(color: _FnlColors.violet),
            ),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Desbloquea tu mejor versión con Funcy',
          textAlign: TextAlign.center,
          style: _FnlText.body(size: isTablet ? 18 : 16),
        ),
      ],
    );
  }

  // Beneficios: tarjeta "chunky" con checks
  Widget _buildFeaturesCard(bool isTablet) {
    final fontSize = isTablet ? 16.0 : 15.0;

    return Container(
      padding: const EdgeInsets.all(_FnlSpace.sm),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _features.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _FnlColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _features[i]['icon'] as IconData,
                    color: _FnlColors.violet,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _features[i]['text'] as String,
                    style: _FnlText.feature(fontSize),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: _FnlColors.violet,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: _FnlColors.white),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Precio: tarjeta lavanda con el monto destacado
  Widget _buildPriceCard(bool isTablet) {
    Widget content;

    if (_isLoading) {
      content = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: _FnlColors.violet,
        ),
      );
    } else if (!_available || _products.isEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Servicio no disponible',
            textAlign: TextAlign.center,
            style: _FnlText.body(size: isTablet ? 18 : 16),
          ),
          // Solo en modo debug: muestra el motivo para diagnosticar
          if (kDebugMode && _storeDebugInfo != null) ...[
            const SizedBox(height: 6),
            Text(
              _storeDebugInfo!,
              textAlign: TextAlign.center,
              style: _FnlText.body(size: 12),
            ),
          ],
        ],
      );
    } else {
      final product = _products.first;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              product.price,
              style: GoogleFonts.manrope(
                fontSize: isTablet ? 44 : 36,
                fontWeight: FontWeight.w800,
                color: _FnlColors.violet,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'por mes',
            style: GoogleFonts.manrope(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: _FnlColors.body,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(
          horizontal: _FnlSpace.md, vertical: _FnlSpace.sm),
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
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
      child: Center(child: content),
    );
  }

  Widget _buildSubscribeButton() {
    return Column(
      children: [
        _PrimaryButton(
          label: 'Suscríbete a Funcy PRO',
          icon: Icons.arrow_forward_rounded,
          loading: _isLoading,
          enabled: !_isLoading && _products.isNotEmpty,
          onTap: () => _buyProduct(_products.first),
        ),

        // Botón de prueba: descomentar SOLO para desarrollo local.
        // if (kDebugMode)
        //   TextButton(
        //     onPressed: _simulateSuccessfulPurchase,
        //     child: const Text(
        //       'TEST',
        //       style: TextStyle(fontSize: 11),
        //     ),
        //   ),
      ],
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

/// Botón primario FNL: 56 px, radio 18, violeta sólido.
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
          onTap: enabled ? onTap : null,
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