import 'package:flutter/material.dart';

class AppStyles {
  static const Map<String, Color> colors = {
    'morado': Color(0xFF5027D0),
    'rosa': Color(0xFFF2545B),
    'celesteTransparent': Color.fromRGBO(68, 222, 232, 0.2),
    'rosaTransparent': Color.fromRGBO(228, 81, 173, 0.2),
    'rojoTransparent': Color.fromRGBO(208, 45, 35, 0.2),
  };

  static final TextStyle btnLabel = TextStyle(
    fontFamily: 'MarlinGeo-Medium',

  );

  static final EdgeInsetsGeometry mb4 = EdgeInsets.only(bottom: 4);
  static final EdgeInsetsGeometry mb8 = EdgeInsets.only(bottom: 8);

  static final ButtonStyle btnDefault = ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 6.5),
    textStyle: TextStyle(
      fontSize: 14,
      fontFamily: 'MarlinGeo-Medium',
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );

  static final ButtonStyle btnLarge = ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 10),
  );

  static final TextStyle familyRegular = TextStyle(
    fontFamily: 'MarlinGeo-Regular',
  );

  static final TextStyle familyBold = TextStyle(
    fontFamily: 'MarlinGeo-Bold',
  );

  static final TextStyle textLink = TextStyle(
    color: colors['rosa'],
    fontFamily: 'MarlinGeo-Regular',
  );
}
