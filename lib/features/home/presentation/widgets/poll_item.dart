import 'package:flutter/material.dart';
import 'package:elecko26_new/domain/entities/poll.dart'; // Assuming Poll entity exists

class PollItem extends StatelessWidget {
  final Poll poll;

  const PollItem({super.key, required this.poll});

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
              poll.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              '마감일: ${poll.dueDate.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // TODO: Add more poll details and options if needed
          ],
        ),
      ),
    );
  }
}
