import 'package:latlong2/latlong.dart';


class ParkingSpot {
  final String id;
  final String name;
  final String address; 
  final double latitude;
  final double longitude;
  final int availableSpots;
  final double price;
  final String? imageUrl;
  final double? averageRating;
  final int? reviewCount;
  final String? description; 


  ParkingSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.availableSpots,
    required this.price,
    this.imageUrl,
    this.averageRating,
    this.reviewCount,
    this.description,
  });

  LatLng get location => LatLng(latitude, longitude);


  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['image_url'];
  print('Parsing parking spot - Image URL: $imageUrl'); // Debug print
  print('Full JSON: $json'); 

  return ParkingSpot(
    id: json['id'].toString(),
    name: json['name'],
    address: json['address'],
    latitude: _parseDouble(json['latitude']),
    longitude: _parseDouble(json['longitude']),
    availableSpots: _parseInt(json['available_spots']),
    price: _parseDouble(json['price']),
    imageUrl: json['image_url'],
    averageRating: _parseDouble(json['avg_rating']),
    reviewCount: _parseInt(json['review_count']),
    description: json['description'], 

  );
}

// Helper methods
static double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

static int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}
}
