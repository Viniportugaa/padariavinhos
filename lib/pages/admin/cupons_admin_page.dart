import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/cupom.dart';

class CuponsAdminPage extends StatefulWidget {
  const CuponsAdminPage({Key? key}) : super(key: key);

  @override
  State<CuponsAdminPage> createState() => _CuponsAdminPageState();
}

class _CuponsAdminPageState extends State<CuponsAdminPage> {
  final _db = FirebaseFirestore.instance;

  Future<void> _mostrarDialogCupom({Cupom? cupom}) async {
    final codigoController = TextEditingController(text: cupom?.codigo ?? '');
    final descontoController = TextEditingController(
        text: cupom?.desconto.toString() ?? '0');
    final isPercentual = ValueNotifier<bool>(cupom?.percentual ?? false);
    final validade = ValueNotifier<DateTime>(
      cupom?.validade ?? DateTime.now().add(const Duration(days: 7)),
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cupom == null ? 'Novo Cupom' : 'Editar Cupom'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
              ),
              TextField(
                controller: descontoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Desconto'),
              ),
              ValueListenableBuilder(
                valueListenable: isPercentual,
                builder: (_, value, __) => SwitchListTile(
                  title: const Text('É Percentual?'),
                  value: value,
                  onChanged: (val) => isPercentual.value = val,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: validade,
                builder: (_, date, __) => ListTile(
                  title: Text(
                      'Validade: ${date.day}/${date.month}/${date.year}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) validade.value = picked;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final newCupom = {
                'codigo': codigoController.text.trim().toUpperCase(),
                'desconto':
                double.tryParse(descontoController.text) ?? 0.0,
                'percentual': isPercentual.value,
                'validade': Timestamp.fromDate(validade.value),
                'ativo': true,
                'usuariosUsaram': cupom?.usuariosUsaram ?? [],
              };

              if (cupom == null) {
                await _db.collection('cupons').add(newCupom);
              } else {
                await _db.collection('cupons').doc(cupom.id).update(newCupom);
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCupom(String id) async {
    await _db.collection('cupons').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Cupons"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarDialogCupom(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('cupons').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Nenhum cupom cadastrado"));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final cupom = Cupom.fromMap(data, docs[index].id);

              return ListTile(
                title: Text("${cupom.codigo} - ${cupom.percentual ? "${cupom.desconto}%" : "R\$ ${cupom.desconto.toStringAsFixed(2)}"}"),
                subtitle: Text(
                    "Validade: ${cupom.validade.day}/${cupom.validade.month}/${cupom.validade.year}\nAtivo: ${cupom.ativo ? 'Sim' : 'Não'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarDialogCupom(cupom: cupom)),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _excluirCupom(cupom.id)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
