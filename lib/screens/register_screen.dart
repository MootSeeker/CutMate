import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/services/auth_service.dart';
import 'package:cutmate/services/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final userProvider = context.read<UserProvider>();
      
      await authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Sync user data after successful registration
      await userProvider.syncUserDataAfterLogin();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrieren'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo oder App-Name
              Text(
                'CutMate',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // E-Mail Feld
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihre E-Mail ein';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Bitte geben Sie eine gültige E-Mail ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Passwort Feld
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie ein Passwort ein';
                  }
                  if (value.length < 6) {
                    return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Passwort bestätigen Feld
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Passwort bestätigen',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte bestätigen Sie Ihr Passwort';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwörter stimmen nicht überein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Registrieren Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Registrieren'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Anmelden Link
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bereits ein Konto? Anmelden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
