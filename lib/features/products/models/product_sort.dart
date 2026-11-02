/// Orderings offered by the "Filtra e ordina" sheet on Prodotti. The first
/// is the default.
enum ProductSort {
  /// Most ordered first (the agents' ranking), then by name.
  popular('Più popolari'),
  priceAscending('Prezzo crescente'),
  priceDescending('Prezzo decrescente'),
  name('Nome (A-Z)');

  const ProductSort(this.label);

  final String label;
}
