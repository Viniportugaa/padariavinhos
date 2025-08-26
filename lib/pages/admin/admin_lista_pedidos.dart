import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/widgets/pedido_card.dart';

class ListaPedidosPage extends StatefulWidget {
  const ListaPedidosPage({super.key});

  @override
  State<ListaPedidosPage> createState() => _ListaPedidosPageState();
}

class _ListaPedidosPageState extends State<ListaPedidosPage> {
  String filtro = 'hoje';
  final printer = BlueThermalPrinter.instance;

  Future<User> _buscarUsuario(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception("Usuário não encontrado");
    return User.fromMap(doc.data()!);
  }

  Future<void> _imprimirPedido(Pedido pedido) async {
    try {
      print("Iniciando requisição de permissões...");
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      print("Permissões requisitadas:");
      statuses.forEach((permission, status) {
        print(" - $permission: $status");
      });

      if (statuses.values.any((status) => !status.isGranted)) {
        print("Permissões Bluetooth não concedidas.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões Bluetooth necessárias não concedidas.')),
        );
        return;
      }

      print("Buscando impressoras pareadas...");
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      print("Impressoras encontradas: ${devices.length}");

      if (devices.isEmpty) {
        print("Nenhuma impressora pareada encontrada.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma impressora pareada encontrada.')),
        );
        return;
      }

      BluetoothDevice selectedDevice = devices.first;
      print("Selecionando impressora: ${selectedDevice.name}");

      bool isConnected = await printer.isConnected ?? false;
      print("Estado inicial da conexão: $isConnected");

      if (!isConnected) {
        print("Tentando conectar à impressora...");
        await printer.connect(selectedDevice);
        await Future.delayed(const Duration(seconds: 2)); // um pouco mais de delay para garantir conexão
        isConnected = await printer.isConnected ?? false;
        print("Estado da conexão após tentar conectar: $isConnected");

        if (!isConnected) {
          throw Exception("Falha ao conectar à impressora.");
        }
      } else {
        print("Já conectado à impressora.");
      }
      User usuario = await _buscarUsuario(pedido.userId); // ajuste o campo uidUsuario conforme seu model Pedido

      String enderecoCompleto = "${usuario.endereco}, Nº ${usuario.numeroEndereco}";

      if (usuario.tipoResidencia == "apartamento" &&
          usuario.ramalApartamento != null &&
          usuario.ramalApartamento!.isNotEmpty) {
        enderecoCompleto += ", Ap. ${usuario.ramalApartamento}";
      }

      enderecoCompleto += " - CEP: ${usuario.cep}";

      print("Iniciando impressao do pedido ${pedido.id}...");
      printer.printNewLine();
      printer.printCustom("PADARIA", 3, 1);
      printer.printCustom("Pedido nº ${pedido.numeroPedido}", 2, 0);
      printer.printNewLine();
      printer.printLeftRight("Cliente:", pedido.nomeUsuario, 1);
      printer.printLeftRight("Telefone:", pedido.telefone, 1);
      printer.printCustom("Endereço:", 1, 0);
      printer.printCustom(enderecoCompleto, 0, 0);
      printer.printLeftRight("Data:", DateFormat('dd/MM/yyyy HH:mm').format(pedido.data.toLocal()), 1);
      printer.printNewLine();

      printer.printCustom("Itens:", 1, 0);
      for (var item in pedido.itens) {
        printer.printLeftRight(
          "${item.quantidade}x ${item.produto.nome}",
          "R\$ ${item.subtotal.toStringAsFixed(2)}",
          0,
        );
        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty) {
          final nomesAcompanhamentos = item.acompanhamentos!
              .map((a) => a.nome)
              .join(', ');
          printer.printCustom("  Acomp: $nomesAcompanhamentos", 0, 0);
        }
        if (item.observacao?.isNotEmpty ?? false) {
          printer.printCustom("  Obs: ${item.observacao}", 0, 0);
        }
      }

      printer.printNewLine();
      printer.printCustom("Total: R\$ ${pedido.total.toStringAsFixed(2)}", 2, 2);
      printer.printCustom("Status: ${pedido.status}", 1, 1);
      printer.printNewLine();
      printer.printQRcode("https://meuapp.com/pedido/${pedido.id}", 200, 200, 1);
      printer.printNewLine();
      printer.paperCut();

      print("Impressão finalizada, atualizando status no Firestore...");
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedido.id)
          .update({'status': 'em preparo', 'impresso': true});

      print("Status atualizado com sucesso.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impressão realizada com sucesso!')),
      );
      await Future.delayed(const Duration(seconds: 5));
    } catch (e, stackTrace) {
      print("Erro ao imprimir: $e");
      print("StackTrace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao imprimir: $e')),
      );
    }
  }

  Future<void> _editarPedido(Pedido pedido) async {
    if (pedido.status != 'finalizado') {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedido.id)
          .update({'status': 'em preparo'});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido finalizado não pode ser editado.')),
      );
    }
  }
  void _finalizarPedido(Pedido pedido) async {
    if (pedido.impresso == true){
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedido.id)
          .update({'status': 'finalizado'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido finalizado com sucesssssoooo!')),
      );
    }
  }

  Stream<QuerySnapshot> _pedidosStream() {
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));

    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .orderBy('data', descending: true);

    if (filtro == 'hoje') {
      final inicio = DateTime(hoje.year, hoje.month, hoje.day);
      final fim = inicio.add(Duration(days: 1));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    }
    if (filtro == 'semana') {
      final inicio = DateTime(hoje.year, hoje.month, hoje.day - (hoje.weekday - 1));
      final fim = inicio.add(const Duration(days: 7));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    }


    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Pedidos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => filtro = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'hoje', child: Text('Hoje')),
              const PopupMenuItem(value: 'semana', child: Text('Essa Semana')),
              const PopupMenuItem(value: 'todos', child: Text('Todos')),
            ],
          )
        ],
      ),
      body: StreamBuilder(
        stream: _pedidosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum pedido encontrado.'));
          }

          final pedidos = snapshot.data!.docs
              .map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return PedidoCard(
                pedido: pedido,
                onImprimir: () => _imprimirPedido(pedido),
                onEditar: () => _editarPedido(pedido),
                onFinalizar: () => _finalizarPedido(pedido),
              );
            },
          );
        },
      ),
    );
  }
}