import 'package:flutter/material.dart';

import '../models/order.dart';
import 'order_tracking_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Order reference: ${order.orderRef}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Total: ₹${order.total.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('Placed at: ${order.timestamp}'),
            const SizedBox(height: 24),
            Text('Items:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ...order.items.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('${e.productId} × ${e.quantity}'),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderTrackingScreen(orderRef: order.orderRef),
                  ),
                );
              },
              child: const Text('Track order'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
