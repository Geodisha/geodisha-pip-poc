class VisitModel {
  final String? id;
  final String? visitId;
  final String? userId;
  final String? constituencyName;
  final String? constituencyId;
  final String? locationName;
  final String? visitType;
  final String? visitPurpose;
  final DateTime? visitDate;
  final double? latitude;
  final double? longitude;
  final int? attendeesCount;
  final String? sentimentScore;
  final List<String>? issuesDiscussed;
  final String? notes;
  final String? mediaUrls;
  final DateTime? createdAt;

  VisitModel({
    this.id,
    this.visitId,
    this.userId,
    this.constituencyName,
    this.constituencyId,
    this.locationName,
    this.visitType,
    this.visitPurpose,
    this.visitDate,
    this.latitude,
    this.longitude,
    this.attendeesCount,
    this.sentimentScore,
    this.issuesDiscussed,
    this.notes,
    this.mediaUrls,
    this.createdAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id']?.toString(),
      visitId: json['visit_id']?.toString(),
      userId: json['user_id']?.toString(),
      constituencyName: json['constituency_name']?.toString(),
      constituencyId: json['constituency_id']?.toString(),
      locationName: json['location_name']?.toString(),
      visitType: json['visit_type']?.toString(),
      visitPurpose: json['visit_purpose']?.toString(),
      visitDate: json['visit_date'] != null 
          ? DateTime.tryParse(json['visit_date'].toString())
          : null,
      latitude: json['latitude'] != null 
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null 
          ? double.tryParse(json['longitude'].toString())
          : null,
      attendeesCount: json['attendees_count'] != null
          ? int.tryParse(json['attendees_count'].toString())
          : null,
      sentimentScore: json['sentiment_score']?.toString(),
      issuesDiscussed: json['issues_discussed'] != null
          ? List<String>.from(json['issues_discussed'])
          : null,
      notes: json['notes']?.toString(),
      mediaUrls: json['media_urls']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visit_id': visitId,
      'user_id': userId,
      'constituency_name': constituencyName,
      'constituency_id': constituencyId,
      'location_name': locationName,
      'visit_type': visitType,
      'visit_purpose': visitPurpose,
      'visit_date': visitDate?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'attendees_count': attendeesCount,
      'sentiment_score': sentimentScore,
      'issues_discussed': issuesDiscussed,
      'notes': notes,
      'media_urls': mediaUrls,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class VisitStatistics {
  final int totalVisits;
  final int totalAttendees;
  final Map<String, int> visitsByType;
  final Map<String, int> visitsByMonth;
  final double avgSentiment;

  VisitStatistics({
    required this.totalVisits,
    required this.totalAttendees,
    required this.visitsByType,
    required this.visitsByMonth,
    required this.avgSentiment,
  });

  factory VisitStatistics.fromJson(Map<String, dynamic> json) {
    return VisitStatistics(
      totalVisits: json['total_visits'] ?? 0,
      totalAttendees: json['total_attendees'] ?? 0,
      visitsByType: Map<String, int>.from(json['visits_by_type'] ?? {}),
      visitsByMonth: Map<String, int>.from(json['visits_by_month'] ?? {}),
      avgSentiment: (json['avg_sentiment'] ?? 0.0).toDouble(),
    );
  }
}
