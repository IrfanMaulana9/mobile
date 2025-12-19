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
      // Load from Supabase
      final supabaseData = await supabaseService.getAllRatingReviews();
      final supabaseRatings = supabaseData.map((map) => RatingReview.fromMap(map)).toList();
      
      // Load from Hive (local storage)
      final hiveService = HiveService();
      final hiveRatings = hiveService.getAllRatingReviews();
      final hiveRatingMaps = hiveRatings.map((r) => r.toRatingReviewMap()).toList();
      final hiveRatingReviews = hiveRatingMaps.map((map) => RatingReview.fromMap(map)).toList();
      
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
      
      ratings.value = mergedRatings.values.toList();
      // Sort by created_at descending (newest first)
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('[RatingReviewController] ✅ Loaded ${ratings.length} ratings (${supabaseRatings.length} from Supabase, ${hiveRatingReviews.length} from Hive)');
    } catch (e) {
      print('[RatingReviewController] ❌ Error loading ratings: $e');
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
        // Reload all ratings
        await loadAllRatings();
        Get.snackbar('Sukses', 'Rating & Review berhasil dikirim');
        return true;
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

  /// Check if booking already has rating
  bool hasRatingForBooking(String bookingId) {
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

