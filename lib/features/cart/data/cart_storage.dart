import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the cart is kept between launches (F1): the device's shared
/// preferences, as JSON. Tests use [MemoryCartStorage].
abstract interface class CartStorage {
  Future<Map<String, Object?>?> read();
  Future<void> write(Map<String, Object?>? cart);
}

class PreferencesCartStorage implements CartStorage {
  const PreferencesCartStorage();

  static const _key = 'cart_v1';

  @override
  Future<Map<String, Object?>?> read() async {
    try {
      final text = (await SharedPreferences.getInstance()).getString(_key);
      return text == null ? null : jsonDecode(text) as Map<String, Object?>;
    } on Object catch (error) {
      // A cart that can't be read is dropped rather than blocking the app.
      debugPrint('Cart not restored: $error');
      return null;
    }
  }

  @override
  Future<void> write(Map<String, Object?>? cart) async {
    final prefs = await SharedPreferences.getInstance();
    if (cart == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(cart));
    }
  }
}

class MemoryCartStorage implements CartStorage {
  MemoryCartStorage([this.saved]);

  Map<String, Object?>? saved;

  @override
  Future<Map<String, Object?>?> read() async => saved;

  @override
  Future<void> write(Map<String, Object?>? cart) async => saved = cart == null
      ? null
      : jsonDecode(jsonEncode(cart)) as Map<String, Object?>;
}
