import 'package:flutter/material.dart';

class Booking {
  final String id;
  final String userId;
  final String spotId;
  final String? spotName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String vehicleBrand;
  final String vehicleType;
  final String plateNumber;
  final double totalPrice;
  final String status;
  final String? bookingCode;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  Booking({
    required this.id,
    required this.userId,
    required this.spotId,
    this.spotName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.vehicleBrand,
    required this.vehicleType,
    required this.plateNumber,
    required this.totalPrice,
    required this.status,
    this.bookingCode,
    this.checkInTime,
    this.checkOutTime,
  });

  static double _parsePrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;

    if (priceValue is num) {
      return priceValue.toDouble();
    } else if (priceValue is String) {
      try {
        return double.parse(priceValue);
      } catch (e) {
        debugPrint('Error parsing price string: $e');
        return 0.0;
      }
    }
    return 0.0;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      DateTime parseDate(dynamic dateValue) {
        if (dateValue == null) {
          return DateTime.now(); 
        }

        String dateStr = dateValue.toString();
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          if (dateStr.contains('T') && !dateStr.contains('-')) {
            try {
              final now = DateTime.now();
              final fixedDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-$dateStr';
              return DateTime.parse(fixedDateStr);
            } catch (e) {
              debugPrint('Error parsing fixed date: $e');
            }
          }

          if (dateStr.contains('-')) {
            try {
              final dateParts = dateStr.split('-');
              if (dateParts.length == 3) {
                return DateTime(
                  int.parse(dateParts[0]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[2]),
                );
              }
            } catch (e) {
              debugPrint('Error parsing date parts: $e');
            }
          }
          debugPrint('Fallback to current date for: $dateStr');
          return DateTime.now();
        }
      }

      TimeOfDay parseTime(dynamic timeValue) {
        if (timeValue == null) {
          return const TimeOfDay(hour: 0, minute: 0);
        }

        String timeStr = timeValue.toString();

        if (timeStr.contains('T')) {
          try {
            final dt = DateTime.parse(timeStr);
            return TimeOfDay(hour: dt.hour, minute: dt.minute);
          } catch (e) {
            try {
              final parts = timeStr.split('T')[1].split(':');
              return TimeOfDay(
                hour: int.parse(parts[0]), 
                minute: int.parse(parts[1]),
              );
            } catch (e) {
              debugPrint('Error extracting time from datetime: $e');
            }
          }
        }

        try {
          final parts = timeStr.split(':');
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (e) {
          debugPrint('Error parsing time: $e');
          return const TimeOfDay(hour: 0, minute: 0);
        }
      }

      return Booking(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        spotId: json['spot_id']?.toString() ?? '',
        spotName: json['spot_name']?.toString(),
        date: parseDate(json['date']),
        startTime: parseTime(json['start_time']),
        endTime: parseTime(json['end_time']),
        vehicleBrand: json['vehicle_brand']?.toString() ?? '',
        vehicleType: json['vehicle_type']?.toString() ?? '',
        plateNumber: json['plate_number']?.toString() ?? '',
        totalPrice: _parsePrice(json['total_price']),
        status: json['status']?.toString() ?? 'unknown',
        bookingCode: json['booking_code']?.toString(),
        checkInTime: json['check_in_time'] != null 
            ? parseDate(json['check_in_time'])
            : null,
        checkOutTime: json['check_out_time'] != null
            ? parseDate(json['check_out_time'])
            : null,
      );
    } catch (e) {
      debugPrint('Error in Booking.fromJson: $e');
      return Booking(
        id: 'error',
        userId: '',
        spotId: '',
        spotName: 'Error loading',
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endTime: const TimeOfDay(hour: 0, minute: 0),
        vehicleBrand: '',
        vehicleType: '',
        plateNumber: '',
        totalPrice: 0.0,
        status: 'error',
      );
    }
  }

  factory Booking.fromPaymentConfirmation(Map<String, dynamic> json) {
    final reservation = json['reservation'];
    final ticket = json['ticket'];

    final startParts = (reservation['start_time'] as String).split(':');
    final endParts = (reservation['end_time'] as String).split(':');
    final dateParts = (reservation['date'] as String).split('-');

    return Booking(
      id: reservation['id'].toString(),
      userId: reservation['user_id'].toString(),
      spotId: reservation['spot_id'].toString(),
      date: DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      ),
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      vehicleBrand: reservation['vehicle_brand'] as String,
      vehicleType: reservation['vehicle_type'] as String,
      plateNumber: reservation['plate_number'] as String,
      totalPrice: _parsePrice(reservation['total_price']),
      status: 'paid',
      bookingCode: ticket['booking_code'] as String,
      checkInTime: null,
      checkOutTime: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'spot_id': spotId,
      'spot_name': spotName,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'vehicle_brand': vehicleBrand,
      'vehicle_type': vehicleType,
      'plate_number': plateNumber,
      'total_price': totalPrice,
      'status': status,
      'booking_code': bookingCode,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
    };
  }

  String formattedTimeRange(BuildContext context) {
    return '${startTime.format(context)} - ${endTime.format(context)}';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }
}
