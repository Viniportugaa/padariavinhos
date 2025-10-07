import 'package:cloud_firestore/cloud_firestore.dart';

class Cupom {
  final String id;
  final String codigo;
  final double desconto; // pode ser valor fixo
  final bool percentual; // se true, desconto é %
  final DateTime validade;
  final bool ativo;
  final List<String> usuariosUsaram;

  Cupom({
    required this.id,
    required this.codigo,
    required this.desconto,
    this.percentual = false,
    required this.validade,
    this.ativo = true,
    this.usuariosUsaram = const [],
  });

  factory Cupom.fromMap(Map<String, dynamic> map, String id) {
    return Cupom(
      id: id,
      codigo: map['codigo'] ?? '',
      desconto: (map['desconto'] as num?)?.toDouble() ?? 0.0,
      percentual: map['percentual'] ?? false,
      validade: (map['validade'] as Timestamp).toDate(),
      ativo: map['ativo'] ?? true,
      usuariosUsaram: List<String>.from(map['usuariosUsaram'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'desconto': desconto,
      'percentual': percentual,
      'validade': Timestamp.fromDate(validade),
      'ativo': ativo,
      'usuariosUsaram': usuariosUsaram,
    };
  }

  bool isValidoParaUsuario(String userId) {
    if (!ativo) return false;
    if (DateTime.now().isAfter(validade)) return false;
    if (usuariosUsaram.contains(userId)) return false;
    return true;
  }
}
