enum ProductCategory {
  wine('Vini'),
  beer('Birre'),
  cocktail('Cocktail'),
  coffee('Caffè e tè'),
  softDrink('Analcolici'),
  food('Gastronomia');

  const ProductCategory(this.label);

  final String label;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.format,
    this.isNew = false,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final double price;
  final String imageUrl;

  /// Package size, e.g. `75 cl` or `500 g`.
  final String format;

  final bool isNew;
  final bool isPopular;
}
