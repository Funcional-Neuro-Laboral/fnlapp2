import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // Importa esta librería para usar json.decode
import 'package:fnlapp/Main/step_screen.dart';
import 'package:intl/intl.dart';

class PlanScreen extends StatelessWidget {
  final NivelEstres nivelEstres;
  final bool isLoading;
  final List<dynamic> programas;

  PlanScreen(
      {required this.nivelEstres,
      required this.isLoading,
      required this.programas});

  bool isProgramUnlocked(dynamic programa) {
    if (programa['start_date'] != null) {
      DateTime temp = DateTime.parse(programa['start_date']).toLocal();
      DateTime date = DateTime(temp.year, temp.month, temp.day);
      bool isRightDay = DateTime.now().isAfter(date);
      return isRightDay;
    } else {
      return false;
    }

    //return true;
  }

  double getProgramPercentage() {
    if (programas.isEmpty) {
      return 0;
    }
    return (programas.where((x) => x['completed_date'] != null).length /
                21 *
                1000)
            .round() /
        10;
  }

  Expanded buildProgramView(dynamic programa, BuildContext context,
      Color backgroundColor, Color textColor) {
    if (isProgramUnlocked(programa)) {
      return Expanded(
        child: Container(
          width: 350,
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                programa['nombre_tecnica'] ?? 'Sin nombre',
                style: GoogleFonts.poppins(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      programa['descripcion'] ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 14.0, color: Colors.black87),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      dynamic stepsData = programa['guia'];
                      List<dynamic> steps;

                      if (stepsData is String) {
                        steps = json.decode(stepsData);
                      } else {
                        steps = stepsData;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StepScreen(
                            steps: List<String>.from(steps),
                            tecnicaNombre: programa['nombre_tecnica'],
                            dia: int.tryParse(programa['dia'].toString()) ?? 0,
                            userId: int.tryParse(programa['user_id'].toString()) ?? 0,
                            tecnicaId: int.tryParse(programa['id'].toString()) ?? 0,
                            url_img: programa['url_img'],
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 237, 221, 255),
                      radius: 24,
                      child: Icon(
                        Icons.play_arrow,
                        size: 28,
                        color: Color.fromARGB(255, 75, 21, 141),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: Color.fromARGB(255, 240, 240, 240),
                        radius: 15,
                        child: Icon(Icons.headset,
                            color: Color.fromARGB(255, 103, 21, 141), size: 18),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 8,
                          child:
                              Icon(Icons.check, color: Colors.white, size: 9),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        programa['tipo_tecnica'],
                        style: GoogleFonts.poppins(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                        ),
                        maxLines: 2, // Si el texto es largo, se ajusta en dos líneas como máximo
                        overflow: TextOverflow.ellipsis, // Si sigue siendo largo, muestra "..."
                        textAlign: TextAlign.center, // Centra el texto dentro del cuadro
                      ),
                    ),
                  ),

                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Expanded(
        child: Container(
          width: 350,
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF6e848e),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                programa['nombre_tecnica'] ?? 'Sin nombre',
                style: GoogleFonts.poppins(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255)),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      programa['start_date'] == null
                          ? 'Esta lección se desbloqueará al día siguiente de haber completado la anterior.'
                          : 'Esta lección se desbloqueará el ${DateFormat('dd/MM/yyyy').format(DateTime.parse(programa['start_date']).toLocal())}',
                      style: GoogleFonts.poppins(
                          fontSize: 14.0,
                          color: const Color.fromARGB(255, 255, 255, 255)),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    radius: 24,
                    child: Icon(
                        programa['start_date'] == null
                            ? Icons.lock
                            : Icons.lock_clock_rounded,
                        size: 28,
                        color: const Color(0xFF6e848e)),
                  )
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      );
    }
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 237, 221, 255),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 130.0),
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mi plan diario',
                          style: GoogleFonts.poppins(
                              fontSize: 28.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3F0071)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Nivel de estrés: ',
                              style: GoogleFonts.poppins(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4A4A4A)),
                            ),
                            Text(
                              isLoading
                                  ? "Cargando..."
                                  : nivelEstres.name.toUpperCase(),
                              style: GoogleFonts.poppins(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3F0071)),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        // Progreso mejorado con diseño minimalista
                        if (!isLoading && programas.length > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Progreso del plan",
                                style: GoogleFonts.poppins(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3F0071)),
                              ),
                              SizedBox(height: 10),
                              // Barra de progreso personalizada
                              Stack(
                                children: [
                                  Container(
                                    width: 300,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white, // Fondo blanco
                                    ),
                                  ),
                                  Container(
                                    width: (300 * getProgramPercentage() / 100)
                                        .clamp(0, 300),
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF3F0071),
                                          Color(0xFF7C47FF),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        "${getProgramPercentage()}%",
                                        style: GoogleFonts.poppins(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3F0071)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          SizedBox(),
                        SizedBox(height: 20),
                        if (isLoading)
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF3F0071),
                            ),
                          )
                        else if (programas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              'No hay programas disponibles',
                              style: GoogleFonts.poppins(
                                  fontSize: 16.0, color: Color(0xFF4A4A4A)),
                            ),
                          )
                        else
                          Column(
                            children: programas
                                .map((programa) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0),
                                      child:
                                          _buildProgramaWidget(programa, context),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildProgramaWidget(dynamic programa, BuildContext context) {
    print('Contenido de programa: ${jsonEncode(programa)}');
    // Verifica que 'tecnica' no sea null
    if (programa['nombre_tecnica'] == null ||
        programa['nombre_tecnica'].isEmpty) {
      return Container(); // O muestra un widget de error/placeholder
    }

    // Añadir logs para depurar
    print('Programa ID: ${programa['id']}');
    print('Técnica: ${programa['nombre_tecnica']}');

    Color backgroundColor;
    Color textColor;

    // Establecer colores dependiendo del tipo de terapia
    if (programa['dia'] >= 1 && programa['dia'] <= 4) {
      backgroundColor = Color.fromARGB(255, 206, 252, 255); // Azul claro
      textColor = Color(0xFF44DEE8); // Azul para el texto
    } else if (programa['dia'] >= 5 && programa['dia'] <= 7) {
      backgroundColor = Color.fromARGB(255, 240, 230, 255); // Lavanda claro
      textColor = Color(0xFF9C27B0); // Morado para el texto
    } else if (programa['dia'] >= 8 && programa['dia'] <= 10) {
      backgroundColor = Color.fromARGB(255, 255, 220, 240); // Rosado claro
      textColor = Color(0xFFFF44B5); // Rosado para el texto
    } else if (programa['dia'] >= 11 && programa['dia'] <= 13) {
      backgroundColor = Color.fromARGB(255, 255, 200, 240); // Rosa más suave
      textColor = Color(0xFFFF80AB); // Rosa intenso para el texto
    } else if (programa['dia'] >= 14 && programa['dia'] <= 16) {
      backgroundColor = Color.fromARGB(255, 255, 235, 205); // Naranja claro
      textColor = Color(0xFFFFA500); // Naranja para el texto
    } else if (programa['dia'] >= 17 && programa['dia'] <= 19) {
      backgroundColor = Color.fromARGB(255, 255, 235, 175); // Amarillo suave
      textColor = Color(0xFFFFC107); // Amarillo para el texto
    } else if (programa['dia'] >= 20 && programa['dia'] <= 21) {
      backgroundColor = Color.fromARGB(255, 255, 180, 180); // Coral suave
      textColor = Color(0xFFFF5722); // Naranja quemado para el texto
    } else {
      // Para cualquier día fuera del rango de 1 a 21, asignamos un color por defecto
      backgroundColor =
          Color.fromARGB(255, 206, 252, 255); // Azul claro por defecto
      textColor = Color(0xFF44DEE8); // Azul para el texto
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Día',
                  style: GoogleFonts.poppins(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
                Text(
                  programa['dia'].toString().padLeft(2, '0'),
                  style: GoogleFonts.poppins(
                      fontSize: 34.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                Container(
                  height: 40,
                  width: 3,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          buildProgramView(programa, context, backgroundColor, textColor)
        ],
      ),
    );
  }
}
