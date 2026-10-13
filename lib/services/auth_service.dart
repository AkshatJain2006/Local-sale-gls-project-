import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash; // stored as plain for simplicity (no sensitive data)
  final String role; // 'admin' | 'staff' | 'manager' | 'cashier'
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    bool? isActive,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role,
        'isActive': isActive,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        passwordHash: j['passwordHash'] as String,
        role: j['role'] as String,
        isActive: j['isActive'] as bool? ?? true,
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _kUsers = 'auth_users';

  List<AppUser> _users = [];
  List<AppUser> get users => List.unmodifiable(_users);

  bool get hasAdmin => _users.any((u) => u.role == 'admin');
  List<AppUser> get staffOnly =>
      _users.where((u) => u.role != 'admin').toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsers);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _users = list
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kUsers, jsonEncode(_users.map((u) => u.toJson()).toList()));
  }

  /// Returns null on success, error string on failure.
  Future<String?> createAdmin(
      String name, String email, String password) async {
    if (name.trim().isEmpty) return 'Name is required.';
    if (email.trim().isEmpty) return 'Email is required.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'An account with this email already exists.';
    }
    _users.add(AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: password,
      role: 'admin',
    ));
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (name.trim().isEmpty) return 'Name is required.';
    if (email.trim().isEmpty) return 'Email is required.';
    if (password.length < 4) return 'Password must be at least 4 characters.';
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'An account with this email already exists.';
    }
    _users.add(AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: password,
      role: role,
    ));
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> updateUser(AppUser updated) async {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) {
      _users[idx] = updated;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    await _persist();
    notifyListeners();
  }

  /// Returns the matching user or null.
  AppUser? login(String email, String password) {
    try {
      return _users.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.trim().toLowerCase() &&
            u.passwordHash == password &&
            u.isActive,
      );
    } catch (_) {
      return null;
    }
  }
}
