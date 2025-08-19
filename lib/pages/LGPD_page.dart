import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFScreen extends StatelessWidget {

  const PDFScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visualizador de PDF")),
      body: SfPdfViewer.asset('assets/lgpdnormas.pdf'), // Para asset
    );
  }
}