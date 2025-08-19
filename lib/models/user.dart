import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String nome;
  final String endereco;
  final String numeroEndereco;
  final String telefone;
  final String email;
  final String role;
  final Timestamp createdAt;
  final String cep;
  final String tipoResidencia;
  final String? ramalApartamento;

  User({
    required this.uid,
    required this.nome,
    required this.endereco,
    required this.numeroEndereco,
    required this.telefone,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.cep,
    required this.tipoResidencia,
    this.ramalApartamento,

  });

  String get enderecoFormatado {
    final ramal = ramalApartamento != null && ramalApartamento!.isNotEmpty
        ? ' - Apt $ramalApartamento'
        : '';
    return '$endereco, $numeroEndereco - CEP: $cep ($tipoResidencia$ramal)';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'endereco': endereco,
      'numero_endereco': numeroEndereco,
      'telefone': telefone,
      'email': email,
      'role': role,
      'created_at': createdAt,
      'cep': cep,
      'tipo_residencia': tipoResidencia,
      'ramal_apartamento': ramalApartamento,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'],
      nome: map['nome'],
      endereco: map['endereco'],
      numeroEndereco: map['numero_endereco'],
      telefone: map['telefone'],
      email: map['email'],
      role: map['role'],
      createdAt: map['created_at'],
      cep: map['cep'],
      tipoResidencia: map['tipo_residencia'] ?? "casa",
      ramalApartamento: map['ramal_apartamento'],
    );
  }
}
