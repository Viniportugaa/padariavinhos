import 'package:flutter/material.dart';

class VisualizarCardapioPage extends StatefulWidget {
  final String frente;
  final String verso;

  const VisualizarCardapioPage({
    super.key,
    required this.frente,
    required this.verso,
  });

  @override
  State<VisualizarCardapioPage> createState() => _VisualizarCardapioPageState();
}

class _VisualizarCardapioPageState extends State<VisualizarCardapioPage> {
  bool mostrarFrente = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _botaoToggle("Frente", true),
            const SizedBox(width: 12),
            _botaoToggle("Verso", false),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: InteractiveViewer(
            key: ValueKey(mostrarFrente),
            minScale: 0.5,
            maxScale: 4,
            child: Image.asset(
              mostrarFrente ? widget.frente : widget.verso,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoToggle(String texto, bool frente) {
    final bool ativo = mostrarFrente == frente;

    return GestureDetector(
      onTap: () {
        setState(() {
          mostrarFrente = frente;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: ativo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: ativo ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
