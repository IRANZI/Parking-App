import 'package:flutter/material.dart';

void main() {
  runApp(StaffDashboardApp());
}

class StaffDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Staff Dashboard',
      theme: ThemeData(
        primaryColor: Color(0xFF2C3E50), // Dark Blue Grey
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2C3E50), // Primary color
          secondary: Color(0xFF3498DB), // Secondary color
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      home: StaffDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StaffDashboard extends StatefulWidget {
  @override
  _StaffDashboardState createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;

  List<String> menuItems = ['Check-In/Out', 'Parking Locations', 'Activity Logs'];

  List<Map<String, String>> checkInOutLogs = [
    {'date': '04/23/2024', 'vehicleCode': 'PARK1234', 'action': 'Checked In'},
    {'date': '04/22/2024', 'vehicleCode': 'BIKE5678', 'action': 'Checked Out'},
  ];

  List<Map<String, String>> parkingLocations = [
    {'spot': 'A1', 'status': 'Available'},
    {'spot': 'A2', 'status': 'Occupied'},
    {'spot': 'B1', 'status': 'Available'},
    {'spot': 'B2', 'status': 'Occupied'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: menuItems.map((item) {
            final index = menuItems.indexOf(item);
            return ListTile(
              title: Text(item),
              selected: index == _selectedIndex,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                Navigator.pop(context); // Close the drawer
              },
            );
          }).toList(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildCheckInOut();
      case 1:
        return _buildParkingLocations();
      case 2:
        return _buildActivityLogs();
      default:
        return _buildCheckInOut();
    }
  }

  // Check-In/Out Page
  Widget _buildCheckInOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check-In/Out',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _showCheckInDialog,
          child: Text('Check-In Vehicle'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3498DB)),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _showCheckOutDialog,
          child: Text('Check-Out Vehicle'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3498DB)),
        ),
      ],
    );
  }

  // Parking Locations Page
  Widget _buildParkingLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parking Locations',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        _buildParkingSpotList(),
      ],
    );
  }

  // Activity Logs Page
  Widget _buildActivityLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Logs',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        _buildCheckInOutTable(),
      ],
    );
  }

  // Parking Spot List
  Widget _buildParkingSpotList() {
    return Column(
      children: parkingLocations.map((location) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            title: Text('Spot: ${location['spot']}', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${location['status']}'),
          ),
        );
      }).toList(),
    );
  }

  // Check-In/Out Table (Activity Logs)
  Widget _buildCheckInOutTable() {
    return DataTable(
      columns: [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Vehicle Code')),
        DataColumn(label: Text('Action')),
      ],
      rows: checkInOutLogs
          .map(
            (log) => DataRow(cells: [
              DataCell(Text(log['date']!)),
              DataCell(Text(log['vehicleCode']!)),
              DataCell(Text(log['action']!)),
            ]),
          )
          .toList(),
    );
  }

  // Show Check-In Dialog
  void _showCheckInDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Check-In Vehicle'),
          content: _buildCheckInForm(),
        );
      },
    );
  }

  // Show Check-Out Dialog
  void _showCheckOutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Check-Out Vehicle'),
          content: _buildCheckOutForm(),
        );
      },
    );
  }

  // Check-In Form Widget
  Widget _buildCheckInForm() {
    final TextEditingController _vehicleCodeController = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _vehicleCodeController,
          decoration: InputDecoration(labelText: 'Vehicle Code'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              checkInOutLogs.add({
                'date': '04/25/2024',
                'vehicleCode': _vehicleCodeController.text,
                'action': 'Checked In',
              });
            });
            Navigator.of(context).pop();
          },
          child: Text('Check-In'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3498DB)),
        ),
      ],
    );
  }

  // Check-Out Form Widget
  Widget _buildCheckOutForm() {
    final TextEditingController _vehicleCodeController = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _vehicleCodeController,
          decoration: InputDecoration(labelText: 'Vehicle Code'),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              checkInOutLogs.add({
                'date': '04/25/2024',
                'vehicleCode': _vehicleCodeController.text,
                'action': 'Checked Out',
              });
            });
            Navigator.of(context).pop();
          },
          child: Text('Check-Out'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3498DB)),
        ),
      ],
    );
  }
}