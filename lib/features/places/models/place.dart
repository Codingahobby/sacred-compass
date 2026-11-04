class Place {
  const Place({
    required this.id,
    required this.slug,
    required this.name,
    required this.country,
    required this.status,
    this.summary,
    this.history,
    this.visitorGuidance,
    this.region,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Place.fromJson(Map<String, Object?> json) {
    try {
      return Place(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
        summary: json['summary'] as String?,
        history: json['history'] as String?,
        visitorGuidance: json['visitor_guidance'] as String?,
        country: json['country'] as String,
        region: json['region'] as String?,
        city: json['city'] as String?,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        status: json['status'] as String,
        publishedAt: _readDate(json['published_at']),
        createdAt: _readDate(json['created_at']),
        updatedAt: _readDate(json['updated_at']),
      );
    } on TypeError {
      throw const FormatException('Invalid place data.');
    } on FormatException {
      throw const FormatException('Invalid place timestamp.');
    }
  }

  static DateTime? _readDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  final String id;
  final String slug;
  final String name;
  final String? summary;
  final String? history;
  final String? visitorGuidance;
  final String country;
  final String? region;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime? publishedAt;

  // These are present on full rows but omitted by the list query.
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
