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

  User({
    required this.uid,
    required this.nome,
    required this.endereco,
    required this.numeroEndereco,
    required this.telefone,
    required this.email,
    required this.role,
    required this.createdAt,
  });

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
    );
  }
}
