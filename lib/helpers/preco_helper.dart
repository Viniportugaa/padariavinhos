import '../models/produto.dart';
import '../models/acompanhamento.dart';

class PrecoHelper {
  static double calcularPrecoUnitario({
    required Produto produto,
    List<Acompanhamento>? selecionados,
  }) {
    double precoBase = produto.preco;
    if (selecionados == null || selecionados.isEmpty) return precoBase;

    if (produto.category.toLowerCase() == 'pratos') {
      if (selecionados.length <= 3) return precoBase;

      // Número de acompanhamentos a cobrar
      final numeroACobrar = selecionados.length - 3;

      // Ordena todos os preços do menor para o maior
      final precosOrdenados = selecionados.map((a) => a.preco).toList()
        ..sort();

      // Soma os menores valores correspondentes ao número a cobrar
      final valorAcomp = precosOrdenados.take(numeroACobrar).fold(
          0.0, (s, v) => s + v);

      return precoBase + valorAcomp;
    } else {
      // Outras categorias: soma todos
      final valorAcomp = selecionados.fold(0.0, (s, a) => s + a.preco);
      return precoBase + valorAcomp;
    }
  }

  static double precoAcompanhamentoCobrado({
    required Produto produto,
    required List<Acompanhamento> selecionados,
    required int index,
  }) {
    if (produto.category.toLowerCase() != 'pratos') {
      return selecionados[index].preco; // sempre cobra
    }

    if (index < 3) return 0.0; // primeiros 3 grátis

    // Quantos devem ser cobrados
    final numeroACobrar = selecionados.length - 3;

    // Lista de preços ordenados
    final precosOrdenados = selecionados.map((a) => a.preco).toList()
      ..sort();

    // Menores valores que serão cobrados
    final valoresACobrar = precosOrdenados.take(numeroACobrar).toList();

    // Copiamos a lista de cobrados para consumir valores à medida que são usados
    final cobradosRestantes = List<double>.from(valoresACobrar);

    final precoAtual = selecionados[index].preco;

    if (cobradosRestantes.contains(precoAtual)) {
      cobradosRestantes.remove(precoAtual); // consome um preço igual
      return precoAtual;
    }

    return 0.0;
  }
}