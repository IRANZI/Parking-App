
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // for formatting date
import 'package:parking/data/models/booking.dart'; // your Booking model
import 'package:parking/data/services/booking_services.dart';  // the getUserBookings function


class BookingCard extends StatefulWidget {
  final Booking booking;
  
  const BookingCard({super.key, required this.booking});
 
  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _expanded = false;
  

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.booking.spotName ?? 'Unknown Spot',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.booking.totalPrice} RWF',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMMd().format(widget.booking.date),
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '${_formatTime(widget.booking.startTime)} - ${_formatTime(widget.booking.endTime)}',
              style: const TextStyle(fontSize: 14),
            ),
            
            if (_expanded) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Vehicle:', '${widget.booking.vehicleBrand} (${widget.booking.vehicleType})'),
              _buildDetailRow('Plate:', widget.booking.plateNumber),
              _buildDetailRow('Status:', widget.booking.status),
              _buildDetailRow('Booking ID:', widget.booking.id),
            ],
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show Less' : 'Show More'),
              ),
            ),
            
            // Show "Pay Now" button only if status is "pending"
 if (widget.booking.status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    
                    onPressed: () {
  Navigator.pushNamed(
    context,
    '/payment',
    arguments: {
      'booking': widget.booking.toJson(), // Convert to JSON
      'totalPrice': widget.booking.totalPrice,
    },
  );
},
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  String _formatTime(dynamic time) {
    try {
      if (time is String) {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute).format(context);
      } else if (time is TimeOfDay) {
        return time.format(context);
      } else {
        return 'Invalid time';
      }
    } catch (e) {
      return time.toString(); // fallback to display whatever it is
    }
  }
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<List<Booking>> _bookingsFuture;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = BookingService.getUserBookings();
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _bookingsFuture = BookingService.getUserBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshBookings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBookings,
        child: FutureBuilder<List<Booking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load bookings'),
                    TextButton(
                      onPressed: _refreshBookings,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final bookings = snapshot.data ?? [];

            if (bookings.isEmpty) {
              return const Center(
                child: Text('No bookings found'),
              );
            }

            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return BookingCard(booking: bookings[index]);
              },
            );
          },
        ),
      ),
    );
  }
}