import 'package:flutter/material.dart';
import 'package:elecko26_new/domain/entities/policy.dart'; // Assuming Policy entity exists

class PolicyItem extends StatelessWidget {
  final Policy policy;

  const PolicyItem({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              policy.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              policy.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // TODO: Add more policy details if needed
          ],
        ),
      ),
    );
  }
}
