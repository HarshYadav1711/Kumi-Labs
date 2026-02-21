import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Base URLs for backend services. Use 10.0.2.2 for Android emulator, localhost for iOS simulator.
const String _baseUsers = 'http://10.0.2.2:8000';
const String _baseCatalog = 'http://10.0.2.2:8001';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  /// POST /register -> { access_token }
  Future<String> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final uri = Uri.parse('$_baseUsers/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );
    if (response.statusCode != 200) {
      final body = response.body;
      String msg = 'Registration failed';
      try {
        final m = jsonDecode(body) as Map<String, dynamic>;
        if (m['detail'] != null) msg = m['detail'].toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null) throw ApiException('No token in response');
    return token;
  }

  /// POST /login -> { access_token }
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUsers/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      final body = response.body;
      String msg = 'Login failed';
      try {
        final m = jsonDecode(body) as Map<String, dynamic>;
        if (m['detail'] != null) msg = m['detail'].toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null) throw ApiException('No token in response');
    return token;
  }

  /// GET /products -> List<Product>
  Future<List<Product>> getProducts() async {
    final uri = Uri.parse('$_baseCatalog/products');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw ApiException('Failed to load products', response.statusCode);
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }
}
