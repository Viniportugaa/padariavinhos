import 'package:flutter/material.dart';

class DialogHelper {
  /// Mostra uma mensagem temporária tipo toast no centro da tela
  static void showTemporaryToast(BuildContext context, String mensagem,
      {int segundos = 1}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // Cria o overlay entry
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        mensagem: mensagem,
      ),
    );

    // Insere na tela
    overlay.insert(overlayEntry);

    // Remove depois de [segundos]
    Future.delayed(Duration(seconds: segundos), () {
      overlayEntry.remove();
    });
  }
}

/// Widget do toast animado
class _ToastWidget extends StatefulWidget {
  final String mensagem;

  const _ToastWidget({required this.mensagem});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
    _offset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  widget.mensagem,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
