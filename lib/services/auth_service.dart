import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService;
  final FlutterSecureStorage _secureStorage;
  final _uuid = const Uuid();
  static const String _userIdKey = 'user_id';

  AuthService(this._storageService, this._secureStorage);

  Future<User?> getCurrentUser() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      if (userId == null) return null;

      final users = await _storageService.getUsers();
      try {
        return users.firstWhere((u) => u.id == userId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final users = await _storageService.getUsers();
      if (users.any((user) => user.email == email)) {
        return false; // Email already exists
      }

      final user = User(
        id: _uuid.v4(),
        username: username,
        email: email,
        password: password, // In a real app, this should be hashed
      );

      await _storageService.saveUser(user);
      await _secureStorage.write(key: _userIdKey, value: user.id);
      return true;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final users = await _storageService.getUsers();
      try {
        final user = users.firstWhere(
          (u) => u.email == email && u.password == password,
        );
        await _secureStorage.write(key: _userIdKey, value: user.id);
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _userIdKey);
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
} 