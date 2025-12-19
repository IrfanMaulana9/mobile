import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/rating_review_controller.dart';
import '../models/rating_review.dart';

class RatingReviewPage extends StatelessWidget {
  static const String routeName = '/rating-review';
  
  const RatingReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RatingReviewController());
    final cs = Theme.of(context).colorScheme;

    // Load ratings when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAllRatings();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating & Review'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadAllRatings(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 64, color: cs.outline),
                const SizedBox(height: 16),
                Text(
                  'Belum ada Rating & Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rating & review akan muncul di sini setelah customer memberikan rating',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAllRatings(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.ratings.length,
            itemBuilder: (context, index) {
              final rating = controller.ratings[index];
              return _buildRatingCard(context, rating, cs);
            },
          ),
        );
      }),
    );
  }

  Widget _buildRatingCard(BuildContext context, RatingReview rating, ColorScheme cs) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.customerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rating.serviceName,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(rating.rating),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rating.review,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(rating.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return Icon(
          starNumber <= rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}

