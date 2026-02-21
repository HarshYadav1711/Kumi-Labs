import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _api = apiService;
  Cart? _cart;
  List<Product> _products = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await _api.getCart();
      final products = await _api.getProducts();
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _products = products;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  Product? _productById(String id) {
    try {
      return _products.firstWhere((p) => p.productId == id);
    } catch (_) {
      return null;
    }
  }

  double _total() {
    if (_cart == null) return 0;
    double sum = 0;
    for (final item in _cart!.items) {
      final p = _productById(item.productId);
      if (p != null) sum += p.price * item.quantity;
    }
    return sum;
  }

  Future<void> _remove(String productId) async {
    try {
      final cart = await _api.removeFromCart(productId);
      if (!mounted) return;
      setState(() => _cart = cart);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _placeOrder() async {
    final total = _total();
    try {
      final order = await _api.createOrder(total);
      try {
        await _api.updateOrderStatus(order.orderRef, 'PLACED');
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed. Tracking may be unavailable.')),
          );
        }
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(order: order),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final cart = _cart!;
    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: Text('Your cart is empty')),
      );
    }
    final total = _total();
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                final p = _productById(item.productId);
                final name = p?.name ?? item.productId;
                final price = p?.price ?? 0.0;
                final lineTotal = price * item.quantity;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('Qty: ${item.quantity} · ₹${lineTotal.toStringAsFixed(0)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _remove(item.productId),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total: ₹${total.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _placeOrder,
                    child: const Text('Place order'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
