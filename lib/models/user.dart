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

  final GeoPoint location;

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
    required this.location,

  });

  double get latitude => location.latitude;
  double get longitude => location.longitude;

  String get enderecoFormatado {
    final ramal = ramalApartamento != null && ramalApartamento!.isNotEmpty
        ? ' - Apt $ramalApartamento'
        : '';
    return '$endereco, $numeroEndereco - CEP: $cep ($tipoResidencia$ramal)';
  }

  String get telefoneWhatsApp {
    String digits = telefone.replaceAll(RegExp(r'\D'), ''); // remove tudo que não é número
    if (!digits.startsWith('55')) digits = '55$digits'; // adiciona DDI do Brasil
    return '+$digits';
  }

  User copyWith({
    String? uid,
    String? nome,
    String? endereco,
    String? numeroEndereco,
    String? telefone,
    String? email,
    String? role,
    Timestamp? createdAt,
    String? cep,
    String? tipoResidencia,
    String? ramalApartamento,
    GeoPoint? location,
  }) {
    return User(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      numeroEndereco: numeroEndereco ?? this.numeroEndereco,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      cep: cep ?? this.cep,
      tipoResidencia: tipoResidencia ?? this.tipoResidencia,
      ramalApartamento: ramalApartamento ?? this.ramalApartamento,
      location: location ?? this.location,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'endereco': endereco,
      'numeroEndereco': numeroEndereco,
      'telefone': telefoneWhatsApp,
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'cep': cep,
      'tipo_residencia': tipoResidencia,
      'ramalApartamento': ramalApartamento,
      'location': location,

    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      numeroEndereco: map['numeroEndereco'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'cliente',
      createdAt: map['created_at'] is Timestamp
          ? map['created_at']
          : (map['createdAt'] is Timestamp
          ? map['createdAt']
          : Timestamp.now()),
      cep: map['cep'] ?? '',
      tipoResidencia: map['tipo_residencia'] ?? 'casa',
      ramalApartamento: map['ramalApartamento'],
      location: map['location'] is GeoPoint
          ? map['location']
          : const GeoPoint(0, 0),
    );
  }
}