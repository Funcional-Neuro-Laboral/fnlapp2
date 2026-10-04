import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ChatBoxFooter extends StatelessWidget {
  final TextEditingController textEditingController;
  final Function(String) onSendMessage;
  final bool enabled;

  ChatBoxFooter({
    required this.textEditingController,
    required this.onSendMessage,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: textEditingController,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: onSendMessage,
              style: const TextStyle(fontSize: 16, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: enabled ? 'Escribe un mensaje…' : 'Reconectando con Funcy…',
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Enviar mensaje',
            onPressed: enabled ? () => onSendMessage(textEditingController.text) : null,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.disabledBg,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
