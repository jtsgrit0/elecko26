import 'package:equatable/equatable.dart';

class PartySupportRate extends Equatable {
  final String partyName;
  final double rate;
  final int year;

  const PartySupportRate({
    required this.partyName,
    required this.rate,
    required this.year,
  });

  @override
  List<Object?> get props => [partyName, rate, year];

  factory PartySupportRate.fromJson(Map<String, dynamic> json) {
    return PartySupportRate(
      partyName: json['partyName'] as String,
      rate: (json['rate'] as num).toDouble(),
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partyName': partyName,
      'rate': rate,
      'year': year,
    };
  }
}
