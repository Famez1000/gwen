import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class GwynSecureStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class FlutterSecureGwynStore implements GwynSecureStore {
  FlutterSecureGwynStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _storageKey = 'gwyn_ai_memory_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _storageKey);

  @override
  Future<void> write(String value) {
    return _storage.write(key: _storageKey, value: value);
  }

  @override
  Future<void> delete() => _storage.delete(key: _storageKey);
}
