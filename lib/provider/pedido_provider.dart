import 'package:flutter/material.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class PedidoStatus {
  static const pendente = 'pendente';
  static const emPreparo = 'em preparo';
  static const finalizado = 'finalizado';
  static const cancelado = 'cancelado';
}

class PedidoProvider extends ChangeNotifier {
  final PedidoService _pedidoService = PedidoService();
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------- Cálculos -----------------
  double subtotal(Pedido pedido) => pedido.subtotal;
  double totalComFrete(Pedido pedido) => pedido.totalFinal;

  // ----------------- Status e persistência -----------------
  Future<void> finalizar(Pedido pedido) async {
    pedido.status = PedidoStatus.finalizado;
    notifyListeners();

    await _firestore.collection('pedidos').doc(pedido.id).update({
      'status': PedidoStatus.finalizado,
      'totalFinal': pedido.totalFinal,
    });

    await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);
  }

  Future<void> cancelar(Pedido pedido) async {
    pedido.status = PedidoStatus.cancelado;
    notifyListeners();

    await _firestore.collection('pedidos').doc(pedido.id).update({
      'status': PedidoStatus.cancelado,
      'dataCancelamento': DateTime.now(),
      'notificacao':
      'Seu pedido foi cancelado. Por favor, entre em contato: 1199999900',
      'totalFinal': pedido.totalFinal,
    });

    await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);
  }

  Future<void> colocarEmPreparo(Pedido pedido) async {
    if (pedido.status == PedidoStatus.pendente) {
      pedido.status = PedidoStatus.emPreparo;
      notifyListeners();

      await _firestore.collection('pedidos').doc(pedido.id).update({
        'status': PedidoStatus.emPreparo,
        'totalFinal': pedido.totalFinal,
      });

      await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);
    }
  }

  // ----------------- Impressão -----------------
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

      String enderecoCompleto = "${usuario.endereco}, Nº ${usuario.numeroEndereco}";
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
      printer.printCustom("DATA ${pedido.dataHoraEntrega}", 2, 0);
      printer.printNewLine();
      printer.printLeftRight("Cliente:", pedido.nomeUsuario, 1);
      printer.printLeftRight("Telefone:", pedido.telefone, 1);
      printer.printCustom("Endereço:", 1, 0);
      printer.printCustom(enderecoCompleto, 0, 0);
      printer.printLeftRight("Data:", DateFormat('dd/MM/yyyy HH:mm').format(pedido.data.toLocal()), 1);
      printer.printNewLine();

      printer.printCustom("Itens:", 1, 0);
      for (var item in pedido.itens) {
        final prefixo = item.produto.vendidoPorPeso
            ? "${item.quantidade.toStringAsFixed(2)}/Kg"
            : "${item.quantidade}x";

        final subtotalItem = item.subtotal;

        printer.printLeftRight("$prefixo ${item.produto.nome}", "R\$ ${subtotalItem.toStringAsFixed(2)}", 0);

        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty) {
          final nomesAcomp = item.acompanhamentos!.map((a) => a.nome).join(', ');
          printer.printCustom("  Acomp: $nomesAcomp", 0, 0);
        }

        if (item.observacao?.isNotEmpty ?? false) {
          printer.printCustom("  Obs: ${item.observacao}", 0, 0);
        }
      }

      printer.printNewLine();
      printer.printLeftRight("Subtotal:", "R\$ ${pedido.subtotal.toStringAsFixed(2)}", 1);
      printer.printLeftRight("Frete:", "R\$ ${pedido.frete.toStringAsFixed(2)}", 1);
      printer.printCustom("Total: R\$ ${pedido.totalFinal.toStringAsFixed(2)}", 2, 2);
      printer.printCustom("Status: ${pedido.status}", 1, 1);
      printer.printNewLine();
      printer.printQRcode("https://meuapp.com/pedido/${pedido.id}", 200, 200, 1);
      printer.printNewLine();
      printer.paperCut();

      pedido.status = PedidoStatus.emPreparo;
      pedido.impresso = true;
      notifyListeners();

      await _firestore.collection('pedidos').doc(pedido.id).update({
        'status': PedidoStatus.emPreparo,
        'impresso': true,
        'totalFinal': pedido.totalFinal,
      });

      await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impressão realizada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao imprimir: $e')),
      );
    }
  }
}
