import 'package:flutter/material.dart';
import 'package:japhy_todo_app/services/auth_service.dart';
import 'package:japhy_todo_app/screens/login_screen.dart';
import 'package:japhy_todo_app/screens/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  final void Function(bool isDark) onThemeChanged;
  final ThemeMode currentThemeMode;

  const SignUpScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final user = await AuthService().signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                onThemeChanged: widget.onThemeChanged,
                currentThemeMode: widget.currentThemeMode,
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _errorMessage = 'Signup failed: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.person_add, size: 80, color: Colors.indigo),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value!.length < 6 ? 'Minimum 6 characters' : null,
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Sign Up'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                            onThemeChanged: widget.onThemeChanged,
                            currentThemeMode: widget.currentThemeMode,
                          ),
                        ),
                      );
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
