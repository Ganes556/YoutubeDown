import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';

class RobotoMonoText extends StatelessWidget {
  String text;
  double fontSize;
  FontWeight fontWeight;
  TextAlign textAlign;
  Color color;

  RobotoMonoText(
    this.text, {
    this.fontSize = 18,
    this.textAlign = TextAlign.center,
    this.color = Colors.white,
    required this.fontWeight,
  });
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.robotoMono(
        textStyle: TextStyle(
          color: color,
          fontWeight: fontWeight,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class RobotoText extends StatelessWidget {
  String text;
  double fontSize;
  FontWeight fontWeight;
  TextAlign textAlign;
  Color color;
  RobotoText(
    this.text, {
    this.fontSize = 18,
    this.textAlign = TextAlign.center,
    this.color = Colors.white,
    required this.fontWeight,
  });
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.roboto(
        textStyle: TextStyle(
          color: color,
          fontWeight: fontWeight,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
