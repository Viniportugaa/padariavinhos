import 'package:flutter/material.dart';
import '../services/cep_service.dart';
import '../helpers/dialog_helper.dart';

class CepValidatorService {
  static Future<String?> validarCep({
    required BuildContext context,
    required String cep,
  }) async {
    final endereco = await CepService.buscarEndereco(cep);

    if (endereco != null) {
      return "${endereco["logradouro"]}, ${endereco["bairro"]}, "
          "${endereco["cidade"]} - ${endereco["estado"]}";
    } else {
      DialogHelper.showTemporaryToast(context, "CEP inválido ou não encontrado.");
      return null;
    }
  }
}
