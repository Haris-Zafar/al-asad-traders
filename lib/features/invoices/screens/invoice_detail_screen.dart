import 'package:flutter/material.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Details')),
      body: Center(child: Text('Invoice Detail Screen for $invoiceId')),
    );
  }
}
