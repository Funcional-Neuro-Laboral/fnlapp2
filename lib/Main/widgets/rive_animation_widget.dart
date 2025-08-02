import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveAnimationWidget extends StatelessWidget {
  final VoidCallback onAnimationComplete;

  const RiveAnimationWidget({required this.onAnimationComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RiveAnimation.asset(
              'animations/feedback_sucesso.riv', // Cambia el path al archivo .riv correcto
              onInit: (artboard) {
                final controller =
                    StateMachineController.fromArtboard(artboard, 'State Machine 1');
                if (controller != null) {
                  artboard.addController(controller);
                  controller.isActiveChanged.addListener(() {
                    if (!controller.isActive) {
                      // Cuando la animación termina, navega al Home
                      onAnimationComplete();
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
