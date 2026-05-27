import 'package:flutter/material.dart';
import 'package:elecko26_new/domain/entities/poll.dart';

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
              poll.pollAgency,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              '조사일: ${poll.surveyDate.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6.0),
            Text(
              poll.supportRate != null
                  ? '지지율: ${(poll.supportRate! * 100).toStringAsFixed(1)}%'
                  : '지지율: 미공개',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (poll.sampleSize != null || poll.marginOfError != null) ...[
              const SizedBox(height: 6.0),
              Text(
                [
                  if (poll.sampleSize != null) '표본 ${poll.sampleSize}명',
                  if (poll.marginOfError != null)
                    '오차 ±${poll.marginOfError!.toStringAsFixed(1)}%',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (poll.notes != null && poll.notes!.isNotEmpty) ...[
              const SizedBox(height: 6.0),
              Text(
                poll.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
