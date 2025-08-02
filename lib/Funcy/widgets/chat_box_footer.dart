import 'package:flutter/material.dart';

class ChatBoxFooter extends StatelessWidget {
  final TextEditingController textEditingController;
  final Function(String) onSendMessage;

  ChatBoxFooter({
    required this.textEditingController,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF6F6F6),
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Campo de texto expandido
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: ShapeDecoration(
                color: const Color(0xFFEAE6FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: TextField(
                controller: textEditingController,
                style: TextStyle(
                  color: const Color(0xFF020107),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Mensaje...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF222222),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (message) {
                  String trimmedMessage = message.trim();
                  if (trimmedMessage.isNotEmpty) {
                    onSendMessage(trimmedMessage);
                    textEditingController.clear();
                  }
                },
              ),
            ),
          ),

          SizedBox(width: 8), // Espaciado entre el campo y el botón

          // Botón de enviar
          Container(
            width: 44,
            height: 44,
            decoration: ShapeDecoration(
              color: const Color(0xFF6D4BD8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              onPressed: () {
                String message = textEditingController.text.trim();
                if (message.isNotEmpty) {
                  onSendMessage(message);
                  textEditingController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
