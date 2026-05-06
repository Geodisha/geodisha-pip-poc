class ConstituencyModel {
  final String id;
  final String name;
  final String state;
  final String type; // MLA, MP
  final int? totalBooths;
  final int? totalVoters;
  final double? healthScore;
  final Map<String, dynamic>? demographics;
  final Map<String, dynamic>? statistics;

  ConstituencyModel({
    required this.id,
    required this.name,
    required this.state,
    required this.type,
    this.totalBooths,
    this.totalVoters,
    this.healthScore,
    this.demographics,
    this.statistics,
  });

  factory ConstituencyModel.fromJson(Map<String, dynamic> json) {
    return ConstituencyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      type: json['type']?.toString() ?? 'MLA',
      totalBooths: json['total_booths'] != null
          ? int.tryParse(json['total_booths'].toString())
          : null,
      totalVoters: json['total_voters'] != null
          ? int.tryParse(json['total_voters'].toString())
          : null,
      healthScore: json['health_score'] != null
          ? double.tryParse(json['health_score'].toString())
          : null,
      demographics: json['demographics'],
      statistics: json['statistics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'type': type,
      'total_booths': totalBooths,
      'total_voters': totalVoters,
      'health_score': healthScore,
      'demographics': demographics,
      'statistics': statistics,
    };
  }
}
