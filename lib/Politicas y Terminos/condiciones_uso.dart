import 'package:flutter/material.dart';

class CondicionesUsoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Condiciones de Uso'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '- Condiciones de Uso -',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Actualizado por última vez: 13 de enero del 2025',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 16),
              _buildSection('1. Aceptación de las Condiciones de Uso',
                  'El acceso y uso de la aplicación Funcional Neuro Laboral (en adelante, "la Aplicación") están sujetos a las presentes Condiciones de Uso. Al acceder, descargar o utilizar la Aplicación, el usuario declara haber leído, comprendido y aceptado estas condiciones en su totalidad. Si no está de acuerdo con alguna de las disposiciones, debe abstenerse de utilizar la Aplicación.'),
              _buildSection(
                '2. Objeto de la Aplicación',
                'Funcional Neuro Laboral tiene como finalidad brindar herramientas para la evaluación y mejora del bienestar emocional y laboral de sus usuarios mediante el análisis de información proporcionada por ellos mismos. La Aplicación no sustituye asesoramiento profesional médico, psicológico o legal.',
              ),
              _buildSection(
                '3. Registro y Responsabilidad del Usuario',
                '•	Para utilizar la Aplicación, el usuario debe registrarse proporcionando información veraz, completa y actualizada. Es responsabilidad exclusiva del usuario mantener la confidencialidad de sus credenciales de acceso.\n•	El usuario se compromete a no compartir su cuenta con terceros ni permitir su uso no autorizado.\n•	Cualquier actividad realizada bajo las credenciales del usuario será considerada como realizada por el propio usuario.',
              ),
              _buildSection(
                '4. Uso Permitido de la Aplicación',
                'El usuario se compromete a utilizar la Aplicación únicamente con fines personales y conforme a la legislación aplicable. Está prohibido:\n•	Utilizar la Aplicación con fines ilegales, fraudulentos o no autorizados.\n•	Modificar, copiar, distribuir, transmitir, exhibir, realizar, reproducir, publicar, licenciar, crear trabajos derivados, transferir o vender cualquier contenido de la Aplicación sin autorización previa por escrito.\n•	Realizar actividades que puedan dañar, inutilizar, sobrecargar o deteriorar la Aplicación o interferir con su uso por parte de otros usuarios.',
              ),
              _buildSection(
                '5. Propiedad Intelectual',
                'Todos los derechos sobre el contenido, diseño, funcionalidades y software de la Aplicación son de propiedad exclusiva de Funcional Neuro Laboral o de sus licenciantes. El usuario no adquiere ningún derecho sobre dichos elementos, salvo el derecho limitado de uso personal y no transferible de la Aplicación conforme a estas Condiciones de Uso.',
              ),
              _buildSection(
                '6. Exclusión de Garantías',
                'Funcional Neuro Laboral proporciona la Aplicación "tal cual" y no garantiza que:\n•	La Aplicación estará libre de errores, interrupciones o fallas.\n•	Los resultados obtenidos mediante el uso de la Aplicación serán precisos o confiables.\n•	La Aplicación cumplirá con las expectativas del usuario.',
              ),
              _buildSection(
                '7. Limitación de Responsabilidad',
                'En la medida permitida por la ley aplicable, Funcional Neuro Laboral no será responsable por daños directos, indirectos, incidentales, especiales, consecuentes o punitivos derivados del uso o imposibilidad de uso de la Aplicación, incluso si se ha advertido sobre la posibilidad de tales daños.',
              ),
              _buildSection(
                '8. Suspensión y Terminación del Servicio',
                'Funcional Neuro Laboral se reserva el derecho de suspender o terminar el acceso del usuario a la Aplicación, sin previo aviso, si considera que el usuario ha incumplido estas Condiciones de Uso o por razones operativas, de seguridad o legales.',
              ),
              _buildSection(
                '9. Modificaciones de las Condiciones de Uso',
                'Funcional Neuro Laboral podrá modificar estas Condiciones de Uso en cualquier momento. Las modificaciones serán comunicadas al usuario mediante la Aplicación y entrarán en vigor inmediatamente. El uso continuado de la Aplicación posterior a la comunicación de los cambios implicará la aceptación de las nuevas condiciones.',
              ),
              _buildSection(
                '10. Legislación Aplicable y Jurisdicción',
                'Estas Condiciones de Uso se rigen por la legislación vigente en la República del Perú. Cualquier controversia que surja en relación con estas Condiciones de Uso será sometida a los juzgados y tribunales competentes de la ciudad de Lima, Perú.',
              ),
              _buildSection(
                '11. Contacto',
                'Para consultas relacionadas con estas Condiciones de Uso, el usuario puede contactarnos mediante el correo electrónico contacto@fnldigital.com o el formulario de contacto disponible en la Aplicación.',
              ),
              _buildSection(
                '12. Disposiciones Finales',
                'Si alguna disposición de estas Condiciones de Uso se considera inválida o inaplicable, las disposiciones restantes continuarán en pleno vigor y efecto. La falta de ejercicio de un derecho o disposición por parte de Funcional Neuro Laboral no constituirá una renuncia al mismo.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
