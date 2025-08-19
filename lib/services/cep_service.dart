import 'dart:convert';
import 'package:http/http.dart' as http;

class CepService {
  static Future<Map<String, dynamic>?> buscarEndereco(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), ''); // remove traços/pontos
    if (cleanCep.length != 8) return null;

    final url = Uri.parse("https://viacep.com.br/ws/$cleanCep/json/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey("erro")) return null;

      return {
        "logradouro": data["logradouro"],
        "bairro": data["bairro"],
        "cidade": data["localidade"],
        "estado": data["uf"],
      };
    }
    return null;
  }
}
