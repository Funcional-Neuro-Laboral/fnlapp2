import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';

class ChatMessage extends StatefulWidget {
  final String message;
  final String time;
  final int userId;

  /// 1 = Funcy; cualquier otro valor = usuario.
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
  final List<TapGestureRecognizer> _recognizers = [];
  bool isPlaying = false;

  bool get _isBot => widget.userType == 1;

  @override
  void initState() {
    super.initState();
    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isPlaying = false);
    });
    flutterTts.setCancelHandler(() {
      if (mounted) setState(() => isPlaying = false);
    });
    flutterTts.setErrorHandler((message) {
      if (mounted) setState(() => isPlaying = false);
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _speakMessage() async {
    if (isPlaying) {
      await flutterTts.stop();
      setState(() => isPlaying = false);
    } else {
      await flutterTts.setLanguage('es-ES');
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.7);
      setState(() => isPlaying = true);
      await flutterTts.speak(widget.message.replaceAll('**', ''));
    }
  }

  List<TextSpan> _buildTextSpans(String text, Color textColor, Color linkColor) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <TextSpan>[];
    final combined = RegExp(r'(https?://[^\s()<>"]+)|(\*\*(.*?)\*\*)|(\[Ver video aquí\])');
    var lastMatchEnd = 0;

    for (final match in combined.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      if (match.group(1) != null) {
        final url = match.group(1)!;
        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          };
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: url,
          style: TextStyle(color: linkColor, decoration: TextDecoration.underline),
          recognizer: recognizer,
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(text: match.group(3) ?? '', style: const TextStyle(fontWeight: FontWeight.w800)));
      } else if (match.group(4) != null) {
        spans.add(const TextSpan(text: '[Ver video aquí] ', style: TextStyle(fontStyle: FontStyle.italic)));
      }
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isBot ? AppColors.ink : Colors.white;
    final linkColor = _isBot ? AppColors.primaryDeep : Colors.white;
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _isBot ? Colors.white : AppColors.primary,
        border: _isBot ? Border.all(color: AppColors.borderSoft) : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(_isBot ? 6 : 18),
          bottomRight: Radius.circular(_isBot ? 18 : 6),
        ),
      ),
      child: SelectableText.rich(
        TextSpan(
          children: _buildTextSpans(widget.message, textColor, linkColor),
          style: TextStyle(fontSize: 15, height: 22 / 15, color: textColor, fontWeight: FontWeight.w500),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(_isBot ? 16 : 64, 6, _isBot ? 64 : 16, 6),
      child: Column(
        crossAxisAlignment: _isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          bubble,
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    widget.time,
                    style: const TextStyle(fontSize: 11, height: 14 / 11, color: AppColors.inkTertiary),
                  ),
                ),
              if (_isBot) ...[
                IconButton(
                  tooltip: 'Copiar mensaje',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.inkSecondary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mensaje copiado')),
                    );
                  },
                ),
                IconButton(
                  tooltip: isPlaying ? 'Detener lectura' : 'Escuchar mensaje',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                    size: 20,
                    color: AppColors.inkSecondary,
                  ),
                  onPressed: _speakMessage,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
