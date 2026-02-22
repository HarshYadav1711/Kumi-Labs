import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../services/api_service.dart';
import '../widgets/loading_placeholder.dart';

/// Backend lifecycle order (no new APIs).
const List<String> _statusSteps = ['PLACED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED'];

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderRef});

  final String orderRef;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _api = apiService;
  OrderStatus? _status;
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
      final status = await _api.getOrderStatus(widget.orderRef);
      if (!mounted) return;
      setState(() {
        _status = status;
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

  /// Next status in order: PLACED → PACKED → OUT_FOR_DELIVERY → DELIVERED. Null if already DELIVERED.
  String? get _nextStatus {
    if (_status == null) return null;
    final i = _statusSteps.indexOf(_status!.status);
    if (i < 0 || i >= _statusSteps.length - 1) return null;
    return _statusSteps[i + 1];
  }

  bool _advancing = false;

  Future<void> _advanceStatus() async {
    final next = _nextStatus;
    if (next == null) return;
    setState(() => _advancing = true);
    try {
      await _api.updateOrderStatus(widget.orderRef, next);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${next.replaceAll('_', ' ')}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  static String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $period';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
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
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.orderRef,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 1.5,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order status',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._statusSteps.asMap().entries.map((entry) {
                                final index = entry.key;
                                final step = entry.value;
                                var currentIndex = _statusSteps.indexOf(_status!.status);
                                if (currentIndex < 0) currentIndex = 0;
                                final isCompleted = index < currentIndex;
                                final isCurrent = index == currentIndex;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isCurrent
                                                  ? Theme.of(context).colorScheme.primary
                                                  : isCompleted
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                            ),
                                            child: isCompleted
                                                ? Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onPrimary)
                                                : null,
                                          ),
                                          if (index < _statusSteps.length - 1)
                                            Container(
                                              width: 2,
                                              height: 28,
                                              margin: const EdgeInsets.only(top: 4),
                                              color: isCompleted
                                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                step.replaceAll('_', ' '),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                                                  color: isCurrent
                                                      ? Theme.of(context).colorScheme.primary
                                                      : null,
                                                ),
                                              ),
                                              if (isCurrent) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Last updated: ${_formatTimestamp(_status!.lastUpdated)}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_nextStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FilledButton(
                            onPressed: _advancing ? null : _advanceStatus,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _advancing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text('Mark as ${_nextStatus!.replaceAll('_', ' ')}'),
                          ),
                        ),
                      TextButton(
                        onPressed: _loading ? null : _load,
                        child: const Text('Refresh'),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                        child: const Text('Back to home'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
