import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/loading_placeholder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = apiService;
  List<Product> _products = [];
  List<String> _categories = [];
  String? _selectedCategory; // null = All
  String? _error;
  bool _loading = true;
  String? _addingProductId;

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
      final results = await Future.wait([_api.getProducts(), _api.getCategories()]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<String>;
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

  List<Product> get _filteredProducts {
    if (_selectedCategory == null) return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  Future<void> _addToCart(Product p) async {
    setState(() => _addingProductId = p.productId);
    try {
      await _api.addToCart(p.productId, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${p.name} to cart')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _addingProductId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              _api.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? loadingPlaceholder()
          : _error != null
              ? Center(
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
                )
              : _products.isEmpty && _categories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('All'),
                                  selected: _selectedCategory == null,
                                  onSelected: (_) => setState(() => _selectedCategory = null),
                                ),
                              ),
                              ..._categories.map(
                                (name) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(name),
                                    selected: _selectedCategory == name,
                                    onSelected: (_) => setState(() => _selectedCategory = name),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _filteredProducts.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No products in this category',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        FilledButton(
                                          onPressed: () => setState(() => _selectedCategory = null),
                                          child: const Text('View all'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    itemCount: _filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final p = _filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 1.5,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Container(
                                    height: 72,
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                    child: Center(
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 32,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p.category,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${p.price.toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: FilledButton(
                                          onPressed: _addingProductId == p.productId ? null : () => _addToCart(p),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: _addingProductId == p.productId
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Text('Add to cart'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                                  ),
                                ),
                        ),
                      ],
                    ),
    );
  }
}
