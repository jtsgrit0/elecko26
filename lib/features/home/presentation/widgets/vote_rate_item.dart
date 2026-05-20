import 'package:flutter/material.dart';
import 'package:elecko26_new/domain/entities/vote_rate.dart';

class VoteRateItem extends StatelessWidget {
  final VoteRate voteRate;

  const VoteRateItem({super.key, required this.voteRate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${voteRate.year}년',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '${voteRate.rate.toStringAsFixed(2)}%',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
