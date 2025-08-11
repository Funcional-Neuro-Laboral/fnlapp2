import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class ChatMessage extends StatefulWidget {
  final String message;
  final String time;
  final int userId;
  final int userType;

  ChatMessage({
    Key? key,
    required this.message,
    required this.time,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  _ChatMessageState createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  final FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() {
    flutterTts.setCompletionHandler(() async {
      setState(() => isPlaying = false);
    });

    flutterTts.setCancelHandler(() {
      setState(() => isPlaying = false);
    });

    flutterTts.setErrorHandler((message) {
      setState(() => isPlaying = false);
    });
  }

  void _speakMessage() async {
    if (isPlaying) {
      await flutterTts.stop();
      setState(() => isPlaying = false);
    } else {
      await flutterTts.setLanguage("es-ES");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.7);
      setState(() => isPlaying = true);
      await flutterTts.speak(widget.message);
    }
  }

  List<TextSpan> _buildTextSpans(String text) {
    List<TextSpan> spans = [];
    final RegExp combinedRegExp = RegExp(
        r'(https?://[^\s()<>"]+)|(\*\*(.*?)\*\*)|(\[Ver video aquí\])');
    final matches = combinedRegExp.allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
              color: widget.userType != 1 ? Colors.black : Colors.black),
        ));
      }

      if (match.group(1) != null) {
        final String url = match.group(1) ?? '';
        spans.add(TextSpan(
          text: url,
          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
        ));
      } else if (match.group(2) != null) {
        final String boldText = match.group(3) ?? '';
        spans.add(TextSpan(
          text: boldText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.userType != 1 ? Colors.black : Colors.black,
          ),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: '[Ver video aquí] ',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: widget.userType != 1 ? Colors.black : Colors.black,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: widget.userType != 1 ? Colors.white : Colors.black),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.userType != 1 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Para mensajes del bot (userType == 1)
        if (widget.userType == 1)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar del bot
                CircleAvatar(
                  radius: 20.0,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.network(
                      'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_chat.jpg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                // Burbuja del mensaje
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 80.0),
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFEAE5F9),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x28000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (widget.message.contains('http://') || widget.message.contains('https://'))
                            Column(
                              children: [
                                Image.network(
                                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQe3IymTZ4kS68lCty_j3iy0oSOIGiVk6Zw2A&usqp=CAU',
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(height: 4.0),
                              ],
                            ),
                          RichText(
                            text: TextSpan(
                              children: _buildTextSpans(widget.message),
                              style: TextStyle(
                                fontSize: 16.0,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.0),
                          //Linea Separadora
                          Container(
                            height: 1.0,
                            width: double.infinity,
                            color: Color(0x99212121),
                          ),
                          SizedBox(height: 4.0),
                          //Iconos de Copiar y Reproducir
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.copy_rounded,
                                  size: 20.0,
                                  color: Color(0xFF351A8B),
                                ),
                                onPressed: () {
                                  // Copiar texto al portapapeles
                                  Clipboard.setData(ClipboardData(text: widget.message));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Texto copiado')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                                  size: 20.0,
                                  color: Color(0xFF351A8B),
                                ),
                                onPressed: _speakMessage,
                              ),
                            ],
                          ),
                        ]
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Para mensajes del usuario (userType != 1)
        if (widget.userType != 1)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.only(
                top: 4.0,
                bottom: 4.0,
                left: 80.0,
                right: 50.0,
              ),
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Color(0xFF8A6FE0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (widget.message.contains('http://') || widget.message.contains('https://'))
                      Column(
                        children: [
                          Image.network(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQe3IymTZ4kS68lCty_j3iy0oSOIGiVk6Zw2A&usqp=CAU',
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 4.0),
                        ],
                      ),
                    RichText(
                      text: TextSpan(
                        children: _buildTextSpans(widget.message),
                        style: TextStyle(
                          fontSize: 16.0,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                  ]
              ),
            ),
          ),

        // Hora del mensaje
        Padding(
          padding: EdgeInsets.only(
            left: widget.userType != 1 ? 80.0 : 50.0,
            right: widget.userType != 1 ? 50.0 : 80.0,
            top: 2.0,
            bottom: 8.0,
          ),
          child: Align(
            alignment: widget.userType != 1 ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              widget.time,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: Color(0xB2212121),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
