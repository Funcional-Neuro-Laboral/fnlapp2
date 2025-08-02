import 'package:flutter/material.dart';

class PoliticaPrivacidadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Política de Privacidad'),
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
                '- Política de Privacidad -',
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
              _buildSection(
                '1. Introducción',
                'En Funcional Neuro Laboral reconocemos la importancia de proteger los datos personales de nuestros usuarios y nos comprometemos a garantizar la confidencialidad, seguridad y uso adecuado de la información recopilada. Estas políticas de privacidad se rigen por la normativa vigente en la República del Perú, incluyendo la Ley Nº 29733, Ley de Protección de Datos Personales, y su Reglamento aprobado mediante el Decreto Supremo Nº 003-2013-JUS.',
              ),
              _buildSection(
                '2. Recopilación y Finalidad del Tratamiento de Datos Personales',
                'Funcional Neuro Laboral recolecta y procesa datos personales proporcionados voluntariamente por el usuario relativos a su bienestar emocional y laboral. Dichos datos serán tratados con el fin exclusivo de:\n•	Realizar análisis y evaluaciones que permitan mejorar el bienestar emocional y laboral del usuario.\n• Diseñar y perfeccionar los servicios ofrecidos por la aplicación.\n•	Llevar a cabo estudios internos destinados a evaluar tendencias y patrones relacionados con la materia de bienestar laboral.\n•	Producir informes estadísticos anonimizados que permitan comprender mejor las problemáticas laborales y emocionales de los usuarios.\n•	Desarrollar estrategias personalizadas que optimicen la experiencia del usuario dentro de la aplicación.',
              ),
              _buildSection(
                '3. Principios Rectores del Tratamiento de Datos',
                'El tratamiento de datos personales se realiza bajo los principios de legalidad, consentimiento, finalidad, proporcionalidad, calidad, seguridad y confidencialidad, conforme a lo establecido en la normativa peruana aplicable.',
              ),
              _buildSection(
                '4. Consentimiento Informado del Usuario',
                'El usuario otorga su consentimiento libre, previo, expreso, inequívoco e informado para el tratamiento de sus datos personales mediante la aceptación de las presentes políticas de privacidad. Dicho consentimiento incluye la autorización para el análisis y evaluación de la información ingresada con los fines establecidos en el numeral 2.',
              ),
              _buildSection(
                '5. Confidencialidad y No Divulgación de Datos',
                'Los datos personales recopilados serán tratados con estricta confidencialidad y no serán compartidos, cedidos ni transferidos a terceros bajo ninguna circunstancia, salvo obligación legal o mandato judicial debidamente fundamentado. Implementamos medidas técnicas, legales y organizativas adecuadas para garantizar la seguridad de los datos. Estas medidas incluyen:\n•	Sistemas de encriptación avanzada para proteger la información almacenada.\n•	Controles de acceso restringido al personal autorizado.\n•	Auditorías periódicas para garantizar el cumplimiento de las normativas.',
              ),
              _buildSection('6. Derechos del Titular de los Datos',
                  'De conformidad con la Ley Nº 29733, el usuario tiene los siguientes derechos respecto a sus datos personales:\n•	Derecho de acceso: Conocer si sus datos están siendo objeto de tratamiento y obtener información sobre las condiciones de este.\n•	Derecho de rectificación: Solicitar la actualización o corrección de sus datos personales en caso de ser inexactos o incompletos.\n•	Derecho de cancelación: Pedir la eliminación de sus datos personales cuando estos hayan dejado de ser necesarios para los fines establecidos o cuando desee retirar su consentimiento.\n•	Derecho de oposición: Manifestar su negativa al tratamiento de sus datos por motivos fundados y legítimos.\n•	Derecho a la portabilidad: Solicitar que sus datos personales sean transferidos a otro responsable del tratamiento, siempre que sea técnicamente posible.\nPara ejercer estos derechos, el usuario podrá contactarse a través de los canales de comunicación dispuestos por Funcional Neuro Laboral, detallados en el numeral 9.'),
              _buildSection('7. Conservación de Datos',
                  'Los datos personales serán conservados durante el tiempo estrictamente necesario para cumplir con los fines para los cuales fueron recopilados, salvo disposición legal en contrario. En caso de que los datos sean anonimizados para fines estadísticos o de investigación, podrán ser conservados por un periodo indeterminado sin que estos sean identificables.'),
              _buildSection('8. Modificaciones de las Políticas de Privacidad',
                  'Funcional Neuro Laboral se reserva el derecho de modificar total o parcialmente las presentes políticas de privacidad. En caso de cambios significativos, el usuario será notificado oportunamente a través de los medios disponibles en la aplicación. El uso continuado de la aplicación posterior a la comunicación de dichas modificaciones implicará la aceptación de los cambios por parte del usuario.'),
              _buildSection('9. Contacto y Consultas',
                  'Para cualquier consulta, duda o ejercicio de derechos vinculados a la protección de datos personales, el usuario podrá comunicarse mediante el correo electrónico contacto@fnldigital.com o a través del formulario de contacto disponible en la aplicación. Asimismo, se dispone de una línea de atención directa para consultas urgentes relacionadas con la privacidad de los datos.'),
              _buildSection('10. Disposiciones Finales',
                  'Estas políticas de privacidad entran en vigor desde la fecha de su publicación en la aplicación y se mantienen vigentes mientras la aplicación continúe en operación, salvo actualizaciones que las modifiquen. El cumplimiento de estas políticas se encuentra supervisado conforme a la normativa aplicable. Para garantizar una implementación efectiva, Funcional Neuro Laboral realiza revisiones periódicas de estas políticas y de las prácticas de gestión de datos, asegurando un compromiso constante con la privacidad y los derechos de los usuarios.'),
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
