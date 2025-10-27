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
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Campo de texto expandido
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                minHeight: 50,
                maxHeight: 120,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: ShapeDecoration(
                color: const Color(0xFFF8F7FD),
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: Colors.black),
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
                maxLines: 5, // Máximo de líneas visibles
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
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
