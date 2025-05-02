import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parking/data/models/parking_spot.dart';
import 'package:parking/data/services/parking_services.dart';
import 'package:parking/data/models/review.dart';
import 'package:parking/widgets/review_dialog.dart';

class ParkingDetailPage extends StatefulWidget {
  final ParkingSpot spot;
  final LatLng userLocation;

  const ParkingDetailPage({
    super.key, 
    required this.spot,
    required this.userLocation,
  });

  @override
  State<ParkingDetailPage> createState() => _ParkingDetailPageState();
}

class _ParkingDetailPageState extends State<ParkingDetailPage> {
    late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Initialize the controller
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller when not needed
    super.dispose();
  }
  // Add this method for showing review dialog
  void _showAddReviewDialog(String spotId) {
  ReviewDialog.show(context, spotId,
  );
}

  @override
  Widget build(BuildContext context) {
    final parkingLocation = LatLng(widget.spot.latitude, widget.spot.longitude);
    final centerPoint = LatLng(
      (widget.userLocation.latitude + parkingLocation.latitude) / 2,
      (widget.userLocation.longitude + parkingLocation.longitude) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareParkingSpot(context),
          ),
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: () => _launchDirections(parkingLocation),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            flexibleSpace: widget.spot.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.spot.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.local_parking, size: 100),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.spot.averageRating != null) 
                        _buildRatingStars(widget.spot.averageRating!),
                      const Spacer(),
                      Text(
                       "${widget.spot.price.toStringAsFixed(2)}Rwf/h",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Location Map Section
                  const Text(
                    "Location",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLocationMap(centerPoint, widget.userLocation, parkingLocation),
                  const SizedBox(height: 8),
                  FutureBuilder<double>(
                    future: _calculateDistance(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.hasData
                            ? "Distance: ${snapshot.data!.toStringAsFixed(1)} km • ~${(snapshot.data! / 0.1 * 10).toStringAsFixed(0)} min walk"
                            : "Calculating distance...",
                        style: TextStyle(color: Colors.grey[600]),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                      "Address",
                     style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    ),
                   ),
                  const SizedBox(height: 8),
                  Text(
                    widget.spot.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 16),

                  const Divider(),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.spot.description ?? "No description available",
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Divider(),
                  const Text(
                    "Amenities",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAmenities(),
                  const SizedBox(height: 16),
                  
                  const Divider(),
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Reviews",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    ElevatedButton.icon(
      icon: const Icon(Icons.add_comment),
      label: const Text('Add Your Review'),
      onPressed: () => _showAddReviewDialog(widget.spot.id),
    ),
  ],
),

                  const SizedBox(height: 8),
                  _buildReviewsSection(widget.spot.id),
                ],
              ),
            ),
          ),
        ],
      ),
 bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(16.0),
  child: ElevatedButton(
    onPressed: () {
      Navigator.pushNamed(
        context, 
        '/booking/vehicle-info',
        arguments: {
          'spotId': widget.spot.id,
          'spotName': widget.spot.name,
          'pricePerHour': widget.spot.price, 
        },
      );
    },
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      textStyle: const TextStyle(fontSize: 16),
    ),
    child: const Text("Book Now"),
  ),
),

    );
  }

  Widget _buildLocationMap(LatLng center, LatLng userPos, LatLng parkingPos) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: userPos,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
                Marker(
                  point: parkingPos,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.local_parking,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [userPos, parkingPos],
                  color: Colors.blue.withOpacity(0.5),
                  strokeWidth: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenities() {
    // Replace with your actual amenities data
    const amenities = [
      {'icon': Icons.security, 'label': 'Security'},
      {'icon': Icons.ev_station, 'label': 'EV Charging'},
      {'icon': Icons.local_car_wash, 'label': 'Car Wash'},
      {'icon': Icons.wifi, 'label': 'WiFi'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: amenities.map((amenity) => Chip(
        avatar: Icon(amenity['icon'] as IconData, size: 18),
        label: Text(amenity['label'] as String),
      )).toList(),
    );
  }

  Future<double> _calculateDistance() async {
    return Geolocator.distanceBetween(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
      widget.spot.latitude,
      widget.spot.longitude,
    ) / 1000; // Convert to kilometers
  }

  Future<void> _launchDirections(LatLng destination) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _shareParkingSpot(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing parking spot...')),
    );
  }

 

  Widget _buildReviewsSection(String spotId) {
    return FutureBuilder<List<Review>>(
      future: ParkingService.getReviews(spotId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading reviews: ${snapshot.error}'));
        }
        
        final reviews = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reviews (${reviews.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (reviews.isNotEmpty)
                    _buildAverageRating(reviews),
                ],
              ),
            ),
            
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.reviews, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'No reviews yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showAddReviewDialog(spotId),
                      child: const Text('Be the first to review'),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Scrollbar(
                  controller: _scrollController, // Attach the controller here
                  child: SingleChildScrollView(
                    controller: _scrollController, // Attach the controller here as well
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ...reviews.map((review) => _buildReviewCard(review)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            
           
          ],
        );
      },
    );
  }

Widget _buildAverageRating(List<Review> reviews) {
  final average = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  return Row(
    children: [
      _buildRatingStars(average),
      const SizedBox(width: 4),
      Text(
        average.toStringAsFixed(1),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ],
  );
}

Widget _buildReviewCard(Review review) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.userAvatar != null
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null
                    ? Text(review.userName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(review.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildRatingStars(review.rating.toDouble()),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(fontSize: 15),
          ),
          // Removed images section since it's not in the Review model
        ],
      ),
    ),
  );
}

Widget _buildRatingStars(double rating) {
  return Row(
    children: List.generate(5, (index) {
      return Icon(
        index < rating.floor()
            ? Icons.star
            : (index < rating ? Icons.star_half : Icons.star_border),
        color: Colors.amber,
        size: 20,
      );
    }),
  );
}
}