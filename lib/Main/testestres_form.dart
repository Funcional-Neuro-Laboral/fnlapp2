import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:fnlapp/Main/cargarprograma.dart';
import 'package:fnlapp/config.dart';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
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
          child: Text(
              "No hay preguntas disponibles"), // Mensaje de error si no hay preguntas
        ),
      );
    }

    // Asignar la pregunta actual solo si la lista de preguntas tiene contenido y el índice es válido
    final question = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Icono de flecha hacia atrás
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
            );
          },
        ),
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .center, // Centra los elementos en el eje horizontal
            children: [
              SizedBox(height: 20),

              // Mostrar el número de pregunta actual
              Text(
                'Pregunta ${currentQuestionIndex + 1} de ${questions.length}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),

              // Verificar que 'question['question']' no sea null antes de usarlo
              if (question['question'] != null) ...[
                Text(
                  question['question']!,
                  textAlign: TextAlign.center, // Centra el texto
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold), // Font más pequeño
                ),
              ] else ...[
                Text(
                  'Pregunta no disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ],

              // Descripción centrada y con margen superior
              if (question['description'] != null) ...[
                SizedBox(height: 12), // Margen superior
                Text(
                  question['description']!,
                  textAlign: TextAlign.center, // Centra el texto
                  style: TextStyle(fontSize: 16),
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

                  // Verificar que cada opción no sea null antes de crear el widget
                  if (optionText == null || optionDetail == null) {
                    return SizedBox
                        .shrink(); // No mostrar si la opción o detalle son null
                  }

                  bool isSelected =
                      selectedOptions[currentQuestionIndex] == (index + 1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 5),
                    child: GestureDetector(
                      onTap: () => selectOption(
                          index + 1), // Seleccionar opción al hacer clic
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 300), // Animación al cambiar tamaño
                        width: double
                            .infinity, // Opción ocupa todo el ancho disponible
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 13),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color.fromARGB(255, 56, 30, 134)
                              : const Color.fromARGB(255, 234, 234, 234),
                          border: Border.all(
                            color: isSelected
                                ? Color.fromARGB(255, 40, 19, 105)
                                : const Color.fromARGB(255, 212, 212, 212),
                            width: 2.0,
                          ),
                          borderRadius:
                              BorderRadius.circular(6), // Bordes más cuadrados
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight
                                        .normal, // Negrita si está seleccionado
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            if (isSelected) // Mostrar el detalle si la opción está seleccionada
                              Padding(
                                padding: const EdgeInsets.only(
                                    top:
                                        13.0), // Incrementar margen superior del detalle
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Detalle: ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight
                                              .bold, // Negrita para "Detalle:"
                                          color: Colors.white,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      TextSpan(
                                        text: optionDetail,
                                        style: const TextStyle(
                                          fontStyle: FontStyle
                                              .italic, // Texto en cursiva para el detalle
                                          fontSize:
                                              14, // Tamaño de fuente reducido
                                          color: Colors.white,
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

              SizedBox(height: 20),

              // Botones de navegación
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentQuestionIndex > 0)
                    ElevatedButton(
                      onPressed: goToPreviousQuestion,
                      child: Text('Anterior'),
                    ),
                  if (currentQuestionIndex < questions.length - 1)
                    ElevatedButton(
                      onPressed: selectedOptions[currentQuestionIndex] != 0
                          ? goToNextQuestion
                          : null, // Deshabilitar si no hay selección
                      child: Text('Siguiente'),
                    ),
                ],
              ),
              SizedBox(height: 20),

              // Botón para enviar el test
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: ElevatedButton(
                  onPressed: (currentQuestionIndex == questions.length - 1 &&
                          selectedOptions[currentQuestionIndex] != 0)
                      ? submitTest
                      : null, // Deshabilitar si no es la última pregunta o no hay selección
                  child: Text('Enviar Test'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
