import 'package:equatable/equatable.dart';

class Policy extends Equatable {
  final String id;
  final String title;
  final String description;
  // Add other fields as necessary

  const Policy({
    required this.id,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [id, title, description];

  // Factory constructor for creating a new Policy instance from a map
  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  // Method for converting a Policy instance to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}
