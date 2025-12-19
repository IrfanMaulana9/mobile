import 'package:get/get.dart';
import '../models/rating_review.dart';
import '../services/supabase_service.dart';
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

  /// Load all ratings from Supabase
  Future<void> loadAllRatings() async {
    isLoading.value = true;
    try {
      final data = await supabaseService.getAllRatingReviews();
      ratings.value = data.map((map) => RatingReview.fromMap(map)).toList();
      // Sort by created_at descending (newest first)
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      final ratingId = await supabaseService.insertRatingReview(
        bookingId: bookingId,
        userId: authController.currentUserId,
        customerName: customerName,
        serviceName: serviceName,
        rating: rating,
        review: review,
      );

      if (ratingId != null) {
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

