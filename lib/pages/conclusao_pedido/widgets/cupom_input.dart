import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/conclusao_pedido/controller/conclusao_pedido_controller.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';

class CupomInput extends StatefulWidget {
  const CupomInput({super.key});

  @override
  State<CupomInput> createState() => _CupomInputState();
}

class _CupomInputState extends State<CupomInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConclusaoPedidoController>(context);
    final auth = Provider.of<AuthNotifier>(context);
    final user = auth.user;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cupom de Desconto",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),

          // Campo de texto + botão aplicar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Digite seu cupom",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrangeAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (user == null) return;
                  final code = _controller.text.trim();
                  if (code.isEmpty) return;

                  await controller.aplicarCupom(code, user.uid);
                  if (controller.cupomAplicado != null) {
                    _controller.clear();
                  }
                },
                child: const Text(
                  "Aplicar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),

          // Mostra erro
          if (controller.erroCupom != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                controller.erroCupom!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),

          // Mostra cupom aplicado
          if (controller.cupomAplicado != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cupom "${controller.cupomAplicado!.codigo}" aplicado! '
                          '${controller.cupomAplicado!.percentual ? '${controller.cupomAplicado!.desconto}% OFF' : 'R\$ ${controller.cupomAplicado!.desconto.toStringAsFixed(2)} de desconto'}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.removerCupom();
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
