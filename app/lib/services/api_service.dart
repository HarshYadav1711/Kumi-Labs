import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/product.dart';

/// Base URLs. Use 10.0.2.2 for Android emulator, localhost for iOS simulator.
const String _baseUsers = 'http://10.0.2.2:8000';
const String _baseCatalog = 'http://10.0.2.2:8001';
const String _baseOrders = 'http://10.0.2.2:8002';
const String _baseDelivery = 'http://10.0.2.2:8003';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

final ApiService apiService = ApiService();

class ApiService {
  String? _token;
  String? _userId;

  void setToken(String? token) {
    _token = token;
  }

  void setUserId(String? userId) {
    _userId = userId;
  }

  void setAuth(String token, String userId) {
    _token = token;
    _userId = userId;
  }

  String? get userId => _userId;

  Map<String, String> _ordersHeaders() {
    final h = {'Content-Type': 'application/json'};
    if (_userId != null) h['X-User-Id'] = _userId!;
    return h;
  }

  void _throwFromBody(String body, int statusCode) {
    String msg = 'Request failed';
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      if (m['detail'] != null) msg = m['detail'].toString();
    } catch (_) {}
    throw ApiException(msg, statusCode);
  }

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
      _throwFromBody(response.body, response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null) throw ApiException('No token in response');
    return token;
  }

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
      _throwFromBody(response.body, response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null) throw ApiException('No token in response');
    return token;
  }

  Future<List<Product>> getProducts() async {
    final uri = Uri.parse('$_baseCatalog/products');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw ApiException('Failed to load products', response.statusCode);
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Cart> getCart() async {
    if (_userId == null) throw ApiException('Not logged in');
    final uri = Uri.parse('$_baseOrders/cart');
    final response = await http.get(uri, headers: _ordersHeaders());
    if (response.statusCode != 200) {
      _throwFromBody(response.body, response.statusCode);
    }
    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Cart> addToCart(String productId, {int quantity = 1}) async {
    if (_userId == null) throw ApiException('Not logged in');
    final uri = Uri.parse('$_baseOrders/cart/add');
    final response = await http.post(
      uri,
      headers: _ordersHeaders(),
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    if (response.statusCode != 200) {
      _throwFromBody(response.body, response.statusCode);
    }
    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Cart> removeFromCart(String productId) async {
    if (_userId == null) throw ApiException('Not logged in');
    final uri = Uri.parse('$_baseOrders/cart/remove');
    final response = await http.post(
      uri,
      headers: _ordersHeaders(),
      body: jsonEncode({'product_id': productId}),
    );
    if (response.statusCode != 200) {
      _throwFromBody(response.body, response.statusCode);
    }
    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Order> createOrder(double total) async {
    if (_userId == null) throw ApiException('Not logged in');
    final uri = Uri.parse('$_baseOrders/order/create');
    final response = await http.post(
      uri,
      headers: _ordersHeaders(),
      body: jsonEncode({'total': total}),
    );
    if (response.statusCode != 200) {
      _throwFromBody(response.body, response.statusCode);
    }
    return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Order>> getOrders() async {
    if (_userId == null) throw ApiException('Not logged in');
    final uri = Uri.parse('$_baseOrders/orders');
    final response = await http.get(uri, headers: _ordersHeaders());
    if (response.statusCode != 200) {
      _throwFromBody(response.body, response.statusCode);
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderStatus> getOrderStatus(String orderId) async {
    final uri = Uri.parse('$_baseDelivery/order/$orderId/status');
    final response = await http.get(uri);
    if (response.statusCode == 404) {
      throw ApiException('Order not found', 404);
    }
    if (response.statusCode != 200) {
      _throwFromBody(response.body, response.statusCode);
    }
    return OrderStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<OrderStatus> updateOrderStatus(String orderId, String status) async {
    final uri = Uri.parse('$_baseDelivery/order/$orderId/update-status');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      _throwFromBody(response.body, response.statusCode);
    }
    return OrderStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
