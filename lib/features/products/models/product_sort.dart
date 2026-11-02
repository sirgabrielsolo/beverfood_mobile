/// Orderings offered by the "Filtra e ordina" sheet on Prodotti.
enum ProductSort {
  /// Catalogue order (new arrivals first).
  recommended('Consigliati'),
  popular('Più popolari'),
  priceAscending('Prezzo crescente'),
  priceDescending('Prezzo decrescente'),
  name('Nome (A-Z)');

  const ProductSort(this.label);

  final String label;
}
