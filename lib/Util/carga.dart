import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';

class LoadingScreen extends StatefulWidget {
  final Function onLoadingComplete;

  LoadingScreen({required this.onLoadingComplete});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double progress = 0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 30), () {
        setState(() {
          progress = i / 100;
        });
      });
    }
    widget.onLoadingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Container(
              width: 250, // Ajusta este valor para hacer el indicador más pequeño
              height: 250, // Ajusta este valor para hacer el indicador más pequeño
              child: AspectRatio(
                aspectRatio: 1, // Mantiene una proporción 1:1
                child: LiquidCircularProgressIndicator(
                  value: progress,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF5027D0)),
                  backgroundColor: Colors.white,
                  borderColor: Color(0xFF5027D0),
                  borderWidth: 5.0,
                  direction: Axis.vertical,
                  center: Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,color: Colors.black54
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Personalizando tu experiencia...',
              style: GoogleFonts.robotoCondensed(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
