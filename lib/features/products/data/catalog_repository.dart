import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';

/// Products from beverfood_web's API: Novità and Più popolari. The full
/// catalogue follows, replacing the sample `ProductRepository`.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  /// Products flagged new (the web app's NOVITÀ), newest first. Throws
  /// [ApiException] when the server can't be reached.
  Future<List<Product>> newProducts() => _products('/api/v1/products/new');

  /// The [limit] most ordered products (the web app's popularity ranking,
  /// promos left out), most popular first. Throws [ApiException] when the
  /// server can't be reached.
  Future<List<Product>> popularProducts({int limit = 20}) =>
      _products('/api/v1/products/popular?limit=$limit');

  Future<List<Product>> _products(String path) async {
    final json = await _api.getJson(path);
    return [
      for (final p in (json! as Map<String, Object?>)['products'] as List)
        Product.fromApi(p as Map<String, Object?>),
    ];
  }
}

/// Exposes the app's [CatalogRepository]; `BeverfoodApp` owns it.
class CatalogScope extends InheritedWidget {
  const CatalogScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final CatalogRepository repository;

  static CatalogRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CatalogScope>()!.repository;

  @override
  bool updateShouldNotify(CatalogScope oldWidget) =>
      repository != oldWidget.repository;
}
