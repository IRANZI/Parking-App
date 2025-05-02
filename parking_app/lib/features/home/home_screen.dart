
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parking/data/models/parking_spot.dart';
import 'package:parking/data/services/parking_services.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:parking/data/models/review.dart';
import 'package:parking/pages/parkingDetailPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parking/widgets/review_dialog.dart';
import 'package:parking/widgets/booking_button.dart'; 
import 'package:parking/pages/booking_screen.dart'; 
import 'package:parking/pages/profile_screen.dart'; 



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MapController _mapController;
  LatLng _currentPosition = LatLng(-1.9501, 30.0588);
  List<ParkingSpot> _parkingSpots = [];
  final _logger = Logger('HomeScreen');
  final TextEditingController _searchController = TextEditingController();
  List<ParkingSpot> _allParkingSpots = []; // Original unfiltered list

  int _currentIndex = 0;
 
  final List<Widget> _screens = const [
    HomeScreen(),
    BookingsScreen(),
    Center(child: Text('Saved Screen')),  // Placeholder
    ProfileScreen()    
  ];
  
  final String slogan = "Find your perfect parking spot!";
  bool _showNearbySpots = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
    _loadParkingSpots();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _logger.warning('Location permission denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _mapController.move(_currentPosition, 15.0);
           _showNearbySpots = true;
        });
      }
    } catch (e) {
      _logger.severe('Error getting location: $e');
    }
  }

  Future<void> _loadParkingSpots() async {
    try {
      final spots = await ParkingService.getParkingSpots();
      if (mounted) {
        setState(() {
          _allParkingSpots = spots;
          _parkingSpots = spots;
          _logger.info('Loaded ${_parkingSpots.length} parking spots');
        });
      }
    } catch (e) {
      _logger.severe('Error loading parking spots: $e');
    }
  }

Future<void> saveAuthToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('authToken', token);  // Save the token
}

  @override
Widget build(BuildContext context) {

  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;
  final isLargeScreen = screenWidth > 1200;
  final nearbySpots = _getNearbyParkingSpots();

  return Scaffold(
        extendBodyBehindAppBar: true,
    appBar: isMobile ? _buildMobileAppBar() : null,
    body: _currentIndex == 0 
      ? LayoutBuilder(
          builder: (context, constraints) {
        return Stack(
          children: [
            // Map View
           Positioned.fill(
  child: Listener(
    onPointerDown: (_) {
      // Only hide nearby spots when tapping on the map (not on markers)
      if (_showNearbySpots) {
        setState(() {
          _showNearbySpots = false;
        });
      }
    },
    child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition,
        initialZoom: isLargeScreen ? 16.0 : 15.0,
        onTap: (tapPosition, point) {
          _checkIfParkingSpotTapped(point);
        },
        keepAlive: true,
        maxZoom: 18.0,
        minZoom: 3.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.parking.app',
        ),
        MarkerLayer(markers: _buildParkingMarkers(isMobile)),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentPosition,
              width: isMobile ? 30 : 40,
              height: isMobile ? 30 : 40,
              child: Icon(
                Icons.my_location,
                color: Colors.blue,
                size: isMobile ? 30 : 40,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),
            // Search Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + (isMobile ? 70 : 90),
             left: isMobile
    ? 20
    : isLargeScreen
        ? constraints.maxWidth * 0.2
        : constraints.maxWidth * 0.1,
right: isMobile
    ? 20
    : isLargeScreen
        ? constraints.maxWidth * 0.2
        : constraints.maxWidth * 0.1,

              child: _buildSearchBar(isMobile),
            ),

            // Desktop Sidebar
if (!isMobile && !isLargeScreen)_buildDesktopSidebar(),


            // Nearby Parking Spots Overlay
            if (_showNearbySpots && nearbySpots.isNotEmpty)
  Positioned(
    bottom: isMobile ? 55 : 15, // Adjusted bottom position
    left: 6, // Slightly reduced left margin
    right: 6, // Slightly reduced right margin
    child: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildNearbyParkingList(nearbySpots, isMobile),
      ),
    ),
  ),
          ],
        );
      },
    ) : _screens[_currentIndex],
  floatingActionButton: _currentIndex == 0 
      ? FloatingActionButton(
          onPressed: () {
            setState(() {
              _showNearbySpots = true;
              _getUserLocation();
            });
          },
          backgroundColor: Colors.blueAccent,
          elevation: 8.0,
          child: const Icon(Icons.my_location),
        )
      : null,
    bottomNavigationBar: isMobile ? _buildMobileNavBar() : null,
  );
}
List<ParkingSpot> _getNearbyParkingSpots() {
if (_parkingSpots.isEmpty) return [];  
  return _parkingSpots.where((spot) {
    final distance = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      spot.latitude,
      spot.longitude,
    );
    return distance <= 5000; //
  }).toList()
    ..sort((a, b) {
      final distA = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        a.latitude,
        a.longitude,
      );
      final distB = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });
}
Widget _buildNearbyParkingList(List<ParkingSpot> spots, bool isMobile) {
  return Container(
    height: isMobile ? 170 : 190, 
    margin: const EdgeInsets.only(bottom: 10), 
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 2), 
          child: Text(
            "Nearby Parking Spots",
            style: TextStyle(
              fontSize: isMobile ? 14 : 16, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2), 
            child: ListView.separated(
  scrollDirection: Axis.horizontal,
  itemCount: _parkingSpots.length,
  itemBuilder: (context, index) {
    return _buildNearbyParkingCard(_parkingSpots[index], isMobile, context);
  },
  separatorBuilder: (context, index) => const SizedBox(width: 12),
)

          ),
        ),
      ],
    ),
  );
}

Widget _buildNearbyParkingCard(
  ParkingSpot spot, 
  bool isMobile,
  BuildContext context,
) {
  final distance = Geolocator.distanceBetween(
    _currentPosition.latitude,
    _currentPosition.longitude,
    spot.latitude,
    spot.longitude,
  );
  return SizedBox(
    width: isMobile ? 145 : 165, // Fixed width
    height: isMobile ? 150 : 170, // Fixed height
    child: GestureDetector(
      onTap: () => _showParkingDetails(spot, context),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias, // Prevent overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section (60% of card)
            Expanded(
              flex: 6,
              child: Container(
                color: Colors.grey[200],
                child: spot.imageUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: spot.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.local_parking,
                        size: 30,
                        color: Colors.grey[400],
                      ),
                    )
                  : Icon(
                      Icons.local_parking,
                      size: 30,
                      color: Colors.grey[400],
                    ),
              ),
            ),
            // Info section (40% of card)
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 4.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parking spot name
                    Text(
                      spot.name,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Rating and price row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (spot.averageRating != null)
                                _buildCompactRatingStars(spot.averageRating!),
                              Text(
                               "${spot.price.toStringAsFixed(2)}Rwf/h",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: isMobile ? 11 : 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    // Distance
                    Text(
                      "${(distance / 1000).toStringAsFixed(1)} km away",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 10 : 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// More compact rating stars widget
Widget _buildCompactRatingStars(double rating) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      return Icon(
        index < rating.floor() ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 14, 
      );
    }),
  );
}

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Text(
                slogan,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    slogan,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Add desktop navigation items here
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 12 : 20,
      vertical: isMobile ? 4 : 12,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(Icons.search, 
          color: Colors.grey[600],
          size: isMobile ? 20 : 24,
        ),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by location, spot name...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: isMobile ? 14 : 16,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.black87,
            ),
            onChanged: (value) {
              _filterParkingSpots(value);
            },
          ),
        ),
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear, 
              size: isMobile ? 18 : 22,
              color: Colors.grey[500],
            ),
            onPressed: () {
              _searchController.clear();
              _filterParkingSpots('');
            },
          ),
        IconButton(
          icon: Icon(isMobile ? Icons.tune : Icons.filter_list),
          color: Colors.grey[600],
          onPressed: _showFilterDialog,
        ),
      ],
    ),
  );
}
void _zoomToSpot(ParkingSpot spot) {
  _mapController.move(spot.location, 17); // Adjust zoom level if needed
}
void _filterParkingSpots(String query) {
  setState(() {
    if (query.isEmpty) {
      _parkingSpots = _allParkingSpots;
    } else {
      final filtered = _allParkingSpots.where((spot) {
        final nameLower = spot.name.toLowerCase();
        final addressLower = spot.address.toLowerCase();
        final queryLower = query.toLowerCase();

        return nameLower.contains(queryLower) || addressLower.contains(queryLower);
      }).toList();

      _parkingSpots = filtered;

      // Zoom if one exact match
      if (filtered.length == 1) {
        Future.delayed(Duration(milliseconds: 300), () {
          _zoomToSpot(filtered.first);
        });
      }
    }
  });
}
void _showFilterDialog() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
             'Filter Parking Spots',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
             ),
            SizedBox(height: 16),

            // Add your filter options here
            // Example: price range, rating, distance, etc.
            ListTile(
              title: Text('Price Range'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _showPriceRangeFilter(),
            ),
            ListTile(
              title: Text('Minimum Rating'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _showRatingFilter(),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              child: Text('Apply Filters'),
              onPressed: () {
                Navigator.pop(context);
                // Apply your filters here
              },
            ),
          ],
        ),
      );
    },
  );
}
void _showPriceRangeFilter() {
  double minPrice = 0;
  double maxPrice = 5000; // Typical max parking price in RWF (adjust as needed)

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filter by Price Range (RWF)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                RangeSlider(
                  values: RangeValues(minPrice, maxPrice),
                  min: 0,
                  max: 10000, // 10,000 RWF as maximum range
                  divisions: 10,
                  labels: RangeLabels(
                    'RWF ${minPrice.toStringAsFixed(0)}',
                    'RWF ${maxPrice.toStringAsFixed(0)}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      minPrice = values.start;
                      maxPrice = values.end;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RWF ${minPrice.toStringAsFixed(0)}'),
                    Text('RWF ${maxPrice.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _applyPriceFilter(minPrice, maxPrice);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filter'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _applyPriceFilter(double minPrice, double maxPrice) {
  setState(() {
    _parkingSpots = _allParkingSpots.where((spot) {
      return spot.price >= minPrice && spot.price <= maxPrice;
    }).toList();
    //zoom
     if (_parkingSpots.isNotEmpty) {
      _mapController.move(_parkingSpots[0].location, 17.0);
    }
  });
}

void _showRatingFilter() {
  double minRating = 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filter by Minimum Rating',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: minRating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      minRating = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRatingStars(minRating),
                    Text('${minRating.toStringAsFixed(1)}+'),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _applyRatingFilter(minRating);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filter'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _applyRatingFilter(double minRating) {
  setState(() {
    _parkingSpots = _allParkingSpots.where((spot) {
      return spot.averageRating != null && spot.averageRating! >= minRating;
    }).toList();
    //zoom
     if (_parkingSpots.isNotEmpty) {
      _mapController.move(_parkingSpots[0].location, 17.0);
    }
  });
}
  Widget _buildMobileNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Booking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }
Widget _buildRatingStars(double rating) {
  return Row(
    children: List.generate(5, (index) {
      return Icon(
        index < rating.floor() ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 20,
      );
    }),
  );
}
List<Marker> _buildParkingMarkers(bool isMobile) {
    final markerSize = isMobile ? 40.0 : 50.0;
    return _parkingSpots.map((spot) {
      return Marker(
        point: LatLng(spot.latitude, spot.longitude),
        width: markerSize,
        height: markerSize,
        child: InkWell(
          onTap: () => _showParkingDetails(spot,context),
          child: Container(
            width: markerSize,
            height: markerSize,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

 
void _checkIfParkingSpotTapped(LatLng tapPoint) {
  const double threshold = 0.0005;
  bool tappedOnSpot = false;
  
  for (final spot in _parkingSpots) {
    if ((tapPoint.latitude - spot.latitude).abs() < threshold &&
        (tapPoint.longitude - spot.longitude).abs() < threshold) {
      _showParkingDetails(spot,context);
      tappedOnSpot = true;
      break;
    }
  }

  // Only hide nearby spots if tapping on empty map area
  if (!tappedOnSpot && mounted) {
    setState(() {
      _showNearbySpots = false;
    });
  }
}

void _showParkingDetails(ParkingSpot spot, BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      _showMobileBottomSheet(spot);
    } else {
      _showDesktopDialog(spot);
    }
  }

void _showMobileBottomSheet(ParkingSpot spot) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return _buildParkingDetailsContent(spot, scrollController);
          },
        ),
      );
    },
  );
}
void _showDesktopDialog(ParkingSpot spot) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: _buildParkingDetailsContent(spot, null),
        ),
      );
    },
  );
}

 Widget _buildParkingDetailsContent(ParkingSpot spot, ScrollController? scrollController) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  
  return SingleChildScrollView(
    controller: scrollController,
    physics: const ClampingScrollPhysics(),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: isMobile ? MediaQuery.of(context).size.height * 0.5 : 400,
        maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.9 : 700,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with image
          if (spot.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: spot.imageUrl!,
                height: isMobile ? 150 : 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  height: isMobile ? 150 : 200,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  height: isMobile ? 150 : 200,
                  child: const Icon(Icons.error),
                ),
              ),
            ),

          // Parking spot details
          Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (spot.averageRating != null)
                      _buildRatingStars(spot.averageRating!),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 5),
                    Text("${spot.latitude.toStringAsFixed(4)}, "
                        "${spot.longitude.toStringAsFixed(4)}"),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_parking, color: Colors.blue),
                    const SizedBox(width: 5),
                    Text("${spot.availableSpots} spots available"),
                    const Spacer(),
                    Text(
                     "${spot.price.toStringAsFixed(2)}Rwf/h",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  "Reviews",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Reviews list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isMobile ? 200 : 300,
            ),
            child: FutureBuilder<List<Review>>(
              future: ParkingService.getReviews(spot.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No reviews yet'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(snapshot.data![index]);
                  },
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToDetailPage(spot);
                        },
                        child: const Text("View Details"),
                      ),
                    ),
                    SizedBox(width: isMobile ? 16 : 24),
                Expanded(
  child: BookingButton(
    text: "Book Now",
   onPressed: () {
  Navigator.of(context, rootNavigator: true).pushNamed(
    '/booking/vehicle-info',
    arguments: {
    'spotId': spot.id,
    'spotName': spot.name,
    'pricePerHour': spot.price,
  },
  );
},
  ),
),



                  ],
                ),
                if (isMobile) 
                  TextButton(
                    onPressed: () {
                        ReviewDialog.show(context, spot.id);

                    },
                    child: const Text("Add Review"),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
void _navigateToDetailPage(ParkingSpot spot) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ParkingDetailPage(
        spot: spot,
        userLocation: _currentPosition, // Pass current user location

      ),
      
  
    ),
  );
}
  Widget _buildReviewCard(Review review) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 8,
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.userAvatar != null 
                      ? NetworkImage(review.userAvatar!) 
                      : null,
                  child: review.userAvatar == null 
                      ? Text(review.userName[0]) 
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildRatingStars(review.rating.toDouble()),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy').format(review.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }



}
