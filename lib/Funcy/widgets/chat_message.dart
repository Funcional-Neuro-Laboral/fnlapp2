import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:url_launcher/url_launcher.dart';


class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const body = Color(0xFF70779C);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const white = Color(0xFFFFFFFF);
}

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
  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';

  final FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;
  bool _imagesPrecached = false;

  late final List<TapGestureRecognizer> _recognizers = [];

  bool get _isBot => widget.userType == 1;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const NetworkImage(_funcyUrl), context);
      _imagesPrecached = true;
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _initializeTts() {
    flutterTts.setCompletionHandler(() async {
      if (mounted) setState(() => isPlaying = false);
    });

    flutterTts.setCancelHandler(() {
      if (mounted) setState(() => isPlaying = false);
    });

    flutterTts.setErrorHandler((message) {
      if (mounted) setState(() => isPlaying = false);
    });
  }

  void _speakMessage() async {
    if (isPlaying) {
      await flutterTts.stop();
      if (mounted) setState(() => isPlaying = false);
    } else {
      await flutterTts.setLanguage("es-ES");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.7);
      if (!mounted) return;
      setState(() => isPlaying = true);
      await flutterTts.speak(widget.message);
    }
  }


  List<TextSpan> _buildTextSpans(String text, Color linkColor) {
    _disposeRecognizers();

    final List<TextSpan> spans = [];
    final RegExp combinedRegExp = RegExp(
        r'(https?://[^\s()<>"]+)|(\*\*(.*?)\*\*)|(\[Ver video aquí\])');
    final matches = combinedRegExp.allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      if (match.group(1) != null) {
        final String url = match.group(1) ?? '';
        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            if (await canLaunch(url)) {
              await launch(url);
            }
          };
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: url,
          style: TextStyle(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
            fontWeight: FontWeight.w500,
          ),
          recognizer: recognizer,
        ));
      } else if (match.group(2) != null) {
        final String boldText = match.group(3) ?? '';
        spans.add(TextSpan(
          text: boldText,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(4) != null) {
        spans.add(const TextSpan(
          text: '[Ver video aquí] ',
          style: TextStyle(fontStyle: FontStyle.italic),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  Widget _buildMessageText({required Color textColor, required Color linkColor}) {
    return RichText(
      text: TextSpan(
        children: _buildTextSpans(widget.message, linkColor),
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.5,
        ),
      ),
    );
  }

  // Avatar de Funcy con borde
  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
        shape: BoxShape.circle,
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          _funcyUrl,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.chat_bubble_rounded,
            size: 18,
            color: _FnlColors.violet,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? _FnlColors.violet : _FnlColors.lavender,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: active ? _FnlColors.white : _FnlColors.violet,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotMessage(double maxBubbleWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _FnlColors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: _FnlColors.bubbleBorder,
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMessageText(
                      textColor: _FnlColors.blue,
                      linkColor: _FnlColors.violet,
                    ),
                    const SizedBox(height: 12),
                    // Línea separadora
                    Container(
                      height: 2,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _FnlColors.lavenderDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Copiar y reproducir
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.copy_rounded,
                          tooltip: 'Copiar',
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.message));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Texto copiado')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: isPlaying
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          tooltip: isPlaying ? 'Detener' : 'Escuchar',
                          active: isPlaying,
                          onTap: _speakMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(double maxBubbleWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _FnlColors.violet,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: _buildMessageText(
              textColor: _FnlColors.white,
              linkColor: _FnlColors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double maxBubbleWidth = (width * 0.78).clamp(0.0, 560.0);

    return Column(
      crossAxisAlignment:
          _isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (_isBot) _buildBotMessage(maxBubbleWidth),
        if (!_isBot) _buildUserMessage(maxBubbleWidth),

        // Hora del mensaje
        Padding(
          padding: EdgeInsets.only(
            left: _isBot ? 16 + 40 + 8 : 16,
            right: 16,
            top: 4,
            bottom: 12,
          ),
          child: Text(
            widget.time,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _FnlColors.body,
            ),
          ),
        ),
      ],
    );
  }
}