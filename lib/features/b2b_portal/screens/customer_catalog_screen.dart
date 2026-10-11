import 'package:flutter/material.dart';

class CustomerCatalogScreen extends StatelessWidget {
  const CustomerCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B2B Product Catalog')),
      body: const Center(child: Text('Customer Catalog Screen')),
    );
  }
}
