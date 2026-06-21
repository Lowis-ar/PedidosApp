import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pedidosapp/utils/dimensions.dart';

class WebResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const WebResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        
        // Si no estamos en la web o la pantalla es angosta, renderizar el contenido normalmente
        if (screenWidth <= Dimensions.maxContentWidth) {
          return child;
        }

        // Si es escritorio o tablet (ancho > 500)
        return Container(
          color: const Color(0xFFF4FAF9), // Fondo sutil con toque de color de marca
          child: Center(
            child: Container(
              width: Dimensions.maxContentWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
