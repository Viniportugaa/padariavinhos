import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/cupom.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PedidoService {
  final CollectionReference _pedidosRef =
  FirebaseFirestore.instance.collection('pedidos');
  final DocumentReference _contadorRef =
  FirebaseFirestore.instance.collection('contadores').doc('pedidoCounter');
  final CollectionReference _cuponsRef =
  FirebaseFirestore.instance.collection('cupons');

  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  Future<int> getNextNumeroPedido() async {
    return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_contadorRef);
      int current = snapshot.exists ? (snapshot.get('current') as int) : 0;
      final next = current + 1;
      transaction.set(_contadorRef, {'current': next});
      return next;
    });
  }

  Stream<List<Pedido>> streamPedidosUsuario(String userId) {
    return _pedidosRef
        .where('userId', isEqualTo: userId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> criarPedido(
      Pedido pedido, {
        DateTime? dataEntrega,
        TimeOfDay? horaEntrega,
      }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final contadorSnapshot = await transaction.get(_contadorRef);
        int current =
        contadorSnapshot.exists ? (contadorSnapshot.get('current') as int) : 0;
        final next = current + 1;
        transaction.set(_contadorRef, {'current': next});

        final docRef = _pedidosRef.doc();

        DateTime? dataHoraEntrega;
        if (dataEntrega != null && horaEntrega != null) {
          dataHoraEntrega = DateTime(
            dataEntrega.year,
            dataEntrega.month,
            dataEntrega.day,
            horaEntrega.hour,
            horaEntrega.minute,
          );
        } else {
          dataHoraEntrega = pedido.dataHoraEntrega;
        }

        final uid = auth.FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) throw Exception("Usuário não autenticado");

        final pedidoComId = Pedido(
          id: docRef.id,
          numeroPedido: next,
          userId: uid,
          nomeUsuario: pedido.nomeUsuario,
          telefone: pedido.telefone,
          itens: pedido.itens,
          status: pedido.status,
          data: pedido.data,
          impresso: pedido.impresso,
          endereco: pedido.endereco,
          formaPagamento: pedido.formaPagamento,
          frete: pedido.frete,
          totalFinal: pedido.totalFinal,
          tipoEntrega: pedido.tipoEntrega,
          dataHoraEntrega: dataHoraEntrega,
          cupomAplicado: pedido.cupomAplicado,
          valorPago: pedido.valorPago,
          troco: pedido.troco,
        );

        transaction.set(docRef, pedidoComId.toMap());

        if (pedido.cupomAplicado != null) {
          final cupom = pedido.cupomAplicado!;
          final cupomRef = _cuponsRef.doc(cupom.id);
          transaction.update(cupomRef, {
            'usuariosUsaram': FieldValue.arrayUnion([uid]),
          });
        }
      });
    } catch (e, stack) {
      debugPrint("❌ Erro ao criar pedido: $e");
      debugPrint("📌 Stack trace: $stack");
      throw Exception("Erro ao criar pedido: $e");
    }
  }

  Future<void> ajustarValorPedido(String pedidoId, double novoValor) async {
    await _pedidosRef.doc(pedidoId).update({
      'totalFinal': novoValor,
      'valorAjustado': true,
    });
  }

  // 🔹 Impressão movida do Provider para cá
  Future<void> imprimirPedido(
      Pedido pedido,
      User usuario,
      BuildContext context,
      ) async {
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
      printer.printCustom("DATA ${pedido.dataHoraEntrega}", 2, 0);
      printer.printNewLine();
      printer.printLeftRight("Cliente:", pedido.nomeUsuario, 1);
      printer.printLeftRight("Telefone:", pedido.telefone, 1);
      printer.printCustom("Endereço:", 1, 0);
      printer.printCustom(enderecoCompleto, 0, 0);
      printer.printLeftRight(
          "Data:", DateFormat('dd/MM/yyyy HH:mm').format(pedido.data.toLocal()), 1);
      printer.printNewLine();

      printer.printCustom("Itens:", 1, 0);
      for (var item in pedido.itens) {
        final prefixo = item.produto.vendidoPorPeso
            ? "${item.quantidade.toStringAsFixed(2)}/Kg"
            : "${item.quantidade}x";
        final subtotalItem = item.subtotal;

        printer.printLeftRight(
            "$prefixo ${item.produto.nome}", "R\$ ${subtotalItem.toStringAsFixed(2)}", 0);

        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty) {
          final nomesAcomp = item.acompanhamentos!.map((a) => a.nome).join(', ');
          printer.printCustom("  Acomp: $nomesAcomp", 0, 0);
        }

        if (item.observacao?.isNotEmpty ?? false) {
          printer.printCustom("  Obs: ${item.observacao}", 0, 0);
        }
      }

      printer.printNewLine();
      printer.printLeftRight("Subtotal:",
          "R\$ ${pedido.subtotal.toStringAsFixed(2)}", 1);
      printer.printLeftRight("Frete:",
          "R\$ ${pedido.frete.toStringAsFixed(2)}", 1);
      printer.printCustom("Total: R\$ ${pedido.totalFinal.toStringAsFixed(2)}",
          2, 2);
      printer.printCustom("Status: ${pedido.status}", 1, 1);
      printer.printNewLine();
      printer.printQRcode("https://meuapp.com/pedido/${pedido.id}", 200, 200, 1);
      printer.printNewLine();
      printer.paperCut();

      pedido.status = 'em preparo';
      pedido.impresso = true;

      await _pedidosRef.doc(pedido.id).update({
        'status': 'em preparo',
        'impresso': true,
        'totalFinal': pedido.totalFinal,
      });

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
