import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/loading_placeholder.dart';
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
  bool _placingOrder = false;
  String? _updatingProductId;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
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

  Future<void> _increment(String productId) async {
    setState(() => _updatingProductId = productId);
    try {
      final cart = await _api.addToCart(productId, quantity: 1);
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _updatingProductId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _updatingProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
    }
  }

  Future<void> _decrement(String productId) async {
    final item = (_cart?.items ?? <CartItem>[]).where((i) => i.productId == productId).firstOrNull;
    if (item == null || item.quantity <= 1) return;
    setState(() => _updatingProductId = productId);
    try {
      await _api.removeFromCart(productId);
      final cart = await _api.addToCart(productId, quantity: item.quantity - 1);
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _updatingProductId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _updatingProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
    }
  }

  Future<void> _remove(String productId) async {
    setState(() => _updatingProductId = productId);
    try {
      final cart = await _api.removeFromCart(productId);
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _updatingProductId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _updatingProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
    }
  }

  Future<void> _placeOrder() async {
    final total = _total();
    setState(() => _placingOrder = true);
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: loadingPlaceholder(),
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
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final cart = _cart!;
    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final total = _total();
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                final p = _productById(item.productId);
                final name = p?.name ?? item.productId;
                final price = p?.price ?? 0.0;
                final lineTotal = price * item.quantity;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 1.5,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 56,
                            height: 56,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 28,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: item.quantity <= 1 || _updatingProductId == item.productId
                                            ? null
                                            : () => _decrement(item.productId),
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(4),
                                          minimumSize: const Size(32, 32),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: _updatingProductId == item.productId
                                            ? null
                                            : () => _increment(item.productId),
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(4),
                                          minimumSize: const Size(32, 32),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${lineTotal.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _updatingProductId == item.productId ? null : () => _remove(item.productId),
                          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _placingOrder ? null : _placeOrder,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _placingOrder
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Place order',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
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
