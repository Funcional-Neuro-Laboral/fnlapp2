import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:fnlapp/Main/cargarprograma.dart';
import 'package:fnlapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Preguntas/questions_data.dart';
import 'package:fnlapp/Main/home.dart';

class TestEstresQuestionScreen extends StatefulWidget {
  const TestEstresQuestionScreen({Key? key}) : super(key: key);

  @override
  _TestEstresQuestionScreenState createState() =>
      _TestEstresQuestionScreenState();
}

class _TestEstresQuestionScreenState extends State<TestEstresQuestionScreen> {
  int currentQuestionIndex = 0;
  List<int> selectedOptions = List<int>.filled(
      23, 0); // Asigna un valor predeterminado (por ejemplo, 0)

  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Cargamos el ID del usuario al iniciar
  }

  // Función para cargar el userId desde SharedPreferences
  Future<void> _loadUserId() async {
    int? id = await getUserId(); // Función que obtienes de SharedPreferences
    setState(() {
      userId = id;
      if (userId == null) {
        print('Error: userId is null');
        return;
      } else {
        print('Success: todo bien con el id');
      }
    });
  }

  // Función para seleccionar una opción
  void selectOption(int optionId) {
    setState(() {
      selectedOptions[currentQuestionIndex] =
          optionId; // Guarda la respuesta para la pregunta actual
    });
  }

  void goToNextQuestion() {
    if (selectedOptions[currentQuestionIndex] != 0 &&
        currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Por favor selecciona una opción antes de continuar')),
      );
    }
  }

  void goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

Future<void> submitTest() async {
  // Validar userId antes de proceder
  if (userId == null) {
    print("Error: userId es null");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: No se ha cargado el ID del usuario')),
    );
    return;
  }

  // Validar si selectedOptions está correctamente poblado
  if (selectedOptions.isEmpty || selectedOptions.length < 23) {
    print("Error: selectedOptions no tiene suficientes datos.");
    return;
  }

  // URLs de las APIs
  final checkRecordUrl =
      Uri.parse('${Config.apiUrl}/userestresessions/$userId/nivel'); // Verificar registro
  final saveTestUrl = Uri.parse('${Config.apiUrl}/guardarTestEstres'); // Guardar test
  final updateEstresUrl = Uri.parse('${Config.apiUrl}/userestresessions/assign'); // Actualizar estres_nivel_id

  // Calcular el puntaje total
  int totalScore = selectedOptions.fold(0, (sum, value) => sum + value);

  try {
    // Verificar si existe un registro para este usuario
    final checkResponse = await http.get(checkRecordUrl);

    if (checkResponse.statusCode != 200 && checkResponse.statusCode != 404) {
      print('Error al verificar registro del usuario: ${checkResponse.body}');
      return;
    }

    bool recordExists = checkResponse.statusCode == 200;

    // Obtener el gender_id del usuario
    final genderResponse =
        await http.get(Uri.parse('${Config.apiUrl}/userResponses/$userId'));
    if (genderResponse.statusCode != 200) {
      print('Error al obtener el gender_id: ${genderResponse.statusCode}');
      return;
    }

    final List<dynamic> userData = json.decode(genderResponse.body);
    int genderId = userData.isNotEmpty ? userData[0]['gender_id'] ?? 1 : 1;

    // Calcular el nivel de estrés y su ID
    final Map<String, dynamic> estresResult =
        _calcularNivelEstres(totalScore, genderId);
    NivelEstres nivelEstres = estresResult['nivel'];
    int estresNivelId = estresResult['id'];

  if (recordExists) {
    // Si el registro ya existe, actualiza el nivel de estrés
    final updateData = {
      'user_id': userId,
      'estres_nivel_id': estresNivelId,
    };
    final updateResponse = await http.post(
      updateEstresUrl,
      headers: {"Content-Type": "application/json"},
      body: json.encode(updateData),
    );

    if (updateResponse.statusCode != 200) {
      print('Error al actualizar el estres_nivel_id: ${updateResponse.body}');
      return;
    }

    print('Nivel de estrés actualizado correctamente.');

    // Guardar las respuestas en la tabla `test_estres_salida`
    final saveExitTestUrl = Uri.parse('${Config.apiUrl}/guardarTestEstresSalida');
    final Map<String, dynamic> exitTestData = {
      'user_id': userId,
      for (int i = 0; i < selectedOptions.length; i++)
        'pregunta_${i + 1}': selectedOptions[i],
      'estado': 'activo',
    };

    final exitTestResponse = await http.post(
      saveExitTestUrl,
      headers: {"Content-Type": "application/json"},
      body: json.encode(exitTestData),
    );

    if (exitTestResponse.statusCode != 200) {
      print('Error al guardar el test de salida: ${exitTestResponse.body}');
      return;
    }

    print('Test de salida guardado correctamente.');

    // Redirigir al HomeScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
    );

    return;
}
 else {
      // Si no existe un registro, guardar el test completo
      final Map<String, dynamic> data = {
        'user_id': userId,
        for (int i = 0; i < selectedOptions.length; i++)
          'pregunta_${i + 1}': selectedOptions[i],
        'estado': 'activo',
      };

      // Guardar el test en el backend
      final response = await http.post(
        saveTestUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        print('Error al guardar el test: ${response.body}');
        return;
      }

      print('Test guardado correctamente.');

      // Crear un nuevo registro con el nivel de estrés
      final newRecordData = {
        'user_id': userId,
        'estres_nivel_id': estresNivelId,
      };
      final newRecordResponse = await http.post(
        updateEstresUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode(newRecordData),
      );

      if (newRecordResponse.statusCode != 200) {
        print('Error al crear el registro: ${newRecordResponse.body}');
        return;
      }

      print('Registro de nivel de estrés creado correctamente.');

      // Actualizar testestresbool a true
      await _updateTestEstresBool();

      // Generar reporte en paralelo
      final generateReportUrl =
          Uri.parse('${Config.apiUrl}/userprograma/report/$userId');
      final Map<String, dynamic> reportData = {
        for (int i = 0; i < selectedOptions.length; i++)
          'pregunta_${i + 1}': selectedOptions[i]
      };

      Future<void> generateReport() async {
        try {
          final reportResponse = await http.post(
            generateReportUrl,
            headers: {"Content-Type": "application/json"},
            body: json.encode(reportData),
          );

          if (reportResponse.statusCode != 200) {
            print('Error al generar el reporte: ${reportResponse.body}');
            return;
          }
          print('Reporte generado y guardado correctamente.');
        } catch (e) {
          print('Error al generar el reporte: $e');
        }
      }

      generateReport();

      // Navegar a la pantalla de programa de estrés
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CargarProgramaScreen(nivelEstres: nivelEstres),
        ),
      );
    }
  } catch (e) {
    print('Error al procesar el test: $e');
  }
}

  // Función para calcular el nivel de estrés
  Map<String, dynamic> _calcularNivelEstres(int totalScore, int genderId) {
    NivelEstres nivelEstres = NivelEstres.desconocido;
    int estresNivelId = 0;

    if (totalScore <= 92) {
      nivelEstres = NivelEstres.leve;
      estresNivelId = 1;
    } else if (totalScore > 92 && totalScore <= 138) {
      if (genderId == 1) {
        nivelEstres = NivelEstres.moderado;
        estresNivelId = 2;
      } else if (genderId == 2) {
        nivelEstres =
            totalScore <= 132 ? NivelEstres.moderado : NivelEstres.severo;
        estresNivelId = totalScore <= 132 ? 2 : 3;
      }
    } else if (totalScore > 138) {
      if (genderId == 1) {
        nivelEstres = NivelEstres.severo;
        estresNivelId = 3;
      } else if (genderId == 2) {
        nivelEstres = NivelEstres.leve;
        estresNivelId = 3;
      }
    }

    return {'nivel': nivelEstres, 'id': estresNivelId};
  }

  // Actualizar testestresbool a true en el backend
  Future<void> _updateTestEstresBool() async {
    try {
      String? token = await getToken(); // Obtener token de SharedPreferences
      if (token == null) {
        print('Error: No se encontró el token.');
        return;
      }

      final url = Uri.parse('${Config.apiUrl}/users/$userId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'testestresbool': true}),
      );

      if (response.statusCode == 200) {
        print('Campo testestresbool actualizado correctamente.');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('testestresbool', true);
      } else {
        print('Error al actualizar testestresbool: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al actualizar testestresbool: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // Verificación inicial para asegurarse de que 'questions' no esté vacío y que el índice esté en rango
    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return Scaffold(
        body: Center(
          child: Text("No hay preguntas disponibles"), // Mensaje de error si no hay preguntas
        ),
      );
    }

    // Asignar la pregunta actual solo si la lista de preguntas tiene contenido y el índice es válido
    final question = questions[currentQuestionIndex];

    // Obtener el ancho de la pantalla
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Color(0xFFF6F6F6), // Fondo de todo el Scaffold
        child: SingleChildScrollView( // Añadir el SingleChildScrollView para permitir el desplazamiento
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),  // Mantener margen horizontal
            child: Column(
              children: [
                // Row para colocar el icono "Atrás" a la izquierda y el texto centrado
                Padding(
                  padding: const EdgeInsets.only(top: 20.0), // Añadir espacio vertical hacia abajo
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: Colors.black, // Color de la flecha
                          size: 50.0, // Tamaño más grande de la flecha
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => HomeScreen()),
                                (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
                          );
                        },
                      ),
                      SizedBox(width: 0), // Espacio entre el icono y el texto
                      Expanded(
                        child: Align(
                          alignment: Alignment(-0.25, 0), // Alineación a la izquierda
                          child: Text(
                            'Pregunta ${currentQuestionIndex + 1} de ${questions.length}', // Texto completo
                            style: TextStyle(
                              color: const Color(0xFF4320AD),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700, // Estilo para "Pregunta"
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Para la línea sombreada en la parte inferior
                Container(
                  margin: const EdgeInsets.only(top: 5.0), // Agregar un poco de espacio por encima
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  height: 7, // Definir altura de la línea
                ),

                SizedBox(height: 20), // Espacio entre el encabezado y la pregunta

                if (question['question'] != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Espacio a la izquierda y derecha
                    child: Text(
                      question['question']!,
                      textAlign: TextAlign.start, // Alineación ajustada un poco a la izquierda
                      style: TextStyle(
                        color: const Color(0xFF4320AD),
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0), // Espacio a la izquierda y derecha
                    child: Text(
                      'Pregunta no disponible',
                      textAlign: TextAlign.start, // Alineación ajustada un poco a la izquierda
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],

                if (question['description'] != null) ...[
                  SizedBox(height: 12), // Margen superior
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0), // Espacio a la izquierda y derecha
                    child: Text(
                      question['description']!,
                      textAlign: TextAlign.start, // Alineación ajustada un poco a la izquierda
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 20),


                // Opciones de respuesta
                Column(
                  children: List.generate(8, (index) {
                    final optionKey = 'option${index + 1}';
                    final detailKey = 'detail${index + 1}';
                    final optionText = question[optionKey];
                    final optionDetail = question[detailKey];

                    if (optionText == null || optionDetail == null) {
                      return SizedBox.shrink();
                    }

                    bool isSelected = selectedOptions[currentQuestionIndex] == (index + 1);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: GestureDetector(
                        onTap: () => selectOption(index + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: screenWidth - 48, // Ajustar el ancho para que no se recorte
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0x8E5027D0) : Colors.white,
                            border: Border.all(
                              width: 2,
                              color: Color(0xFF6D4BD8),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                optionText,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Color(0xFF6D4BD8),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Detalle: ",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: optionDetail,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: 20), // Espacio adicional

                // Botones de navegación (Atrás y Siguiente/Finalizar)
                // Botones de navegación
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ---- ATRÁS ----
                      if (currentQuestionIndex > 0)
                        GestureDetector(
                          onTap: goToPreviousQuestion,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x4C000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Atrás',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 88), // Espacio vacío cuando no hay más preguntas anteriores

                      // ---- SIGUIENTE / FINALIZAR ----
                      Builder(
                        builder: (context) {
                          final bool isNextEnabled = selectedOptions[currentQuestionIndex] != 0;
                          final String nextLabel = currentQuestionIndex < questions.length - 1 ? 'Siguiente' : 'Finalizar';

                          return GestureDetector(
                            onTap: isNextEnabled
                                ? () {
                              if (currentQuestionIndex < questions.length - 1) {
                                goToNextQuestion();
                              } else {
                                submitTest(); // Llamar a la función que envía el test
                              }
                            }
                                : null,
                            child: Container(
                              width: 158,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              clipBehavior: Clip.antiAlias,
                              decoration: ShapeDecoration(
                                color: isNextEnabled ? const Color(0xFF6D4BD8) : const Color(0xFFD7D7D7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                shadows: isNextEnabled
                                    ? const [
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Color(0x4C000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                    spreadRadius: 0,
                                  ),
                                ]
                                    : const [],
                              ),
                              child: Center(
                                child: Text(
                                  nextLabel,
                                  style: TextStyle(
                                    color: isNextEnabled ? Colors.white : const Color(0xFF868686),
                                    fontSize: 22,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }

}


