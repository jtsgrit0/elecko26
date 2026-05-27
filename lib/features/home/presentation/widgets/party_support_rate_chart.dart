import 'package:flutter/material.dart';
import 'package:elecko26_new/domain/entities/party_support_rate.dart';

class PartySupportRateChart extends StatelessWidget {
  final List<PartySupportRate> rates;

  const PartySupportRateChart({super.key, required this.rates});

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
              '정당 지지율 차트',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            ...rates
                .map((rate) => Text('${rate.year}: ${rate.partyName} ${rate.rate}%'))
                .toList(),
          ],
        ),
      ),
    );
  }
}
