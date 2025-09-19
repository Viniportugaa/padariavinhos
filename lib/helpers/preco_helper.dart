import '../models/produto.dart';
import '../models/acompanhamento.dart';

class PrecoHelper {
  /// Calcula o preço unitário de um produto com acompanhamentos selecionados
  static double calcularPrecoUnitario({
    required Produto produto,
    required List<Acompanhamento> selecionados,
  }) {
    double precoBase = produto.preco;

    if (produto.category.toLowerCase() == 'prato' && selecionados.length > 3) {
      // Somar apenas os adicionais (após os 3 primeiros)
      final adicionais = List<Acompanhamento>.from(selecionados.sublist(3));
      adicionais.sort((a, b) => a.preco.compareTo(b.preco));
      for (final a in adicionais) {
        precoBase += a.preco;
      }
    } else if (produto.category.toLowerCase() != 'prato') {
      // Para outras categorias, soma todos os selecionados
      precoBase += selecionados.fold(0.0, (soma, a) => soma + a.preco);
    }

    return precoBase;
  }
}
