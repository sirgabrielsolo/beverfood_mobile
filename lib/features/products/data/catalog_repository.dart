import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';

/// Products from beverfood_web's API. Today only Novità; Più popolari and the
/// full catalogue follow, replacing the sample `ProductRepository`.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  /// Products flagged new (the web app's NOVITÀ), newest first. Throws
  /// [ApiException] when the server can't be reached.
  Future<List<Product>> newProducts() async {
    final json = await _api.getJson('/api/v1/products/new');
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
