import 'package:get/get.dart';
import '../models/rating_review.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../models/hive_models.dart';
import '../controllers/auth_controller.dart';
import '../controllers/storage_controller.dart';

class RatingReviewController extends GetxController {
  final ratings = <RatingReview>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  late SupabaseService supabaseService;
  late AuthController authController;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Get SupabaseService from StorageController
    final storageController = Get.find<StorageController>();
    supabaseService = storageController.supabaseService;
    authController = Get.find<AuthController>();
    await loadAllRatings();
  }

  /// Load all ratings from Supabase and Hive (merge both sources)
  Future<void> loadAllRatings() async {
    isLoading.value = true;
    try {
      print('[RatingReviewController] 🔄 Loading ratings...');
      
      // Load from Supabase
      List<RatingReview> supabaseRatings = [];
      try {
        final supabaseData = await supabaseService.getAllRatingReviews();
        supabaseRatings = supabaseData.map((map) {
          try {
            return RatingReview.fromMap(map);
          } catch (e) {
            print('[RatingReviewController] ⚠️ Error parsing Supabase rating: $e');
            return null;
          }
        }).whereType<RatingReview>().toList();
        print('[RatingReviewController] ✅ Loaded ${supabaseRatings.length} ratings from Supabase');
      } catch (e) {
        print('[RatingReviewController] ⚠️ Error loading from Supabase: $e');
      }
      
      // Load from Hive (local storage)
      List<RatingReview> hiveRatingReviews = [];
      try {
        final hiveService = HiveService();
        final hiveRatings = hiveService.getAllRatingReviews();
        print('[RatingReviewController] 📦 Found ${hiveRatings.length} ratings in Hive');
        
        for (var hiveRating in hiveRatings) {
          try {
            final map = hiveRating.toRatingReviewMap();
            final rating = RatingReview.fromMap(map);
            hiveRatingReviews.add(rating);
          } catch (e) {
            print('[RatingReviewController] ⚠️ Error parsing Hive rating ${hiveRating.id}: $e');
          }
        }
        print('[RatingReviewController] ✅ Loaded ${hiveRatingReviews.length} ratings from Hive');
      } catch (e) {
        print('[RatingReviewController] ⚠️ Error loading from Hive: $e');
      }
      
      // Merge both sources, avoiding duplicates (prefer Supabase if both exist)
      final Map<String, RatingReview> mergedRatings = {};
      
      // Add Hive ratings first
      for (var rating in hiveRatingReviews) {
        mergedRatings[rating.id] = rating;
      }
      
      // Add/override with Supabase ratings
      for (var rating in supabaseRatings) {
        mergedRatings[rating.id] = rating;
      }
      
      // Update reactive list
      ratings.value = mergedRatings.values.toList();
      // Sort by created_at descending (newest first)
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('[RatingReviewController] ✅ Total ${ratings.length} ratings loaded (${supabaseRatings.length} from Supabase, ${hiveRatingReviews.length} from Hive)');
    } catch (e, stackTrace) {
      print('[RatingReviewController] ❌ Error loading ratings: $e');
      print('[RatingReviewController] Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  /// Create new rating & review
  Future<bool> createRatingReview({
    required String bookingId,
    required String customerName,
    required String serviceName,
    required int rating,
    required String review,
  }) async {
    if (!authController.isAuthenticated.value) {
      Get.snackbar('Error', 'Anda harus login terlebih dahulu');
      return false;
    }

    isSaving.value = true;
    try {
      final savedId = await supabaseService.insertRatingReview(
        bookingId: bookingId,
        userId: authController.currentUserId,
        customerName: customerName,
        serviceName: serviceName,
        rating: rating,
        review: review,
      );

      if (savedId != null) {
        // Successfully saved (either to Supabase or Hive fallback)
        print('[RatingReviewController] ✅ Rating saved with ID: $savedId');
        
        // Force reload all ratings to ensure UI updates
        await loadAllRatings();
        
        // Double check that the rating was added
        final allRatings = ratings.value;
        final newRating = allRatings.firstWhere(
          (r) => r.id == savedId,
          orElse: () => RatingReview(
            id: '',
            bookingId: '',
            userId: '',
            customerName: '',
            serviceName: '',
            rating: 0,
            review: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        if (newRating.id.isNotEmpty) {
          print('[RatingReviewController] ✅ Rating confirmed in list: ${newRating.id}');
          Get.snackbar('Sukses', 'Rating & Review berhasil dikirim');
          return true;
        } else {
          print('[RatingReviewController] ⚠️ Rating saved but not found in list, forcing reload...');
          await Future.delayed(const Duration(milliseconds: 500));
          await loadAllRatings();
          Get.snackbar('Sukses', 'Rating & Review berhasil dikirim');
          return true;
        }
      } else {
        Get.snackbar('Error', 'Gagal mengirim rating & review');
        return false;
      }
    } catch (e) {
      print('[RatingReviewController] ❌ Error creating rating: $e');
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Check if booking already has rating (by current user)
  bool hasRatingForBooking(String bookingId) {
    if (!authController.isAuthenticated.value) return false;
    final currentUserId = authController.currentUserId;
    return ratings.any((r) => 
      r.bookingId == bookingId && r.userId == currentUserId
    );
  }
  
  /// Check if booking already has rating (by any user)
  bool hasAnyRatingForBooking(String bookingId) {
    return ratings.any((r) => r.bookingId == bookingId);
  }

  /// Get rating for specific booking
  RatingReview? getRatingForBooking(String bookingId) {
    try {
      return ratings.firstWhere((r) => r.bookingId == bookingId);
    } catch (e) {
      return null;
    }
  }

  /// Delete rating review
  Future<bool> deleteRatingReview(String ratingId) async {
    try {
      final success = await supabaseService.deleteRatingReview(ratingId);
      if (success) {
        await loadAllRatings();
        Get.snackbar('Sukses', 'Rating & Review berhasil dihapus');
        return true;
      } else {
        Get.snackbar('Error', 'Gagal menghapus rating & review');
        return false;
      }
    } catch (e) {
      print('[RatingReviewController] ❌ Error deleting rating: $e');
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
      return false;
    }
  }
}

