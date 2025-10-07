// concluicao_pedido_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/conclusao_pedido/controller/conclusao_pedido_controller.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/carrinho_item_card.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/endereco_card.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/pagamento_selector.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:padariavinhos/helpers/pedido_validador.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/pedido_minimo_widget.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/cupom_input.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/sugestoes_tab.dart';

class ConclusaoPedidoPage extends StatelessWidget {
  const ConclusaoPedidoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConclusaoPedidoController()
        ..carregarAcompanhamentos()
        ..carregarSugestoes(),
      child: const _ConclusaoPedidoPageBody(),
    );
  }
}

class _ConclusaoPedidoPageBody extends StatelessWidget {
  const _ConclusaoPedidoPageBody();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConclusaoPedidoController>(context);
    final carrinho = Provider.of<CarrinhoProvider>(context);
    final authNotifier = Provider.of<AuthNotifier>(context);
    final user = authNotifier.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pedidoPreview = Pedido(
      id: '',
      numeroPedido: 0,
      userId: user.uid,
      nomeUsuario: user.nome,
      telefone: user.telefone,
      itens: carrinho.itens,
      status: 'preview',
      data: DateTime.now(),
      impresso: false,
      endereco: controller.tipoEntrega == TipoEntrega.entrega
          ? user.enderecoFormatado
          : null,
      formaPagamento: [controller.formaPagamento],
      frete: controller.frete,
      tipoEntrega: controller.tipoEntrega.name,
      dataHoraEntrega: controller.dataHoraEntrega,
      cupomAplicado: controller.cupomAplicado,
    );

    final valorTotal = pedidoPreview.totalFinal;

    // valida alcance só para entrega
    final dentroAlcance = controller.tipoEntrega == TipoEntrega.entrega
        ? PedidoValidador.validarAlcance(
      user.latitude,
      user.longitude,
    )
        : true;

    // pedido válido se atende valor mínimo e alcance
    final pedidoOk = controller.tipoEntrega == TipoEntrega.entrega
        ? (PedidoValidador.validarValor(valorTotal) && dentroAlcance)
        : true;

    return Scaffold(
      backgroundColor: Colors.black45,
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SafeArea(
        child: carrinho.itens.isEmpty
            ? const Center(
          child: Text(
            'Seu carrinho está vazio.',
            style: TextStyle(color: Colors.white),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
              const SizedBox(height: 16),
              controller.buildTipoEntrega(context),
              const SizedBox(height: 16),
              EnderecoCard(
                endereco: user.enderecoFormatado,
                goToPath: '/opcoes',
              ),
              const SizedBox(height: 8),

              if (controller.tipoEntrega == TipoEntrega.entrega && !dentroAlcance)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.red, width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seu endereço pode estar fora da área de entrega '
                              '(${PedidoValidador.alcanceKm.toStringAsFixed(1)} km).',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              /// 🔹 SUGESTÕES
              const Text(
                "Sugestões para você",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SugestoesTab(
                sugestoes: controller.sugestoesProdutos,
                acompanhamentosDisponiveis: controller.acompanhamentos,
              ),
              const SizedBox(height: 16),
              PagamentoSelector(controller: controller,carrinho: Provider.of<CarrinhoProvider>(context)),
              const SizedBox(height: 16),
              const Text(
                'Itens do Carrinho',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: carrinho.itens.length,
                itemBuilder: (context, index) {
                  final item = carrinho.itens[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: CarrinhoItemCard(
                      item: item,
                      index: index,
                      carrinho: carrinho,
                      controller: controller,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const CupomInput(),
              const SizedBox(height: 16),
              _buildTotais(pedidoPreview),
              const SizedBox(height: 16),
              if (controller.tipoEntrega == TipoEntrega.entrega &&
                  !PedidoValidador.validarValor(valorTotal))
                PedidoMinimoAviso(
                  valorMinimo: PedidoValidador.valorMinimo,
                  tipoEntrega: controller.tipoEntrega,
                ),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pedidoOk
                        ? Colors.deepOrangeAccent.withOpacity(0.95)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: controller.isLoading || !pedidoOk
                      ? null
                      : () => controller.finalizarPedido(
                    context,
                    carrinho,
                    authNotifier,
                  ),
                  child: controller.isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    'Finalizar Pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotais(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          _buildTotalRow('Itens', pedido.subtotal),
          const SizedBox(height: 8),
          _buildTotalRow('Frete', pedido.frete),
          if (pedido.cupomAplicado != null) ...[
            const Divider(color: Colors.black),
            _buildTotalRow(
              'Desconto (${pedido.cupomAplicado!.codigo})',
              (pedido.subtotal + pedido.frete) - pedido.totalFinal,
              valueColor: Colors.red,
            ),
          ],
          const Divider(color: Colors.black),
          _buildTotalRow(
            'Total',
            pedido.totalFinal,
            isBold: true,
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
      String label,
      double value, {
        bool isBold = false,
        Color valueColor = Colors.black,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}