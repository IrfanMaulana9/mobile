import 'package:get/get.dart';
import '../models/async_result.dart';
import '../services/async_handling_service.dart';

class AsyncController extends GetxController {
  final asyncService = AsyncHandlingService();

  final isLoading = false.obs;
  final asyncAwaitResult = Rxn<AsyncResult>();
  final callbackResult = Rxn<AsyncResult>();
  final testCount = 0.obs;

  Future<void> runAsyncAwaitTest() async {
    isLoading.value = true;
    try {
      print('[AsyncController] Running async-await test...');
      final result = await asyncService.fetchWeatherAndRecommendationAsyncAwait();
      asyncAwaitResult.value = result;
      print('[AsyncController] Async-await test completed: ${result.totalTime}ms');
    } catch (e) {
      print('[AsyncController] Error in async-await: $e');
      Get.snackbar('Error', 'Gagal menjalankan async-await test: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> runCallbackTest() async {
    isLoading.value = true;
    try {
      print('[AsyncController] Running callback test...');
      final result = await asyncService.fetchWeatherAndRecommendationCallback();
      callbackResult.value = result;
      print('[AsyncController] Callback test completed: ${result.totalTime}ms');
    } catch (e) {
      print('[AsyncController] Error in callback: $e');
      Get.snackbar('Error', 'Gagal menjalankan callback test: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> runBothTests() async {
    isLoading.value = true;
    testCount.value++;
    try {
      print('[AsyncController] Running both tests...');
      await Future.wait([
        runAsyncAwaitTest(),
        runCallbackTest(),
      ]);
      print('[AsyncController] Both tests completed');
    } catch (e) {
      print('[AsyncController] Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String getComparison() {
    if (asyncAwaitResult.value == null || callbackResult.value == null) {
      return 'Jalankan kedua test untuk melihat perbandingan';
    }

    final asyncTime = asyncAwaitResult.value!.totalTime;
    final callbackTime = callbackResult.value!.totalTime;
    final diff = (asyncTime - callbackTime).abs();

    if (asyncTime < callbackTime) {
      return 'Async-await ${diff}ms lebih cepat';
    } else if (callbackTime < asyncTime) {
      return 'Callback ${diff}ms lebih cepat';
    } else {
      return 'Performa sama';
    }
  }

  String getReadabilityAnalysis() {
    return '''
Async-Await:
✓ Kode linear dan mudah dibaca
✓ Mudah di-debug dengan stack trace yang jelas
✓ Error handling dengan try-catch yang familiar
✗ Memerlukan async/await keywords

Callback Chaining:
✓ Fleksibel untuk operasi kompleks
✗ Nested callbacks (callback hell)
✗ Sulit di-debug
✗ Error handling lebih rumit
    ''';
  }
}
