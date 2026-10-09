import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;


class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const body = Color(0xFF70779C);
  static const border = Color(0xFFD9DCEF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const disabledText = Color(0xFF9AA0C0);
  static const white = Color(0xFFFFFFFF);
}

class ChatBoxFooter extends StatelessWidget {
  final TextEditingController textEditingController;
  final Function(String) onSendMessage;

  ChatBoxFooter({
    required this.textEditingController,
    required this.onSendMessage,
  });

  void _send() {
    final message = textEditingController.text.trim();
    if (message.isEmpty) return;
    onSendMessage(message);
    textEditingController.clear();
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _FnlColors.white,
        border: Border(
          top: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Campo de texto expandido
              Expanded(
                child: TextField(
                  controller: textEditingController,
                  style: GoogleFonts.roboto(
                    color: _FnlColors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  cursorColor: _FnlColors.violet,
                  decoration: InputDecoration(
                    hintText: 'Mensaje...',
                    hintStyle: GoogleFonts.roboto(
                      color: _FnlColors.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: _FnlColors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    enabledBorder: _border(_FnlColors.border, 1),
                    focusedBorder: _border(_FnlColors.violet, 2),
                    border: _border(_FnlColors.border, 1),
                  ),
                  maxLines: 5, // Máximo de líneas visibles
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,

                  onSubmitted: (_) => _send(),
                ),
              ),

              const SizedBox(width: 8),

              ValueListenableBuilder<TextEditingValue>(
                valueListenable: textEditingController,
                builder: (context, value, _) {
                  final bool enabled = value.text.trim().isNotEmpty;
                  final radius = BorderRadius.circular(18);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: enabled ? _FnlColors.violet : _FnlColors.border,
                      borderRadius: radius,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: radius,
                        onTap: enabled ? _send : null,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 24,
                          semanticLabel: 'Enviar mensaje',
                          color: enabled
                              ? _FnlColors.white
                              : _FnlColors.disabledText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}