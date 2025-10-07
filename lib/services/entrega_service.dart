import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class EntregaService {
  static const double padariaLat = -23.561414; // Latitude da padaria
  static const double padariaLng = -46.655881; // Longitude da padaria
  static const double raioEntregaKm = 1.1;    // raio de entrega

  /// Retorna lat/lng e valida se está dentro do raio de entrega
  static Future<Map<String, dynamic>> verificarEndereco(String cep) async {
    final cleanedCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    print("🔹 CEP recebido: $cep → Limpo: $cleanedCep");

    // 1️⃣ ViaCEP
    final viacepUrl = Uri.parse('https://viacep.com.br/ws/$cleanedCep/json/');
    print("🔹 Requisição ViaCEP: $viacepUrl");
    final viacepResponse = await http.get(viacepUrl);
    if (viacepResponse.statusCode != 200) return {'valido': false, 'mensagem': 'Erro ao buscar CEP.'};

    final viacepData = json.decode(viacepResponse.body);
    if (viacepData.containsKey('erro')) return {'valido': false, 'mensagem': 'CEP não encontrado.'};

    final logradouro = viacepData['logradouro'] ?? '';
    final bairro = viacepData['bairro'] ?? '';
    final localidade = viacepData['localidade'] ?? '';
    final uf = viacepData['uf'] ?? '';

    final enderecoCompleto = '$logradouro, $bairro, $localidade, $uf, Brazil';
    print("🔹 Endereço completo do ViaCEP: $enderecoCompleto");

    // 2️⃣ Nominatim (OSM)
    final nominatimUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(enderecoCompleto)}&format=json&limit=1&addressdetails=1');
    print("🔹 Requisição Nominatim: $nominatimUrl");
    final nominatimResponse = await http.get(
      nominatimUrl,
      headers: {'User-Agent': 'PadariaVinhosApp/1.0'},
    );
    if (nominatimResponse.statusCode != 200) return {'valido': false, 'mensagem': 'Erro ao localizar endereço.'};

    final nominatimData = json.decode(nominatimResponse.body);
    if (nominatimData.isEmpty) return {'valido': false, 'mensagem': 'Não foi possível localizar o endereço.'};

    final location = nominatimData[0];
    final lat = double.tryParse(location['lat'] ?? '');
    final lng = double.tryParse(location['lon'] ?? '');
    if (lat == null || lng == null) return {'valido': false, 'mensagem': 'Erro ao converter coordenadas.'};

    print("🔹 Coordenadas obtidas → Latitude: $lat, Longitude: $lng");

    // 3️⃣ Calcula distância
    final distancia = _calcularDistanciaKm(padariaLat, padariaLng, lat, lng);
    print("🔹 Distância até a padaria: ${distancia.toStringAsFixed(2)} km");

    return {
      'valido': distancia <= raioEntregaKm,
      'mensagem': distancia <= raioEntregaKm ? 'Endereço dentro do raio de entrega!' : 'Endereço fora do raio de entrega.',
      'lat': lat,
      'lng': lng,
    };
  }

  static double _calcularDistanciaKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
