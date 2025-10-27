import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _available = true;

  static const String _productId = 'tu_producto_id';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Suscripción activada exitosamente!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;
    final horizontalPadding = isDesktop ? 200.0 : isTablet ? 80.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF5027D0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 800 : double.infinity,
                ),
                child: Column(
                  children: [
                    _buildHeader(size),
                    SizedBox(height: size.height * 0.04),
                    _buildPriceCard(size),
                    SizedBox(height: size.height * 0.04),
                    _buildFeaturesList(size),
                    SizedBox(height: size.height * 0.04),
                    _buildSubscribeButton(size, isDesktop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(size.width < 600 ? 20 : 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(
            Icons.workspace_premium,
            size: size.width < 600 ? 50 : 70,
            color: Color(0xFF5027D0),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Funcy Pro',
          style: GoogleFonts.inter(
            fontSize: size.width < 400 ? 28 : size.width < 600 ? 32 : 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Desbloquea tu mejor versión con Funcy Pro',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: size.width < 600 ? 14 : 16,
            color: Colors.white.withOpacity(0.9),
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

    return Container(
      padding: EdgeInsets.all(size.width < 600 ? 20 : 24),
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
        children: features.map((feature) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF5027D0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Color(0xFF5027D0),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    feature['text'] as String,
                    style: GoogleFonts.inter(
                      fontSize: size.width < 600 ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                Icon(Icons.check_circle, color: Color(0xFF5027D0), size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceCard(Size size) {
    /*if (_isLoading) {
      return CircularProgressIndicator(color: Colors.white);
    }

    if (!_available || _products.isEmpty) {
      return Text(
        'Servicio no disponible',
        style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
      );
    }

    final product = _products.first;*/

    return Column(
      children: [
        Text(
          'S/. 19.90',
          style: GoogleFonts.inter(
            fontSize: size.width < 400 ? 48 : 56,
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
        SizedBox(height: 4),
        Text(
          'por mes',
          style: GoogleFonts.inter(
            fontSize: size.width < 600 ? 16 : 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(Size size, bool isDesktop) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 400 : size.width * 0.8,
      ),
      child: ElevatedButton(
        /*onPressed: _isLoading || _products.isEmpty ? null : () => _buyProduct(_products.first),*/
        onPressed: () {
          // Por ahora solo muestra un mensaje
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Funcionalidad en desarrollo')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF5027D0),
          disabledBackgroundColor: Colors.white.withOpacity(0.6),
          disabledForegroundColor: Color(0xFF5027D0).withOpacity(0.5),
          padding: EdgeInsets.symmetric(vertical: size.width < 400 ? 14 : 18),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5027D0)),
          ),
        )
            : Text(
          'Obtener acceso Pro',
          style: GoogleFonts.inter(
            fontSize: size.width < 400 ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

}
