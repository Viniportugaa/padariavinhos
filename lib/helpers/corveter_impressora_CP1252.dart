import 'dart:convert';

String converterParaCp1252(String texto) {
  // Remove caracteres que não são representáveis (opcional)
  final bytes = latin1.encode(texto); // latin1 é equivalente ao CP1252
  return latin1.decode(bytes);
}
