import 'package:equatable/equatable.dart';

class Poll extends Equatable {
  final String id;
  final String question;
  final DateTime dueDate;
  // Add other fields as necessary, e.g., List<String> options, Map<String, int> results

  const Poll({
    required this.id,
    required this.question,
    required this.dueDate,
  });

  @override
  List<Object?> get props => [id, question, dueDate];

  // Factory constructor for creating a new Poll instance from a map
  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      question: json['question'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
    );
  }

  // Method for converting a Poll instance to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'dueDate': dueDate.toIso8601String(),
    };
  }
}
