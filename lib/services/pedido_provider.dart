import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class PedidoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  /// Subtotal e total podem ser calculados sem depender de pedido fixo
  double subtotal(Pedido pedido) => pedido.itens.fold<double>(
      0.0, (sum, item) => sum + (item.subtotal ?? 0.0));

  double totalComFrete(Pedido pedido) {
    final totalBase = pedido.valorAjustado && pedido.totalFinal != null
        ? pedido.totalFinal!
        : subtotal(pedido);
    return totalBase + (pedido.frete ?? 0);
  }

  void atualizarItemPedidoPorIndice({
    required Pedido pedido,
    required int index,
    required double quantidade,
  }) {
    if (index < 0 || index >= pedido.itens.length) return;
    pedido.itens[index].quantidade = quantidade;
    notifyListeners();
  }

  /// Atualiza status de um pedido específico
  Future<void> editar(Pedido pedido) async {
    if (pedido.status == 'pendente') {
      await _firestore
          .collection('pedidos')
          .doc(pedido.id)
          .update({'status': 'em preparo'});
      pedido.status = 'em preparo';
      notifyListeners();
    }
  }

  Future<void> finalizar(Pedido pedido) async {
    if (pedido.impresso == true) {
      await _firestore
          .collection('pedidos')
          .doc(pedido.id)
          .update({'status': 'finalizado'});
      pedido.status = 'finalizado';
      notifyListeners();
    }
  }
  Future<void> cancelarPedido(Pedido pedido) async {
    final docRef = _firestore.collection('pedidos').doc(pedido.id);

    await docRef.update({
      'status': 'cancelado',
      'dataCancelamento': DateTime.now(),
      'notificacao': 'Seu pedido foi cancelado. Por favor, entre em contato: 1199999900',
    });

    // Atualiza o objeto local
    pedido.status = 'cancelado';
    notifyListeners();
  }
  /// Impressão via bluetooth
  Future<void> imprimir(Pedido pedido, User usuario, BuildContext context) async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      if (statuses.values.any((s) => !s.isGranted)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões Bluetooth necessárias não concedidas.')),
        );
        return;
      }

      final devices = await printer.getBondedDevices();
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma impressora pareada encontrada.')),
        );
        return;
      }

      final selectedDevice = devices.first;
      bool isConnected = await printer.isConnected ?? false;
      if (!isConnected) {
        await printer.connect(selectedDevice);
        await Future.delayed(const Duration(seconds: 2));
        isConnected = await printer.isConnected ?? false;
        if (!isConnected) throw Exception("Falha ao conectar à impressora.");
      }

      String enderecoCompleto =
          "${usuario.endereco}, Nº ${usuario.numeroEndereco}";
      if (usuario.tipoResidencia == "apartamento" &&
          usuario.ramalApartamento != null &&
          usuario.ramalApartamento!.isNotEmpty) {
        enderecoCompleto += ", Ap. ${usuario.ramalApartamento}";
      }
      enderecoCompleto += " - CEP: ${usuario.cep}";

      // Impressão
      printer.printNewLine();
      printer.printCustom("Padaria Vinho's", 3, 1);
      printer.printCustom("Pedido num. ${pedido.numeroPedido}", 2, 0);
      printer.printNewLine();
      printer.printLeftRight("Cliente:", pedido.nomeUsuario, 1);
      printer.printLeftRight("Telefone:", pedido.telefone, 1);
      printer.printCustom("Endereco:", 1, 0);
      printer.printCustom(enderecoCompleto, 0, 0);
      printer.printLeftRight("Data:", DateFormat('dd/MM/yyyy HH:mm').format(pedido.data.toLocal()), 1);
      printer.printNewLine();

      printer.printCustom("Itens:", 1, 0);
      for (var item in pedido.itens) {
        final prefixo = item.produto.vendidoPorPeso
            ? "${item.quantidade.toStringAsFixed(2)}/Kg"
            : "${item.quantidade}x";
        final preco = (item.valorFinal ?? item.produto.preco);
        final subtotalItem = preco * item.quantidade;

        printer.printLeftRight(
          "$prefixo ${item.produto.nome}",
          "R\$ ${subtotalItem.toStringAsFixed(2)}",
          0,
        );

        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty) {
          final nomesAcomp = item.acompanhamentos!.map((a) => a.nome).join(', ');
          printer.printCustom("  Acomp: $nomesAcomp", 0, 0);
        }
        if (item.observacao?.isNotEmpty ?? false) {
          printer.printCustom("  Obs: ${item.observacao}", 0, 0);
        }
      }

      printer.printNewLine();
      printer.printLeftRight("Subtotal:", "R\$ ${subtotal(pedido).toStringAsFixed(2)}", 1);
      printer.printLeftRight("Frete:", "R\$ ${(pedido.frete ?? 0).toStringAsFixed(2)}", 1);
      printer.printCustom("Total: R\$ ${totalComFrete(pedido).toStringAsFixed(2)}", 2, 2);
      printer.printCustom("Status: ${pedido.status}", 1, 1);
      printer.printNewLine();
      printer.printQRcode("https://meuapp.com/pedido/${pedido.id}", 200, 200, 1);
      printer.printNewLine();
      printer.paperCut();

      await _firestore.collection('pedidos').doc(pedido.id)
          .update({'status': 'em preparo', 'impresso': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impressão realizada com sucesso!')),
      );

      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao imprimir: $e')),
      );
    }
  }
}
