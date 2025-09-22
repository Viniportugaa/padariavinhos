import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/helpers/aberto_check.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/carrinho_item_card.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/pagamento_selector.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/endereco_card.dart';
import 'package:padariavinhos/pages/conclusao_pedido/controller/conclusao_pedido_controller.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/pedido_minimo_widget.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';

enum TipoEntrega { entrega, retirada, noLocal }

class ConclusaoPedidoPage extends StatelessWidget {
  const ConclusaoPedidoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConclusaoPedidoController()..carregarAcompanhamentos(),
      child: const _ConclusaoPedidoPageBody(),
    );
  }
}

bool pedidoValido(double total, {double minimo = 20}){
  return total >= minimo;
}

class _ConclusaoPedidoPageBody extends StatelessWidget {
  const _ConclusaoPedidoPageBody();

  @override
  Widget build(BuildContext context) {
    return AbertoChecker(
      child: Consumer<ConclusaoPedidoController>(
        builder: (context, controller, _) {
          final carrinho = Provider.of<CarrinhoProvider>(context);
          final authNotifier = Provider.of<AuthNotifier>(context);

          if (authNotifier.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authNotifier.user == null) {
            return const Scaffold(
              body: Center(child: Text('Erro ao carregar dados do usuário.')),
            );
          }

          final user = authNotifier.user!;
          final valorTotal = carrinho.total + controller.frete;
          const valorMinimo = 20.0;

          return Scaffold(
            backgroundColor: Colors.black45,
            appBar: AppBar(
              title: const Text('Confirmar Pedido'),
              backgroundColor: Colors.deepOrange,
              elevation: 2,
            ),
            body: SafeArea(
              child: carrinho.itens.isEmpty
                  ? const Center(
                child: Text(
                  'Seu carrinho está vazio.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voltar
                    ElevatedButton.icon(
                      onPressed: () => context.go('/pedido'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipo de entrega
                    controller.buildTipoEntrega(context),
                    const SizedBox(height: 16),

                    // Endereço do usuário
                    EnderecoCard(
                      endereco: user.enderecoFormatado,
                      goToPath: '/opcoes',
                    ),
                    const SizedBox(height: 16),

                    // Pagamento
                    PagamentoSelector(controller: controller),
                    const SizedBox(height: 16),

                    // Lista de itens
                    Text(
                      'Itens do Carrinho',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: carrinho.itens.length,
                      itemBuilder: (context, index) {
                        final item = carrinho.itens[index];
                        return _buildAnimatedItemCard(
                            item, index, carrinho, controller);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Totais
                    _buildTotais(carrinho, controller),
                    const SizedBox(height: 16),

                    // Aviso pedido mínimo
                    if (!pedidoValido(valorTotal, minimo: valorMinimo))
                      const PedidoMinimoAviso(valorMinimo: valorMinimo),

                    const SizedBox(height: 8),

                    // Botão finalizar pedido
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent
                              .withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: controller.isLoading ||
                            !pedidoValido(valorTotal,
                                minimo: valorMinimo)
                            ? null
                            : () =>
                            controller.finalizarPedido(
                                context, carrinho, authNotifier),
                        child: controller.isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  /// Cartão animado para cada item do carrinho
  Widget _buildAnimatedItemCard(item, int index, CarrinhoProvider carrinho,
      ConclusaoPedidoController controller) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 100),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: CarrinhoItemCard(
          item: item,
          index: index,
          carrinho: carrinho,
          controller: controller,
        ),
      ),
    );
  }

// Totais com glassmorphism
  Widget _buildTotais(CarrinhoProvider carrinho,
      ConclusaoPedidoController controller) {
    double totalItens = 0;

    // Calcula o total considerando a lógica de preço dos acompanhamentos
    for (var item in carrinho.itens) {
      final precoUnitario = PrecoHelper.calcularPrecoUnitario(
        produto: item.produto,
        selecionados: item.acompanhamentos ?? [],
      );
      totalItens += precoUnitario * item.quantidade;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          _buildTotalRow('Itens', totalItens),
          const SizedBox(height: 8),
          _buildTotalRow('Frete', controller.frete),
          const Divider(color: Colors.black),
          _buildTotalRow(
            'Total',
            totalItens + controller.frete,
            isBold: true,
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value,
      {bool isBold = false, Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
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