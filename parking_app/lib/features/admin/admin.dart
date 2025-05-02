import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: ThemeData(
        primaryColor: Color(0xFF2C3E50), // Dark Blue Grey
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2C3E50), // Primary color
          secondary: Color(0xFF3498DB), // Secondary color
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      home: AdminHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0; // Default to Dashboard

  List<String> menuItems = [
    'Dashboard',
    'Parking Locations',
    'Spot Availability',
    'Staff Manager',
    'Check-In/Out Logs',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
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
        child: _getPageContent(),
      ),
    );
  }

  Widget _getPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _dashboardPage();
      case 1:
        return _parkingLocationsPage();
      case 2:
        return _spotAvailabilityPage();
      case 3:
        return _staffManagerPage();
      case 4:
        return _checkInOutLogsPage();
      default:
        return Center(child: Text('Page not found', style: _pageTitleStyle()));
    }
  }

  TextStyle _pageTitleStyle() => TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50));

  Widget _dashboardPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('Welcome Back, Admin!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          SizedBox(height: 20),
          Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _statisticRow('Total Parking Spots', '120', Color(0xFF3498DB)),
                  _statisticRow('Available Spots', '75', Colors.green),
                  _statisticRow('Total Staff', '10', Colors.orange),
                  SizedBox(height: 20),
                  _buildBarChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 150,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: 120,
                  width: 15,
                  borderRadius: BorderRadius.zero,
                  color: Color(0xFF3498DB),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: 90,
                  width: 15,
                  borderRadius: BorderRadius.zero,
                  color: Colors.green,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: 60,
                  width: 15,
                  borderRadius: BorderRadius.zero,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticRow(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 18, color: Colors.grey)),
        SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _parkingLocationsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parking Locations', style: _pageTitleStyle()),
          SizedBox(height: 20),
          _locationCard('Central Garage', '120 spots', Colors.blue),
          _locationCard('East Lot', '50 spots', Colors.green),
          _locationCard('West Lot', '30 spots', Colors.orange),
        ],
      ),
    );
  }

  Widget _locationCard(String name, String availability, Color color) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(availability, style: TextStyle(fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _spotAvailabilityPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spot Availability', style: _pageTitleStyle()),
          SizedBox(height: 20),
          _availabilityCard('Central Garage', 75, Colors.green),
          _availabilityCard('East Lot', 30, Colors.orange),
          _availabilityCard('West Lot', 10, Colors.red),
        ],
      ),
    );
  }

  Widget _availabilityCard(String name, int availableSpots, Color color) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('$availableSpots available', style: TextStyle(fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _staffManagerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Staff Manager', style: _pageTitleStyle()),
            ElevatedButton(
              onPressed: () => _showStaffForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3498DB),
                textStyle: TextStyle(color: Colors.white),
              ),
              child: Text('Add Staff'),
            ),
          ],
        ),
        SizedBox(height: 20),
        Expanded(child: _buildStaffTable()),
      ],
    );
  }

  Widget _buildStaffTable() {
    final staffData = [
      {'name': 'John Doe', 'role': 'Parking Attendant', 'location': 'Central Garage'},
      {'name': 'Jane Smith', 'role': 'Parking Attendant', 'location': 'East Lot'},
      {'name': 'Mike Johnson', 'role': 'Manager', 'location': 'Warehouse Parking'},
    ];

    return DataTable(
      columns: [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('Edit')),
      ],
      rows: staffData
          .map(
            (staff) => DataRow(cells: [
              DataCell(Text(staff['name']!)),
              DataCell(Text(staff['role']!)),
              DataCell(Text(staff['location']!)),
              DataCell(IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF3498DB)),
                onPressed: () => _showStaffForm(editData: staff),
              )),
            ]),
          )
          .toList(),
    );
  }

  Widget _checkInOutLogsPage() {
    final logs = [
      {'date': '04/23/2024', 'staff': 'John Doe', 'code': 'PARK1234', 'type': 'Car', 'action': 'Check in'},
      {'date': '04/23/2024', 'staff': 'Jane Smith', 'code': 'BIKE5678', 'type': 'Bike', 'action': 'Check in'},
      {'date': '04/22/2024', 'staff': 'John Doe', 'code': 'TRUCK810', 'type': 'Truck', 'action': 'Check out'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check-In/Out Logs', style: _pageTitleStyle()),
        SizedBox(height: 20),
        DataTable(
          columns: [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Staff')),
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Action')),
          ],
          rows: logs
              .map((log) => DataRow(cells: [
                    DataCell(Text(log['date']!)),
                    DataCell(Text(log['staff']!)),
                    DataCell(Text(log['code']!)),
                    DataCell(Text(log['type']!)),
                    DataCell(Text(log['action']!)),
                  ]))
              .toList(),
        ),
      ],
    );
  }

  void _showStaffForm({Map<String, String>? editData}) {
    final nameController = TextEditingController(text: editData?['name'] ?? '');
    final roleController = TextEditingController(text: editData?['role'] ?? '');
    final locationController = TextEditingController(text: editData?['location'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(editData == null ? 'Add Staff' : 'Edit Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: roleController,
                decoration: InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF3498DB))),
            ),
            ElevatedButton(
              onPressed: () {
                // Save staff info logic
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3498DB)),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}