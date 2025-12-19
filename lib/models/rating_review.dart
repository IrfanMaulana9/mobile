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
    return RatingReview(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      userId: map['user_id'] as String,
      customerName: map['customer_name'] as String,
      serviceName: map['service_name'] as String,
      rating: map['rating'] as int,
      review: map['review'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

