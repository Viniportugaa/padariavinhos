import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagemPickerWidget extends StatefulWidget {
  final Function(File imagemSelecionada) onImagemSelecionada;

  const ImagemPickerWidget({
    super.key,
    required this.onImagemSelecionada,
  });

  @override
  State<ImagemPickerWidget> createState() => _ImagemPickerWidgetState();
}

class _ImagemPickerWidgetState extends State<ImagemPickerWidget> {
  File? imagem;

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final imagemSelecionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagemSelecionada != null) {
      final arquivo = File(imagemSelecionada.path);
      setState(() {
        imagem = arquivo;
      });
      widget.onImagemSelecionada(arquivo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        imagem != null
            ? Image.file(imagem!, height: 150, fit: BoxFit.cover)
            : const Text('Nenhuma imagem selecionada'),
        TextButton.icon(
          onPressed: _selecionarImagem,
          icon: const Icon(Icons.image),
          label: const Text('Selecionar Imagem'),
        ),
      ],
    );
  }
}