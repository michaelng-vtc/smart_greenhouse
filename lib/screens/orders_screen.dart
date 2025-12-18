import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        context.read<CartProvider>().fetchOrders(auth.userId!);
      }
    });
  }

  Future<void> _exportToExcel(List<Order> orders) async {
    var excel = Excel.createExcel();
    // Rename default sheet
    String defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, 'Orders');

    Sheet sheet = excel['Orders'];

    // Add headers
    List<CellValue> headers = [
      TextCellValue('Order ID'),
      TextCellValue('Date'),
      TextCellValue('Status'),
      TextCellValue('Total Amount'),
      TextCellValue('Items'),
    ];
    sheet.appendRow(headers);

    for (var order in orders) {
      String itemsStr = order.items
          .map((item) => '${item.productName} (${item.quantity})')
          .join(', ');

      List<CellValue> row = [
        IntCellValue(order.id),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)),
        TextCellValue(order.status),
        DoubleCellValue(order.totalAmount),
        TextCellValue(itemsStr),
      ];
      sheet.appendRow(row);
    }

    // Save
    var fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/orders_report.xlsx');
      await file.writeAsBytes(fileBytes);

      // Share
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Here is your orders report.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return IconButton(
                icon: const Icon(Icons.download),
                onPressed: cart.orders.isEmpty
                    ? null
                    : () => _exportToExcel(cart.orders),
                tooltip: 'Export Report',
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cart.orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cart.orders.length,
            itemBuilder: (context, index) {
              final order = cart.orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text('Order #${order.id}'),
                  subtitle: Text(
                    '${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}\nStatus: ${order.status.toUpperCase()}',
                  ),
                  trailing: Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  children: order.items.map((item) {
                    return ListTile(
                      title: Text(item.productName),
                      subtitle: Text('${item.quantity} x \$${item.price}'),
                      trailing: Text(
                        '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
