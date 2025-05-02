import 'package:flutter/material.dart';
import 'package:parking/data/services/booking_services.dart';

class BookingDateTimePickerScreen extends StatefulWidget {
  const BookingDateTimePickerScreen({super.key});

  @override
  State<BookingDateTimePickerScreen> createState() => _BookingDateTimePickerScreenState();
}

class _BookingDateTimePickerScreenState extends State<BookingDateTimePickerScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  final Gradient _appBarGradient = const LinearGradient(
    colors: [Colors.blue, Colors.green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  bool _isValidTime(TimeOfDay time) {
  return time.hour >= 0 && time.hour < 24 && time.minute >= 0 && time.minute < 60;
}

void _validateAndSetTime(TimeOfDay? pickedTime, bool isStartTime) {
  if (pickedTime == null) return;
  
  if (!_isValidTime(pickedTime)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid time! Please select time between 00:00-23:59")),
    );
    return;
  }

  setState(() {
    if (isStartTime) {
      _startTime = pickedTime;
    } else {
      _endTime = pickedTime;
    }
  });
}

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String parkingSpotName = args?['spotName'] ?? '';
    final int pricePerHour = args?['pricePerHour'] ?? 0;

    int totalHours = 0;
    int totalPrice = 0;

    if (_startTime != null && _endTime != null) {
      final start = DateTime(2023, 1, 1, _startTime!.hour, _startTime!.minute);
      final end = DateTime(2023, 1, 1, _endTime!.hour, _endTime!.minute);

      Duration duration = end.difference(start);
      totalHours = duration.inMinutes > 0 ? (duration.inMinutes / 60).ceil() : 0;
      totalPrice = totalHours * pricePerHour;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: _appBarGradient),
          ),
          centerTitle: true,
          title: const Text('Select Parking Time'),
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Parking Spot: $parkingSpotName", style: const TextStyle(fontSize: 16)),
            Text("Price per hour: $pricePerHour RWF", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),

            const Text("Select Date", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
           _buildPickerTile(
  label: _startTime == null ? "Tap to select start time" : _startTime!.format(context),
  icon: Icons.access_time,
  onTap: () async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true, // Force 24-hour format
          ),
          child: child!,
        );
      },
    );
    _validateAndSetTime(pickedTime, true);
  },
),

            const SizedBox(height: 25),

            const Text("Select Start Time", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPickerTile(
              label: _startTime == null
                  ? "Tap to select start time"
                  : _startTime!.format(context),
              icon: Icons.access_time,
              onTap: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() => _startTime = pickedTime);
                }
              },
            ),

            const SizedBox(height: 20),

            const Text("Select End Time", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          _buildPickerTile(
  label: _endTime == null ? "Tap to select end time" : _endTime!.format(context),
  icon: Icons.access_time,
  onTap: () async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start time first")),
      );
      return;
    }
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _startTime!.hour + 1, // Default to 1 hour after start
        minute: _startTime!.minute,
      ),
    );
    
    if (pickedTime != null) {
      // Validate time is after start time
      final start = DateTime(2023, 1, 1, _startTime!.hour, _startTime!.minute);
      final end = DateTime(2023, 1, 1, pickedTime.hour, pickedTime.minute);
      
      if (end.isBefore(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End time must be after start time")),
        );
      } else {
        setState(() => _endTime = pickedTime);
      }
    }
  },
),

            const SizedBox(height: 30),
            if (totalHours > 0)
              Text("Total Hours: $totalHours", style: const TextStyle(fontSize: 16)),
            if (totalPrice > 0)
              Text("Total Price: $totalPrice RWF", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const Spacer(),

SizedBox(
  width: double.infinity,
  child: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : ElevatedButton(
          onPressed: (_selectedDate != null && _startTime != null && _endTime != null)
              ? () {
                  debugPrint("Confirm button pressed");
                  _handleBooking(context, args, totalPrice);
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: (_selectedDate != null && _startTime != null && _endTime != null)
                ? Colors.blue
                : Colors.grey,
          ),
          child: const Text(
            "Confirm Book",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleBooking(BuildContext context, Map<String, dynamic>? args, int totalPrice) async {
  if (args == null || _selectedDate == null || _startTime == null || _endTime == null) return;

  // Add time validation before sending to backend
  final startDateTime = DateTime(
    _selectedDate!.year,
    _selectedDate!.month,
    _selectedDate!.day,
    _startTime!.hour,
    _startTime!.minute,
  );
  
  final endDateTime = DateTime(
    _selectedDate!.year,
    _selectedDate!.month,
    _selectedDate!.day,
    _endTime!.hour,
    _endTime!.minute,
  );

  if (endDateTime.isBefore(startDateTime)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("End time must be after start time")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final booking = await BookingService.createBooking(
      spotId: args['spotId'] ?? '',
      vehicleBrand: args['vehicleBrand'] ?? '',
      vehicleType: args['vehicleType'] ?? '',
      plateNumber: args['plateNumber'] ?? '',
      date: _selectedDate!,
      startTime: _startTime!,
      endTime: _endTime!,
    );

    Navigator.pushNamed(context, '/payment', arguments: {
      'booking': booking.toJson(),
      'totalPrice': totalPrice,
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())), // Show actual error message
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  Widget _buildPickerTile({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade100,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Icon(icon, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }
}