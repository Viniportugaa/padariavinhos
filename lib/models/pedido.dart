import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Pedido {
  final int numeroPedido;
  final String id;
  final String userId;
  final String nomeUsuario;
  final String telefone;
  final List<ItemCarrinho> itens;
  final double? totalFinal;
  String status;
  final DateTime data;
  bool impresso;
  final String? endereco;
  final List<String> formaPagamento;
  final bool valorAjustado;
  final double frete;

  final String tipoEntrega;
  final DateTime? dataEntrega;
  final DateTime? horaEntrega;

  Pedido({
    required this.id,
    required this.numeroPedido,
    required this.userId,
    required this.nomeUsuario,
    required this.telefone,
    required this.itens,
    this.totalFinal,
    required this.status,
    required this.data,
    this.impresso = false,
    this.endereco,
    required this.formaPagamento,
    this.valorAjustado = false,
    this.frete = 4.0,
    required this.tipoEntrega,
    this.dataEntrega,
    this.horaEntrega,


  });

  double get subtotal => itens.fold(0.0, (sum, item) => sum + item.subtotal);

  double get totalComFrete => subtotal + frete;

  DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  factory Pedido.fromMap(Map<String, dynamic> map, String id) {
    return Pedido(
      id: id,
      numeroPedido: map['numeroPedido'] ?? 0,
      userId: map['userId'] ?? '',
      nomeUsuario: map['nomeUsuario'] ?? 'Desconhecido',
      telefone: map['telefone'] ?? 'Sem telefone',
      itens: (map['itens'] as List<dynamic>? ?? [])
          .map((e) => ItemCarrinho.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalFinal: (map['totalFinal'] != null)
          ? (map['totalFinal'] as num).toDouble()
          : null,
      status: map['status'] ?? 'pendente',
      data: (map['data'] is Timestamp)
          ? (map['data'] as Timestamp).toDate()
          : DateTime.now(),
      impresso: map['impresso'] ?? false,
      endereco: map['endereco'],
      formaPagamento: List<String>.from(map['formaPagamento'] ?? ['Pix']),
      valorAjustado: map['valorAjustado'] ?? false,
      frete: (map['frete'] != null) ? (map['frete'] as num).toDouble() : 4.0, // 🔹 se não tiver salvo, assume 4.0
      tipoEntrega: map['tipoEntrega'] ?? 'entrega',
      dataEntrega: map['dataEntrega'] != null
          ? (map['dataEntrega'] as Timestamp).toDate()
          : null,
      horaEntrega: map['horaEntrega'] != null
          ? (map['horaEntrega'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numeroPedido': numeroPedido,
      'userId': userId,
      'nomeUsuario': nomeUsuario,
      'telefone': telefone,
      'itens': itens.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'frete': frete,
      'totalComFrete': totalComFrete,
      'totalFinal': totalFinal,
      'status': status,
      'data': Timestamp.fromDate(data),
      'impresso': impresso,
      'endereco': endereco,
      'formaPagamento': formaPagamento,
      'valorAjustado': valorAjustado,
      'tipoEntrega': tipoEntrega,
      'dataEntrega': dataEntrega != null ? Timestamp.fromDate(dataEntrega!) : null,
      'horaEntrega': horaEntrega != null ? Timestamp.fromDate(horaEntrega!) : null,
    };

  }
}