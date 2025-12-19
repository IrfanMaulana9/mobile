class RatingReview {
  final String id;
  final String bookingId;
  final String userId;
  final String customerName;
  final String serviceName;
  final int rating; // 1-5 stars
  final String review;
  final DateTime createdAt;
  final DateTime updatedAt;

  RatingReview({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.customerName,
    required this.serviceName,
    required this.rating,
    required this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'customer_name': customerName,
      'service_name': serviceName,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RatingReview.fromMap(Map<String, dynamic> map) {
    try {
      return RatingReview(
        id: map['id']?.toString() ?? '',
        bookingId: map['booking_id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        customerName: map['customer_name']?.toString() ?? '',
        serviceName: map['service_name']?.toString() ?? '',
        rating: (map['rating'] is int) 
            ? map['rating'] as int 
            : int.tryParse(map['rating']?.toString() ?? '0') ?? 0,
        review: map['review']?.toString() ?? '',
        createdAt: map['created_at'] is String
            ? DateTime.parse(map['created_at'] as String)
            : (map['created_at'] is DateTime 
                ? map['created_at'] as DateTime 
                : DateTime.now()),
        updatedAt: map['updated_at'] is String
            ? DateTime.parse(map['updated_at'] as String)
            : (map['updated_at'] is DateTime 
                ? map['updated_at'] as DateTime 
                : DateTime.now()),
      );
    } catch (e) {
      print('[RatingReview] ❌ Error parsing map: $e');
      print('[RatingReview] Map data: $map');
      rethrow;
    }
  }
}

