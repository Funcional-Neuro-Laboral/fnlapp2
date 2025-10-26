import 'package:flutter/material.dart';
import '../models/test_notice.dart';

class TestNoticeDialog extends StatelessWidget {
  final TestNotice notice;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const TestNoticeDialog({
    Key? key,
    required this.notice,
    required this.onContinue,
    this.onBack,
  }) : super(key: key);

  Widget _buildDescription(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.060;
    final lineHeight = 1.4;

    switch (notice.afterQuestion) {
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No estás solo.',
              style: TextStyle(
                color: Color(0xFF5027D0),
                fontSize: fontSize,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                height: lineHeight,
              ),
              textAlign: TextAlign.left,
            ),
            Text(
              'Muchos profesionales sienten lo mismo cuando las cosas se salen de control.',
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                height: lineHeight,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        );

      case 12:
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Según la neurociencia, puedes entrenar tu mente para ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: lineHeight,
                ),
              ),
              TextSpan(
                text: 'reducir el estrés.\n',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: lineHeight,
                ),
              ),
              TextSpan(
                text: 'Más del 70%',
                style: TextStyle(
                  color: Color(0xFF5027D0),
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: lineHeight,
                ),
              ),
              TextSpan(
                text: ' ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: lineHeight,
                ),
              ),
              TextSpan(
                text: 'del estrés laboral',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: lineHeight,
                ),
              ),
              TextSpan(
                text: ' proviene de factores fuera de tu control.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: lineHeight,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.left,
        );

      case 15:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Estás haciendo un gran trabajo.',
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                height: lineHeight,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: screenWidth * 0.04),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Lo que estás logrando ahora te acerca a un gran salto en tu bienestar.\n',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSize,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: lineHeight,
                    ),
                  ),
                  TextSpan(
                    text: 'Sigue adelante.',
                    style: TextStyle(
                      color: Color(0xFF5027D0),
                      fontSize: fontSize,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.left,
            ),
          ],
        );

      case 18:
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'El cambio empieza con conocerte mejor.\n',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: lineHeight,
                ),
              ),
              TextSpan(
                text: 'Estás a pocos pasos de descubrir un plan hecho para ti.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: lineHeight,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.left,
        );

      default:
        return Text(
          notice.description,
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            height: lineHeight,
          ),
        );
    }
  }

  Widget _buildNetworkImage(BuildContext context, String url, double maxHeight) {
    return Flexible(
      child: Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.error_outline,
            size: MediaQuery.of(context).size.width * 0.12,
            color: Colors.grey,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;
    final titleFontSize = screenWidth * 0.065;
    final buttonFontSize = screenWidth * 0.047;

    return Container(
      color: const Color(0xFFF6F6F6),
      child: SafeArea(
        child: Column(
          children: [
            // Header con botón de retroceso
            if (onBack != null)
              Padding(
                padding: EdgeInsets.only(
                  left: padding,
                  top: screenHeight * 0.05,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF4320AD),
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (notice.afterQuestion == 18) ...[
                          if (notice.title != null)
                            Text(
                              notice.title!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF4320AD),
                                fontSize: titleFontSize,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          SizedBox(height: screenHeight * 0.015),
                          if (notice.imagePath != null && notice.imagePath!.isNotEmpty)
                            _buildNetworkImage(context, notice.imagePath!, constraints.maxHeight * 0.30),
                          SizedBox(height: screenHeight * 0.025),
                          _buildDescription(context),
                        ]
                        else if (notice.afterQuestion == 15) ...[
                          if (notice.imagePath != null && notice.imagePath!.isNotEmpty)
                            _buildNetworkImage(context, notice.imagePath!, constraints.maxHeight * 0.45),
                          SizedBox(height: screenHeight * 0.025),
                          _buildDescription(context),
                        ]
                        else if (notice.afterQuestion == 12) ...[
                            _buildDescription(context),
                            SizedBox(height: screenHeight * 0.015),
                            if (notice.imagePath != null && notice.imagePath!.isNotEmpty)
                              _buildNetworkImage(context, notice.imagePath!, constraints.maxHeight * 0.30),
                            SizedBox(height: screenHeight * 0.015),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'En ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.060,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Funcy',
                                    style: TextStyle(
                                      color: Color(0xFF5027D0),
                                      fontSize: screenWidth * 0.060,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ', te acompañamos paso a paso para lograrlo.',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.060,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ]
                          else ...[
                              if (notice.title != null) ...[
                                Text(
                                  notice.title!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF4320AD),
                                    fontSize: titleFontSize,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                              ],
                              _buildDescription(context),
                              SizedBox(height: screenHeight * 0.025),
                              if (notice.imagePath != null && notice.imagePath!.isNotEmpty)
                                _buildNetworkImage(context, notice.imagePath!, constraints.maxHeight * 0.45),
                            ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Botón continuar
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
              child: GestureDetector(
                onTap: onContinue,
                child: Container(
                  width: screenWidth * 0.88,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.018,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF6D4BD8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      notice.buttonText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: buttonFontSize,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
