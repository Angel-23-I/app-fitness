import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/food_models.dart';
import 'gemini_food_analyzer.dart';

/// Where the Gemini API key lives. It is never written to the database, code or git.
abstract class ApiKeyStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> delete();
}

class SecureApiKeyStore implements ApiKeyStore {
  static const _k = 'gemini_api_key';
  final _s = const FlutterSecureStorage();

  @override
  Future<String?> read() => _s.read(key: _k);
  @override
  Future<void> write(String key) => _s.write(key: _k, value: key);
  @override
  Future<void> delete() => _s.delete(key: _k);
}

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => SecureApiKeyStore());

class ApiKeyNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final k = await ref.watch(apiKeyStoreProvider).read();
    return (k == null || k.trim().isEmpty) ? null : k.trim();
  }

  Future<void> save(String key) async {
    await ref.read(apiKeyStoreProvider).write(key.trim());
    state = AsyncData(key.trim());
  }

  Future<void> clear() async {
    await ref.read(apiKeyStoreProvider).delete();
    state = const AsyncData(null);
  }
}

final apiKeyProvider = AsyncNotifierProvider<ApiKeyNotifier, String?>(ApiKeyNotifier.new);

/// Null when no API key is configured (feature disabled).
final foodAnalyzerProvider = Provider<FoodAnalyzer?>((ref) {
  final key = ref.watch(apiKeyProvider).value;
  return key == null ? null : GeminiFoodAnalyzer(apiKey: key);
});
