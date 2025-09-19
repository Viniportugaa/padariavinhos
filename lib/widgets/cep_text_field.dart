import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cep_validator_service.dart';

class CepTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController addressController;
  final void Function(bool) onCepValidated;

  const CepTextField({
    super.key,
    required this.controller,
    required this.addressController,
    required this.onCepValidated,
  });

  @override
  State<CepTextField> createState() => _CepTextFieldState();
}

class _CepTextFieldState extends State<CepTextField> {
  bool isLoading = false;

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _buscarCep(String cep) async {
    setState(() => isLoading = true);

    final endereco = await CepValidatorService.validarCep(
      context: context,
      cep: cep,
    );

    setState(() => isLoading = false);

    if (endereco != null) {
      widget.addressController.text = endereco;
      widget.onCepValidated(true);
    } else {
      widget.onCepValidated(false);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final cep = _onlyDigits(widget.controller.text.trim());
      if (cep.length == 8 && !isLoading) {
        _buscarCep(cep);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: "CEP",
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: isLoading
            ? const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : null,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'CEP não pode ser vazio';
        if (!RegExp(r'^\d{5}-?\d{3}$').hasMatch(v)) return 'CEP inválido';
        return null;
      },
    );
  }
}
