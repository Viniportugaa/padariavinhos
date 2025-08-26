import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class PedidoProvider extends ChangeNotifier {
  Pedido? pedido;
  User? usuario;


  final _firestore = FirebaseFirestore.instance;
  final printer = BlueThermalPrinter.instance;

  PedidoProvider({this.pedidoId}) {
    if (pedidoId != null) _init();
  }
  final String? pedidoId;

  void _init() {
    if (pedidoId == null) return;
    _firestore.collection('pedidos').doc(pedidoId).snapshots().listen((snapshot) async {
      pedido = Pedido.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      await _fetchUsuario();
      notifyListeners(); // apenas uma vez
    });
  }

  Future<void> atualizarItemPedidoPorIndice({
    required int index,
    required double quantidade,
    double? valorFinal,
  }) async {
    if (pedido == null) return;
    if (index < 0 || index >= pedido!.itens.length) return;

    pedido!.itens[index].quantidade = quantidade;
    if (valorFinal != null) pedido!.itens[index].valorFinal = valorFinal;

    await _firestore.collection('pedidos').doc(pedidoId).update({
      'itens': pedido!.itens.map((i) => i.toMap()).toList(),
    });

    notifyListeners();
  }

  Future<void> _fetchUsuario() async {
    if (pedido == null) return;
    final doc = await _firestore.collection('users').doc(pedido!.userId).get();
    if (doc.exists) {
      usuario = User.fromMap(doc.data()!);
      notifyListeners();
    }
  }

  Future<void> editar() async {
    if (pedido != null && pedido!.status == 'pendente') {
      await _firestore.collection('pedidos').doc(pedidoId).update({'status': 'em preparo'});
      pedido!.status = 'em preparo';
      notifyListeners();
    }
  }

  Future<void> finalizar() async {
    if (pedido != null && pedido!.impresso == true) {
      await _firestore.collection('pedidos').doc(pedidoId).update({'status': 'finalizado'});
      pedido!.status = 'finalizado';
      notifyListeners();
    }
  }

  Future<void> imprimir(BuildContext context) async {
    if (pedido == null || usuario == null) return;

    try {
      // Solicita permissões necessárias
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      if (statuses.values.any((status) => !status.isGranted)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões Bluetooth necessárias não concedidas.')),
        );
        return;
      }

      // Lista impressoras pareadas
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

      // Formata endereço completo
      String enderecoCompleto = "${usuario!.endereco}, Nº ${usuario!.numeroEndereco}";
      if (usuario!.tipoResidencia == "apartamento" &&
          usuario!.ramalApartamento != null &&
          usuario!.ramalApartamento!.isNotEmpty) {
        enderecoCompleto += ", Ap. ${usuario!.ramalApartamento}";
      }
      enderecoCompleto += " - CEP: ${usuario!.cep}";

      // Impressão
      printer.printNewLine();
      printer.printCustom("Padaria Vinho's", 3, 1);
      printer.printCustom("Pedido num. ${pedido!.numeroPedido}", 2, 0);
      printer.printNewLine();
      printer.printLeftRight("Cliente:", pedido!.nomeUsuario, 1);
      printer.printLeftRight("Telefone:", pedido!.telefone, 1);
      printer.printCustom("Endereco:", 1, 0);
      printer.printCustom(enderecoCompleto, 0, 0);
      printer.printLeftRight("Data:", DateFormat('dd/MM/yyyy HH:mm').format(pedido!.data.toLocal()), 1);
      printer.printNewLine();

      printer.printCustom("Itens:", 1, 0);
      for (var item in pedido!.itens) {
        final prefixo = item.produto.vendidoPorPeso ? "${item.quantidade.toStringAsFixed(2)}/Kg" : "${item.quantidade}x";
        printer.printLeftRight(
          "$prefixo ${item.produto.nome}",
          "R\$ ${item.subtotal.toStringAsFixed(2)}",
          0,
        );
        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty) {
          final nomesAcompanhamentos = item.acompanhamentos!.map((a) => a.nome).join(', ');
          printer.printCustom("  Acomp: $nomesAcompanhamentos", 0, 0);
        }
        if (item.observacao?.isNotEmpty ?? false) {
          printer.printCustom("  Obs: ${item.observacao}", 0, 0);
        }
      }

      printer.printNewLine();
      printer.printCustom("Total: R\$ ${pedido!.total.toStringAsFixed(2)}", 2, 2);
      printer.printCustom("Status: ${pedido!.status}", 1, 1);
      printer.printNewLine();
      printer.printQRcode("https://meuapp.com/pedido/${pedido!.id}", 200, 200, 1);
      printer.printNewLine();
      printer.paperCut();

      // Atualiza status
      await _firestore.collection('pedidos').doc(pedidoId)
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