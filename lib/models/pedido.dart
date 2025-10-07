import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:padariavinhos/models/cupom.dart';

class Pedido {
  final int numeroPedido;
  final String id;
  final String userId;
  final String nomeUsuario;
  final String telefone;
  final List<ItemCarrinho> itens;
  final double totalFinal;
  String status;
  final DateTime data;
  bool impresso;
  final String? endereco;
  final List<String> formaPagamento;
  final double frete;
  final String tipoEntrega;
  final DateTime? dataHoraEntrega;
  final Cupom? cupomAplicado;

  final double? valorPago;
  final double? troco;

  Pedido({
    required this.id,
    required this.numeroPedido,
    required this.userId,
    required this.nomeUsuario,
    required this.telefone,
    required this.itens,
    double? totalFinal,
    required this.status,
    required this.data,
    this.impresso = false,
    this.endereco,
    required this.formaPagamento,
    this.frete = 4.0,
    required this.tipoEntrega,
    this.dataHoraEntrega,
    this.cupomAplicado,
    this.valorPago,
    this.troco,
  }) : totalFinal = totalFinal ?? _calcularTotalFinal(itens, frete, cupomAplicado);

  /// Subtotal coerente (cada item calcula subtotal com PrecoHelper)
  double get subtotal {
    return itens.fold(0.0, (sum, item) {
      final precoUnitario = item.precoUnitarioCustom ??
          PrecoHelper.calcularPrecoUnitario(
            produto: item.produto,
            selecionados: item.acompanhamentos,
          );
      return sum + (precoUnitario * item.quantidade);
    });
  }


  static double _calcularTotalFinal(List<ItemCarrinho> itens, double frete, Cupom? cupom) {
    double subtotal = 0.0;
    for (var item in itens) {
      final precoUnitario = item.precoUnitarioCustom ??
          PrecoHelper.calcularPrecoUnitario(
            produto: item.produto,
            selecionados: item.acompanhamentos,
          );
      subtotal += precoUnitario * item.quantidade;
    }
    double total = subtotal + frete;
    if (cupom != null) {
      if (cupom.percentual) {
        total -= total * (cupom.desconto / 100);
      } else {
        total -= cupom.desconto;
      }
      if (total < 0) total = 0; // nunca negativo
    }

    return total;
  }



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
    final itens = (map['itens'] as List<dynamic>? ?? [])
        .map((e) => ItemCarrinho.fromMap(e as Map<String, dynamic>))
        .toList();

    final frete = (map['frete'] != null) ? (map['frete'] as num).toDouble() : 4.0;
    Cupom? cupom;
    if (map['cupomAplicado'] != null) {
      cupom = Cupom.fromMap(map['cupomAplicado'], 'inline');
    }
    final subtotal = (map['subtotal'] != null)
        ? (map['subtotal'] as num).toDouble()
        : itens.fold(0.0, (sum, item) {
      final precoUnitario = item.precoUnitarioCustom ??
          PrecoHelper.calcularPrecoUnitario(
            produto: item.produto,
            selecionados: item.acompanhamentos,
          );
      return sum + (precoUnitario * item.quantidade);
    });
    return Pedido(
      id: id,
      numeroPedido: map['numeroPedido'] ?? 0,
      userId: map['userId'] ?? '',
      nomeUsuario: map['nomeUsuario'] ?? 'Desconhecido',
      telefone: map['telefone'] ?? 'Sem telefone',
      itens: itens,
      totalFinal: (map['totalFinal'] != null)
          ? (map['totalFinal'] as num).toDouble()
          : _calcularTotalFinal(itens, frete, cupom),
      status: map['status'] ?? 'pendente',
      data: (map['data'] is Timestamp)
          ? (map['data'] as Timestamp).toDate()
          : DateTime.now(),
      impresso: map['impresso'] ?? false,
      endereco: map['endereco'],
      formaPagamento: List<String>.from(map['formaPagamento'] ?? ['Pix']),
      frete: frete,
      tipoEntrega: map['tipoEntrega'] ?? 'entrega',
      dataHoraEntrega: map['dataHoraEntrega'] != null
          ? (map['dataHoraEntrega'] as Timestamp).toDate()
          : null,
      cupomAplicado: cupom,
      valorPago: (map['valorPago'] as num?)?.toDouble(),
      troco: (map['troco'] as num?)?.toDouble(),

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numeroPedido': numeroPedido,
      'userId': userId,
      'nomeUsuario': nomeUsuario,
      'telefone': telefone,
      'itens': itens.map((item) => item.toMap()).toList(),
      'frete': frete,
      'subtotal': subtotal,
      'totalFinal': totalFinal,
      'status': status,
      'data': Timestamp.fromDate(data),
      'impresso': impresso,
      'endereco': endereco,
      'formaPagamento': formaPagamento,
      'tipoEntrega': tipoEntrega,
      'dataHoraEntrega':
      dataHoraEntrega != null ? Timestamp.fromDate(dataHoraEntrega!) : null,
      'cupomAplicado': cupomAplicado?.toMap(),
      'valorPago': valorPago,
      'troco': troco,
    };
  }
}
