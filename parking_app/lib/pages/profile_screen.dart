import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:parking/data/models/user.dart';
import 'package:parking/data/services/user_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        _user = user;
        _avatarUrl = user.avatarUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Header with Avatar
                    _buildProfileHeader(),
                    const SizedBox(height: 24),

                    // User Information Section
                    _buildUserInfoSection(),
                    const SizedBox(height: 32),

                    // Actions Section
                    _buildActionsSection(),
                  ],
                ),
              ),
    );
  }
Widget _buildProfileHeader() {
  return Column(
    children: [
      // Avatar with edit button
      Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _avatarUrl != null
                ? NetworkImage(_avatarUrl!)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
            child: _avatarUrl == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: _changeProfilePicture,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        _user?.name ?? 'No Name',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      Text(
        _user?.email ?? 'No Email',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    ],
  );
}
  Widget _buildUserInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.phone, 'Phone', _user?.phone ?? 'Not provided'),
            const Divider(),
            _buildInfoRow(
              Icons.location_on,
              'Address',
              _user?.address ?? 'Not provided',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.calendar_today,
              'Member since',
              _user?.joinDate != null
                  ? DateFormat('MMM d, y').format(_user!.joinDate!)
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lock, color: Colors.blue),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showChangePasswordDialog,
        ),
        
       
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _logout,
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  Future<void> _changeProfilePicture() async {
    // Implement image picking logic
    // This would typically use image_picker package
    // After selecting image, upload to server and update avatarUrl
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Old Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      await UserService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _logout() async {
    try {
      await UserService.logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout error: ${e.toString()}')),
        );
      }
    }
  }
}
