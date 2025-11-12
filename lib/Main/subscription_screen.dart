import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
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
      final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
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
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

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
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _deliverProduct(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
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

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      // Enviar comprobante de compra al backend
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/subscriptions/subscribe'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'plan_type': 'PRO',
          'purchase_token': purchaseDetails.verificationData.serverVerificationData,
          'product_id': purchaseDetails.productID,
          'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Suscripción activada exitosamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Retornar true para que profile.dart recargue los datos
        Navigator.of(context).pop(true);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Error al activar suscripción');
      }
    } catch (e) {
      print('Error al procesar suscripción: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al activar suscripción: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    if (productDetails.id.contains('monthly') || productDetails.id.contains('yearly')) {
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
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;
    final horizontalPadding = isDesktop ? 200.0 : isTablet ? 80.0 : 20.0;

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : double.infinity,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    flex: 3,
                    child: _buildHeader(size),
                  ),
                  Flexible(
                    flex: 2,
                    child: _buildPriceCard(size),
                  ),
                  Flexible(
                    flex: 5,
                    child: _buildFeaturesList(size),
                  ),
                  Flexible(
                    flex: 2,
                    child: _buildSubscribeButton(size, isDesktop),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    final iconSize = size.height * 0.06;
    final titleSize = size.height * 0.035;
    final subtitleSize = size.height * 0.018;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(size.height * 0.02),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(
            Icons.workspace_premium,
            size: iconSize.clamp(30.0, 60.0),
            color: Color(0xFF5027D0),
          ),
        ),
        SizedBox(height: size.height * 0.015),
        Text(
          'Funcy Pro',
          style: GoogleFonts.inter(
            fontSize: titleSize.clamp(22.0, 36.0),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: size.height * 0.008),
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: Text(
              'Desbloquea tu mejor versión con Funcy Pro',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: subtitleSize.clamp(12.0, 16.0),
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(Size size) {
    final features = [
      {'icon': Icons.psychology, 'text': 'Acceso ilimitado al chat de IA'},
      {'icon': Icons.insights, 'text': 'Análisis detallados de estrés'},
      {'icon': Icons.trending_up, 'text': 'Seguimiento avanzado de progreso'},
      {'icon': Icons.workspace_premium, 'text': 'Contenido premium exclusivo'},
      {'icon': Icons.priority_high, 'text': 'Soporte prioritario'},
    ];

    final fontSize = (size.height * 0.018).clamp(12.0, 16.0);
    final iconSize = (size.height * 0.022).clamp(16.0, 20.0);
    final padding = (size.height * 0.02).clamp(12.0, 20.0);

    return Container(
      padding: EdgeInsets.all(padding),
      margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: features.map((feature) {
          return Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: size.height * 0.008),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(size.height * 0.01),
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
                  SizedBox(width: size.width * 0.035),
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
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF5027D0),
                    size: iconSize,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceCard(Size size) {
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
            fontSize: (size.height * 0.02).clamp(14.0, 18.0),
            color: Colors.white,
          ),
        ),
      );
    }

    final product = _products.first;
    final priceSize = (size.height * 0.06).clamp(32.0, 56.0);
    final labelSize = (size.height * 0.02).clamp(13.0, 18.0);

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
        SizedBox(height: size.height * 0.005),
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

  Widget _buildSubscribeButton(Size size, bool isDesktop) {
    final buttonTextSize = (size.height * 0.022).clamp(14.0, 18.0);
    final buttonPadding = (size.height * 0.02).clamp(12.0, 18.0);

    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 400 : size.width * 0.85,
        ),
        child: ElevatedButton(
          onPressed: _isLoading || _products.isEmpty ? null : () => _buyProduct(_products.first),
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
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5027D0)),
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
    );
  }
}