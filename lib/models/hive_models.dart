import 'package:hive/hive.dart';

part 'hive_models.g.dart';

/// Hive model untuk booking history dengan notes & photos support
@HiveType(typeId: 0)
class HiveBooking extends HiveObject {
  @HiveField(0)
  String id = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(1)
  String customerName = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(2)
  String phoneNumber = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(3)
  String serviceName = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(4)
  double latitude = 0.0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(5)
  double longitude = 0.0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(6)
  String address = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(7)
  DateTime bookingDate = DateTime.now(); // ✅ INISIALISASI LANGSUNG
  
  @HiveField(8)
  String bookingTime = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(9)
  double totalPrice = 0.0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(10)
  String status = 'pending'; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(11)
  DateTime createdAt = DateTime.now(); // ✅ INISIALISASI LANGSUNG
  
  @HiveField(12)
  DateTime? updatedAt; // ✅ NULLABLE - TIDAK PERLU INISIALISASI
  
  @HiveField(13)
  bool synced = false; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(14)
  String? notes; // ✅ NULLABLE - TIDAK PERLU INISIALISASI
  
  @HiveField(15)
  List<String>? photoUrls; // ✅ NULLABLE - TIDAK PERLU INISIALISASI

  @HiveField(16)
  List<String>? localPhotoPaths; // ✅ NULLABLE - TIDAK PERLU INISIALISASI

  // ✅ CONSTRUCTOR UNTUK MEMUDAH PEMBUATAN OBJECT
  HiveBooking({
    String? id,
    String? customerName,
    String? phoneNumber,
    String? serviceName,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? bookingDate,
    String? bookingTime,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    this.updatedAt,
    bool? synced,
    this.notes,
    this.photoUrls,
    this.localPhotoPaths,
  }) {
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    this.customerName = customerName ?? '';
    this.phoneNumber = phoneNumber ?? '';
    this.serviceName = serviceName ?? '';
    this.latitude = latitude ?? 0.0;
    this.longitude = longitude ?? 0.0;
    this.address = address ?? '';
    this.bookingDate = bookingDate ?? DateTime.now();
    this.bookingTime = bookingTime ?? '';
    this.totalPrice = totalPrice ?? 0.0;
    this.status = status ?? 'pending';
    this.createdAt = createdAt ?? DateTime.now();
    this.synced = synced ?? false;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'phoneNumber': phoneNumber,
    'serviceName': serviceName,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'bookingDate': bookingDate.toIso8601String(),
    'bookingTime': bookingTime,
    'totalPrice': totalPrice,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'synced': synced,
    'notes': notes,
    'photoUrls': photoUrls ?? [],
    'localPhotoPaths': localPhotoPaths ?? [],
  };
  
  // ✅ FACTORY METHOD YANG LEBIH AMAN
  factory HiveBooking.fromJson(Map<String, dynamic> json) {
    return HiveBooking(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: json['customerName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address']?.toString() ?? '',
      bookingDate: json['bookingDate'] is String 
          ? DateTime.tryParse(json['bookingDate']) ?? DateTime.now()
          : json['bookingDate'] ?? DateTime.now(),
      bookingTime: json['bookingTime']?.toString() ?? '',
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] is String 
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : json['createdAt'] ?? DateTime.now(),
      updatedAt: json['updatedAt'] is String 
          ? DateTime.tryParse(json['updatedAt'])
          : json['updatedAt'],
      synced: json['synced'] ?? false,
      notes: json['notes']?.toString(),
      photoUrls: json['photoUrls'] != null 
          ? List<String>.from(json['photoUrls']) 
          : null,
      localPhotoPaths: json['localPhotoPaths'] != null
          ? List<String>.from(json['localPhotoPaths'])
          : null,
    );
  }
}

/// Hive model untuk cached weather data
@HiveType(typeId: 1)
class HiveCachedWeather extends HiveObject {
  @HiveField(0)
  String locationKey = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(1)
  double temperature = 0.0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(2)
  double windSpeed = 0.0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(3)
  int rainProbability = 0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(4)
  DateTime cachedAt = DateTime.now(); // ✅ INISIALISASI LANGSUNG

  // ✅ CONSTRUCTOR
  HiveCachedWeather({
    String? locationKey,
    double? temperature,
    double? windSpeed,
    int? rainProbability,
    DateTime? cachedAt,
  }) {
    this.locationKey = locationKey ?? '';
    this.temperature = temperature ?? 0.0;
    this.windSpeed = windSpeed ?? 0.0;
    this.rainProbability = rainProbability ?? 0;
    this.cachedAt = cachedAt ?? DateTime.now();
  }
  
  bool isExpired() => DateTime.now().difference(cachedAt).inHours > 6;
  
  Map<String, dynamic> toJson() => {
    'locationKey': locationKey,
    'temperature': temperature,
    'windSpeed': windSpeed,
    'rainProbability': rainProbability,
    'cachedAt': cachedAt.toIso8601String(),
  };

  // ✅ FACTORY METHOD
  factory HiveCachedWeather.fromJson(Map<String, dynamic> json) {
    return HiveCachedWeather(
      locationKey: json['locationKey']?.toString() ?? '',
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
      rainProbability: (json['rainProbability'] ?? 0).toInt(),
      cachedAt: json['cachedAt'] is String 
          ? DateTime.tryParse(json['cachedAt']) ?? DateTime.now()
          : json['cachedAt'] ?? DateTime.now(),
    );
  }
}

/// Hive model untuk last used location
@HiveType(typeId: 2)
class HiveLastLocation extends HiveObject {
  @HiveField(0)
  double latitude = 0.0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(1)
  double longitude = 0.0; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(2)
  String address = ''; // ✅ INISIALISASI LANGSUNG
  
  @HiveField(3)
  String? placeName; // ✅ NULLABLE - TIDAK PERLU INISIALISASI
  
  @HiveField(4)
  DateTime usedAt = DateTime.now(); // ✅ INISIALISASI LANGSUNG

  // ✅ CONSTRUCTOR
  HiveLastLocation({
    double? latitude,
    double? longitude,
    String? address,
    this.placeName,
    DateTime? usedAt,
  }) {
    this.latitude = latitude ?? 0.0;
    this.longitude = longitude ?? 0.0;
    this.address = address ?? '';
    this.usedAt = usedAt ?? DateTime.now();
  }
  
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'placeName': placeName,
    'usedAt': usedAt.toIso8601String(),
  };

  // ✅ FACTORY METHOD
  factory HiveLastLocation.fromJson(Map<String, dynamic> json) {
    return HiveLastLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address']?.toString() ?? '',
      placeName: json['placeName']?.toString(),
      usedAt: json['usedAt'] is String 
          ? DateTime.tryParse(json['usedAt']) ?? DateTime.now()
          : json['usedAt'] ?? DateTime.now(),
    );
  }
}

/// Hive model untuk notes STANDALONE - NO BOOKING DEPENDENCY
@HiveType(typeId: 3)
class HiveNote extends HiveObject {
  @HiveField(0)
  String id = '';
  
  @HiveField(1)
  String userId = '';
  
  @HiveField(2)
  String title = '';
  
  @HiveField(3)
  String content = '';
  
  @HiveField(4)
  DateTime createdAt = DateTime.now();
  
  @HiveField(5)
  DateTime? updatedAt;
  
  @HiveField(6)
  bool synced = false;
  
  @HiveField(7)
  String? supabaseId;

  @HiveField(8)
  List<String> imageUrls = [];
  
  @HiveField(9)
  List<String> localImagePaths = [];
  
  HiveNote({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    this.updatedAt,
    bool? synced,
    this.supabaseId,
    List<String>? imageUrls,
    List<String>? localImagePaths,
  }) {
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    this.userId = userId ?? '';
    this.title = title ?? '';
    this.content = content ?? '';
    this.createdAt = createdAt ?? DateTime.now();
    this.synced = synced ?? false;
    this.imageUrls = imageUrls ?? [];
    this.localImagePaths = localImagePaths ?? [];
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'synced': synced,
    'supabaseId': supabaseId,
    'imageUrls': imageUrls,
    'localImagePaths': localImagePaths,
  };
  
  factory HiveNote.fromJson(Map<String, dynamic> json) {
    return HiveNote(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] is String 
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : json['createdAt'] ?? DateTime.now(),
      updatedAt: json['updatedAt'] is String 
          ? DateTime.tryParse(json['updatedAt'])
          : json['updatedAt'],
      synced: json['synced'] ?? false,
      supabaseId: json['supabaseId']?.toString(),
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls']) 
          : [],
      localImagePaths: json['localImagePaths'] != null
          ? List<String>.from(json['localImagePaths'])
          : [],
    );
  }
}

/// Hive model untuk Rating Review
@HiveType(typeId: 4)
class HiveRatingReview extends HiveObject {
  @HiveField(0)
  String id = '';
  
  @HiveField(1)
  String bookingId = '';
  
  @HiveField(2)
  String userId = '';
  
  @HiveField(3)
  String customerName = '';
  
  @HiveField(4)
  String serviceName = '';
  
  @HiveField(5)
  int rating = 0; // 1-5 stars
  
  @HiveField(6)
  String review = '';
  
  @HiveField(7)
  DateTime createdAt = DateTime.now();
  
  @HiveField(8)
  DateTime updatedAt = DateTime.now();
  
  @HiveField(9)
  bool synced = false; // Whether synced to Supabase
  
  @HiveField(10)
  String? supabaseId; // ID from Supabase after sync

  HiveRatingReview({
    String? id,
    String? bookingId,
    String? userId,
    String? customerName,
    String? serviceName,
    int? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
    this.supabaseId,
  }) {
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    this.bookingId = bookingId ?? '';
    this.userId = userId ?? '';
    this.customerName = customerName ?? '';
    this.serviceName = serviceName ?? '';
    this.rating = rating ?? 0;
    this.review = review ?? '';
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.synced = synced ?? false;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_id': bookingId,
    'user_id': userId,
    'customer_name': customerName,
    'service_name': serviceName,
    'rating': rating,
    'review': review,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'synced': synced,
    'supabase_id': supabaseId,
  };

  factory HiveRatingReview.fromJson(Map<String, dynamic> json) {
    return HiveRatingReview(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: json['booking_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toInt(),
      review: json['review']?.toString() ?? '',
      createdAt: json['created_at'] is String 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : json['created_at'] ?? DateTime.now(),
      updatedAt: json['updated_at'] is String 
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : json['updated_at'] ?? DateTime.now(),
      synced: json['synced'] ?? false,
      supabaseId: json['supabase_id']?.toString(),
    );
  }
  
  // Convert to RatingReview model
  Map<String, dynamic> toRatingReviewMap() => {
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