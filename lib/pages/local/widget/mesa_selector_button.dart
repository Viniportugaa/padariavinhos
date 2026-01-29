import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/provider/provider_local/pedido_local_provider.dart';

class MesaSelectorButton extends StatelessWidget {
  const MesaSelectorButton({super.key});

  void _abrirSelecionarMesaSheet(BuildContext context) {
    final pedidoProvider = context.read<PedidoLocalProvider>();
    String? mesaSelecionada = pedidoProvider.mesaAtual;

    Future<void> pedirSenhaParaTrocarMesa(String novaMesa) async {
      final controller = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Alterar Mesa"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Digite a senha para mudar a mesa:"),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Senha",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text == "123456") {
                    Navigator.pop(context, true);
                  } else {
                    Navigator.pop(context, false);
                  }
                },
                child: const Text("Confirmar"),
              ),
            ],
          );
        },
      );

      if (result == true) {
        pedidoProvider.definirMesa(novaMesa);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Senha incorreta"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          final List<String> mesas = List.generate(21, (i) => '${i + 1}');
          const double mesaSize = 60;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    'Selecione sua Mesa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: mesas.map((mesa) {
                      final isSelected = mesaSelecionada == mesa;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            mesaSelecionada = mesa;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: mesaSize,
                          height: mesaSize,
                          decoration: BoxDecoration(
                            color:
                            isSelected ? Colors.brown[400] : Colors.brown[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.brown.shade700
                                  : Colors.brown.shade300,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              mesa,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.brown[800],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: mesaSelecionada == null
                        ? null
                        : () async {
                      final mesaAtual = pedidoProvider.mesaAtual;

                      // Se não existe mesa → define direto
                      if (mesaAtual == null) {
                        pedidoProvider.definirMesa(mesaSelecionada!);
                        Navigator.pop(context);
                        return;
                      }

                      // Se é a mesma mesa → nada muda
                      if (mesaAtual == mesaSelecionada) {
                        Navigator.pop(context);
                        return;
                      }

                      // Se tentar mudar → pedir senha
                      await pedirSenhaParaTrocarMesa(mesaSelecionada!);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = context.watch<PedidoLocalProvider>();
    final mesa = pedido.mesaAtual;

    return GestureDetector(
      onTap: () => _abrirSelecionarMesaSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: mesa != null ? Colors.green[600] : Colors.orange[600],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_bar, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              mesa != null ? "Mesa $mesa" : "Selecionar Mesa",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
