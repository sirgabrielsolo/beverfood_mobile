import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/products/models/catalog.dart';

/// The catalogue from beverfood_web's API.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  /// Every product, the categories and the popular and new orders, in one
  /// request (~30 KB gzipped). Throws [ApiException] when the server can't
  /// be reached.
  Future<Catalog> load() async {
    final json = await _api.getJson('/api/v1/catalog');
    return Catalog.fromApi(json! as Map<String, Object?>);
  }
}

enum CatalogStatus { loading, loaded, failed }

/// Holds the [Catalog] that Home and Prodotti show. `BeverfoodApp` loads it
/// once signed in, and again when the app returns to the foreground after
/// [staleAfter], so prices stay current. A failed reload keeps the catalogue
/// already shown.
class CatalogController extends ChangeNotifier {
  CatalogController(this._repository);

  final CatalogRepository _repository;

  static const staleAfter = Duration(minutes: 5);

  Catalog? _catalog;
  var _status = CatalogStatus.loading;
  DateTime? _loadedAt;
  Future<void>? _loading;

  /// Null until the first load succeeds.
  Catalog? get catalog => _catalog;

  /// `failed` only when there is no catalogue to show.
  CatalogStatus get status => _status;

  /// Loads the catalogue; a load already running is shared.
  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    if (_catalog == null && _status != CatalogStatus.loading) {
      _status = CatalogStatus.loading;
      notifyListeners();
    }
    try {
      _catalog = await _repository.load();
      _loadedAt = DateTime.now();
      _status = CatalogStatus.loaded;
    } on Exception catch (error) {
      debugPrint('Catalog not loaded: $error');
      if (_catalog == null) _status = CatalogStatus.failed;
    }
    notifyListeners();
  }

  /// Reloads when the catalogue is older than [staleAfter] (or missing).
  void refreshIfStale() {
    final loadedAt = _loadedAt;
    if (loadedAt == null || DateTime.now().difference(loadedAt) > staleAfter) {
      load();
    }
  }

  /// Forgets the catalogue, e.g. on sign-out.
  void clear() {
    _catalog = null;
    _loadedAt = null;
    _status = CatalogStatus.loading;
    notifyListeners();
  }
}

/// Exposes the app's [CatalogController]; `BeverfoodApp` owns it. Widgets
/// that read it with [of] rebuild when the catalogue changes.
class CatalogScope extends InheritedNotifier<CatalogController> {
  const CatalogScope({
    super.key,
    required CatalogController controller,
    required super.child,
  }) : super(notifier: controller);

  static CatalogController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CatalogScope>()!.notifier!;

  /// Without listening, for callbacks.
  static CatalogController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CatalogScope>()!.notifier!;
}
