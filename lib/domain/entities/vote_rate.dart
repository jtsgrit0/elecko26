import 'package:equatable/equatable.dart';

class VoteRate extends Equatable {
  final int year;
  final double rate;
  // Add other fields as necessary

  const VoteRate({
    required this.year,
    required this.rate,
  });

  @override
  List<Object?> get props => [year, rate];

  // Factory constructor for creating a new VoteRate instance from a map
  factory VoteRate.fromJson(Map<String, dynamic> json) {
    return VoteRate(
      year: json['year'] as int,
      rate: (json['rate'] as num).toDouble(),
    );
  }

  // Method for converting a VoteRate instance to a map
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'rate': rate,
    };
  }
}
