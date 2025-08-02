import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts para usar tipografías personalizadas
import '../Util/api_service.dart'; // Importa el servicio de API personalizado

// Pantalla de "Test de Salida"
class RaitingScreen extends StatefulWidget {
  final String username; // Nombre de usuario pasado a la pantalla
  final ApiService apiServiceWithToken; // Servicio de API con token autenticado

  RaitingScreen({
    required this.username, // Parámetros obligatorios
    required this.apiServiceWithToken,
  });

  @override
  _RaitingScreenState createState() => _RaitingScreenState();
}

class _RaitingScreenState extends State<RaitingScreen> {
  late String username; // Almacena el nombre de usuario

  @override
  void initState() {
    super.initState();
    username = widget.username; // Asigna el nombre de usuario del widget a la variable local
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Establece el fondo de la pantalla en blanco
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ajusta el tamaño de la columna al contenido
          children: [
            Icon(
              Icons.speed, // Ícono de velocidad
              size: 75.0, // Tamaño del ícono
              color: Color(0xFF5027D0), // Color del ícono
            ),
            SizedBox(height: 20), // Espacio entre el ícono y el texto
            Text(
              'Test de Salida', // Texto principal
              style: GoogleFonts.poppins(
                fontSize: 24.0, // Tamaño del texto
                color: Colors.black, // Color del texto
                fontWeight: FontWeight.bold, // Grosor del texto
              ),
            ),
            SizedBox(height: 20), // Espacio entre el texto y el siguiente elemento
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centra el Row horizontalmente
              crossAxisAlignment: CrossAxisAlignment.center, // Alinea el contenido del Row en el centro
              children: [
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center, // Centra el texto dentro del RichText
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 18.0, // Tamaño del texto en RichText
                        color: Colors.black, // Color del texto
                      ),
                      children: [
                        TextSpan(
                          text: 'Ya completaste los 21 días del programa personalizado por lo que es momento que realices tu ',
                        ),
                        TextSpan(
                          text: ' Test de Salida ', // Texto destacado
                          style: TextStyle(
                            color: Color(0xFF5027D0), // Color destacado
                          ),
                        ),
                        TextSpan(
                          text: 'Para una evaluación final.',
                        ),
                      ],
                    ),
                    overflow: TextOverflow.visible, // Permite que el texto fluya a la siguiente línea si es necesario
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0), // Añade padding alrededor del botón
              child: ElevatedButton(
                onPressed: () {
                  // Acción al presionar el botón (actualmente vacío)
                },
                child: Text(
                  'Empezar Test',
                  style: GoogleFonts.poppins(), // Estilo del texto en el botón
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, // Color del texto del botón
                  backgroundColor: Color(0xFF5027D0), // Color de fondo del botón
                  minimumSize: Size(double.infinity, 50), // Asegura que el botón ocupe todo el ancho disponible
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
