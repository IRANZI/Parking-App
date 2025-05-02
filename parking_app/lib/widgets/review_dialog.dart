import 'package:flutter/material.dart';
import 'package:parking/data/services/parking_services.dart';

class ReviewDialog {
  static void show(
    BuildContext context,
    String parkingSpotId, {
    VoidCallback? onReviewSubmitted,
  }) {
    int rating = 0;
    final commentController = TextEditingController();
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Review'),
              content: SizedBox(
                width: isMobile ? double.maxFinite : 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                          onPressed: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Your review',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a rating')),
                      );
                      return;
                    }
                    _submitReview(
                      context,
                      parkingSpotId,
                      rating,
                      commentController.text.trim(),
                      onReviewSubmitted, // pass the callback here
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _submitReview(
    BuildContext context,
    String parkingSpotId,
    int rating,
    String comment,
    VoidCallback? onReviewSubmitted,
  ) async {
    try {
      await ParkingService.addReview(
        parkingSpotId: parkingSpotId,
        rating: rating,
        comment: comment,
      );

      Navigator.pop(context); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!')),
      );

      if (onReviewSubmitted != null) {
        onReviewSubmitted(); // ✅ Trigger the refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
