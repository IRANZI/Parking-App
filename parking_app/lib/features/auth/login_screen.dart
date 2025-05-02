import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:parking/data/services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _apiMessage;
  bool _isError = false;
  String? _userType; // This will hold the selected user type

  String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:2005/api/auth/login';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:2005/api/auth/login';
    } else {
      return 'http://localhost:2005/api/auth/login';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, bool isError) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _handleLoginResponse(http.Response response) async {
    if (!mounted) return;

    try {
      if (response.body.isEmpty) {
        _showMessage('Server returned an empty response', true);
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        if (token == null || token.toString().isEmpty) {
          _showMessage('Invalid response: missing token', true);
          return;
        }

        await AuthService.saveToken(token.toString());
        print('Login successful, token saved');

        if (mounted) {
          _showMessage('Login successful!', false);
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacementNamed(context, '/home');
          });
        }
      } else {
        final message = data['message']?.toString() ?? 'Invalid credentials';
        _showMessage(message, true);
      }
    } catch (e) {
      _showMessage('Invalid response from server', true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _apiMessage = null;
      _isError = false;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _userType == null) {
      _showMessage('Please fill in all fields and select login type', true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Admin login check
    if (_userType == 'Admin' && _emailController.text == 'iradianah5@gmail.com' && _passwordController.text == '123') {
      // Proceed with Admin login
      await AuthService.saveToken('admin-token'); // You can save an actual admin token here
      _showMessage('Admin login successful!', false);
      Navigator.pushReplacementNamed(context, '/admin'); // Navigate to the admin panel
      return;
    }

    // Staff login (mocked for simplicity)
    if (_userType == 'Staff') {
      // Staff login can be based on staff data stored elsewhere
      // For this demo, let's simulate that the staff login is successful if email ends with '@staff.com'
      if (_emailController.text.endsWith('@staff.com')) {
        _showMessage('Staff login successful!', false);
        Navigator.pushReplacementNamed(context, '/staff'); // Navigate to staff dashboard
        return;
      } else {
        _showMessage('Invalid staff credentials', true);
        return;
      }
    }

    // User login via API for other types
    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      await _handleLoginResponse(response);
    } on SocketException {
      _showMessage('Cannot connect to server. Check your connection.', true);
    } on TimeoutException {
      _showMessage('Connection timed out. Please try again.', true);
    } catch (e) {
      _showMessage('An error occurred. Please try again.', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    Text(
                      "Welcome Back!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Login to your account",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // User Type Selector
                    _buildUserTypeSelector(),

                    const SizedBox(height: 40),

                    // Error/Success Message
                    if (_apiMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isError ? Colors.red : Colors.green,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isError ? Icons.error_outline : Icons.check_circle_outline,
                              color: _isError ? Colors.red : Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _apiMessage!,
                                style: GoogleFonts.poppins(
                                  color: _isError ? Colors.red : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_apiMessage != null) const SizedBox(height: 20),

                    // Email Field
                    _buildInputField("Email", Icons.email, _emailController, false),

                    const SizedBox(height: 15),

                    // Password Field with Toggle
                    _buildInputField("Password", Icons.lock, _passwordController, true),

                    const SizedBox(height: 25),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          disabledBackgroundColor: Colors.white.withAlpha(100),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.blue, strokeWidth: 2)
                            : Text(
                                "Login",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                      ),
                    ),

                    // Register Button Below Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register'); // Ensure you have this route defined
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          "Register",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: Text('User'),
          selected: _userType == 'User',
          onSelected: (selected) {
            setState(() {
              _userType = selected ? 'User' : null;
            });
          },
        ),
        const SizedBox(width: 20),
        ChoiceChip(
          label: Text('Admin'),
          selected: _userType == 'Admin',
          onSelected: (selected) {
            setState(() {
              _userType = selected ? 'Admin' : null;
            });
          },
        ),
        const SizedBox(width: 20),
        ChoiceChip(
          label: Text('Staff'),
          selected: _userType == 'Staff',
          onSelected: (selected) {
            setState(() {
              _userType = selected ? 'Staff' : null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInputField(String hintText, IconData icon, TextEditingController controller, bool isPassword) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(hintText, icon, isPassword),
      ),
    );
  }

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: Colors.white.withAlpha(51),
      borderRadius: BorderRadius.circular(25),
    );
  }

  InputDecoration _inputDecoration(String hintText, IconData icon, bool isPassword) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white),
      border: InputBorder.none,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
          : null,
    );
  }
}
