import 'package:flutter/material.dart';
import 'package:parking/data/models/booking.dart'; 
import 'package:parking/data/services/booking_services.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedMethod;
  String? _errorMessage;
  Booking? _booking;
  double _totalPrice = 0;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args == null || args['booking'] == null) {
    debugPrint('No booking data provided');
    return;
  }

  try {
    Booking booking;
    if (args['booking'] is Booking) {
      booking = args['booking'] as Booking;
    } 
    else if (args['booking'] is Map<String, dynamic>) {
      // Convert from JSON
      booking = Booking.fromJson(args['booking'] as Map<String, dynamic>);
    }
    else {
      throw Exception('Invalid booking type: ${args['booking'].runtimeType}');
    }

    setState(() {
      _booking = booking;
      _totalPrice = args['totalPrice'] ?? booking.totalPrice;
    });
  } catch (e) {
    debugPrint('Error processing booking: $e');
    // Handle error
  }
}
  Future<void> _processPayment(String method) async {
    final phone = _phoneController.text.trim();
    
    if (!RegExp(r'^07[2389]\d{7}$').hasMatch(phone)) {
      setState(() => _errorMessage = "Please enter a valid Rwandan phone number");
      return;
    }

    if (_booking == null) {
      setState(() => _errorMessage = "Invalid booking information");
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedMethod = method;
      _errorMessage = null;
    });

    try {
      final response = await BookingService.confirmPayment(
        reservationId: _booking!.id,
        paymentMethod: method,
        amountPaid: _totalPrice,
        phoneNumber: phone,
      );

      if (response['success'] == true) {
        _showSuccessDialog(response);
      } else {
        setState(() => _errorMessage = response['message'] ?? 'Payment failed');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Payment Successful"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Amount: ${_totalPrice.toStringAsFixed(2)} RWF"),
            Text("Method: $_selectedMethod"),
            Text("Transaction ID: ${response['data']['transaction_id']}"),
            const SizedBox(height: 16),
            const Text("You will receive a confirmation message shortly."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red[100],
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "07X XXX XXXX",
                prefixText: "+250 ",
              ),
            ),
            
            const SizedBox(height: 20),
            
            _PaymentOptionTile(
              label: "MTN Mobile Money",
              icon: Icons.phone_android,
              onTap: () => _processPayment("MTN"),
              isSelected: _selectedMethod == "MTN",
              isLoading: _isProcessing && _selectedMethod == "MTN",
            ),
            
            const SizedBox(height: 15),
            
            _PaymentOptionTile(
              label: "Airtel Money",
              icon: Icons.phone_iphone,
              onTap: () => _processPayment("AIRTEL"),
              isSelected: _selectedMethod == "AIRTEL",
              isLoading: _isProcessing && _selectedMethod == "AIRTEL",
            ),
            
            const Spacer(),
            
            Text(
              "Total: ${_totalPrice.toStringAsFixed(2)} RWF",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isLoading;

  const _PaymentOptionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
        title: Text(label),
        trailing: isLoading 
            ? const CircularProgressIndicator()
            : const Icon(Icons.arrow_forward),
        onTap: isLoading ? null : onTap,
      ),
    );
  }
}
