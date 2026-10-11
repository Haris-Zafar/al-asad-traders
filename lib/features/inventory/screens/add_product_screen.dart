import 'package:flutter/material.dart';

class AddProductScreen extends StatelessWidget {
  final String? productId;

  const AddProductScreen({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productId == null ? 'Add New Product' : 'Edit Product'),
      ),
      body: const Center(child: Text('Product Form Screen')),
    );
  }
}
