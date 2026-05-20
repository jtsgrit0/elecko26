import 'package:flutter/material.dart';
import 'package:elecko26_new/domain/entities/vote_rate.dart'; // Assuming VoteRate entity exists

class VoteRateChart extends StatelessWidget {
  final List<VoteRate> rates;

  const VoteRateChart({super.key, required this.rates});

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
              '득표율 차트',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            // TODO: Implement actual chart visualization for vote rates
            ...rates
                .map((rate) => Text('${rate.year}: ${rate.rate}%'))
                .toList(),
          ],
        ),
      ),
    );
  }
}
