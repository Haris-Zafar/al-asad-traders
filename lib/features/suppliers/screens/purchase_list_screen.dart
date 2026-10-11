import 'package:flutter/material.dart';

class PurchaseListScreen extends StatelessWidget {
  const PurchaseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Requirement List')),
      body: const Center(child: Text('Purchase List Screen')),
    );
  }
}
